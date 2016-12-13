#include "skynet.h"
#include "skynet_mq.h"
#include "skynet_handle.h"
#include "spinlock.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdbool.h>

#define DEFAULT_QUEUE_SIZE 64
#define MAX_GLOBAL_MQ 0x10000

// 0 means mq is not in global mq.
// 1 means mq is in global mq , or the message is dispatching.

#define MQ_IN_GLOBAL 1
#define MQ_OVERLOAD 1024

// skynet使用了二级队列  从全局的 globe_mq 中取 mq 来处理

// 消息队列(循环队列)，容量不固定，按需增长
// 消息队列 mq 的结构
struct message_queue 
{
	struct spinlock lock;			// 锁
	uint32_t handle;				// 所属服务handle
	int cap;						// 容量
	int head;						// 队头
	int tail;						// 队尾
	int release;					// 消息队列释放标记，当要释放一个服务的时候 清理标记 不能立即释放该服务对应的消息队列(有可能工作线程还在操作mq)，就需要设置一个标记 标记是否可以释放
	int in_global;					// 消息当前的状态(0 不在全局队列中 1在全局队列中)
	int overload;
	int overload_threshold;
	struct skynet_message *queue;	//消息队列
	struct message_queue *next;
};

// 全局队列(循环队列，无锁队列)，容量固定64K 二级队列的实现
// 保存了 所有的消息 就是从这个队列中取消息出来做处理
struct global_queue 
{
	struct message_queue *head;
	struct message_queue *tail;
	struct spinlock lock;
};

static struct global_queue *Q = NULL;	// 全局的消息队列Q

void skynet_globalmq_push(struct message_queue *queue) 
{
	struct global_queue *q = Q;

	SPIN_LOCK(q)
	assert(queue->next == NULL);
	if(q->tail) 
	{
		q->tail->next = queue;
		q->tail = queue;
	} 
	else 
	{
		q->head = q->tail = queue;
	}
	SPIN_UNLOCK(q)
}

struct message_queue *skynet_globalmq_pop() 
{
	struct global_queue *q = Q;

	SPIN_LOCK(q)
	struct message_queue *mq = q->head;
	if(mq) 
	{
		q->head = mq->next;
		if(q->head == NULL) 
		{
			assert(mq == q->tail);
			q->tail = NULL;
		}
		mq->next = NULL;
	}
	SPIN_UNLOCK(q)

	return mq;
}

// 创建消息队列，初始容量 DEFAULT_QUEUE_SIZE 64K
struct message_queue *skynet_mq_create(uint32_t handle) 
{
	struct message_queue *q = skynet_malloc(sizeof(*q));
	q->handle = handle;
	q->cap = DEFAULT_QUEUE_SIZE;
	q->head = 0;
	q->tail = 0;
	SPIN_INIT(q)
	// When the queue is create (always between service create and service init) ,
	// set in_global flag to avoid push it to global queue .
	// If the service init success, skynet_context_new will call skynet_mq_push to push it to global queue.
	q->in_global = MQ_IN_GLOBAL;
	q->release = 0;
	q->overload = 0;
	q->overload_threshold = MQ_OVERLOAD;
	q->queue = skynet_malloc(sizeof(struct skynet_message) * q->cap);
	q->next = NULL;

	return q;
}

static void _release(struct message_queue *q) 
{
	assert(q->next == NULL);
	SPIN_DESTROY(q)
	skynet_free(q->queue);
	skynet_free(q);
}

uint32_t skynet_mq_handle(struct message_queue *q) 
{
	return q->handle;
}

int skynet_mq_length(struct message_queue *q) 
{
	int head, tail, cap;

	SPIN_LOCK(q)
	head = q->head;
	tail = q->tail;
	cap = q->cap;
	SPIN_UNLOCK(q)
	
	if(head <= tail) 
	{
		return tail - head;		// 正常没有循环回来
	}
	return tail + cap - head;	// 循环回来了
}

int skynet_mq_overload(struct message_queue *q) 
{
	if(q->overload) 
	{
		int overload = q->overload;
		q->overload = 0;
		return overload;
	} 
	return 0;
}

int skynet_mq_pop(struct message_queue *q, struct skynet_message *message) 
{
	int ret = 1;
	SPIN_LOCK(q)

	if(q->head != q->tail) 
	{
		*message = q->queue[q->head++];
		ret = 0;
		int head = q->head;
		int tail = q->tail;
		int cap = q->cap;

		if(head >= cap) 
		{
			q->head = head = 0;
		}
		int length = tail - head;
		if(length < 0) 
		{
			length += cap;
		}
		while(length > q->overload_threshold) 
		{
			q->overload = length;
			q->overload_threshold *= 2;
		}
	} 
	else 
	{
		// reset overload_threshold when queue is empty
		q->overload_threshold = MQ_OVERLOAD;
	}

	// 没有消息弹出，消息队列为空则不再将消息队列压入全局队列消息队列为空的就是就不再压入 globe_mq中
	if(ret) 
	{
		q->in_global = 0;
	}
	
	SPIN_UNLOCK(q)

	return ret;
}

// 扩大mq， 2倍的大小扩大
static void expand_queue(struct message_queue *q) 
{
	struct skynet_message *new_queue = skynet_malloc(sizeof(struct skynet_message) * q->cap * 2);
	int i;
	for(i = 0; i < q->cap; ++i) 
	{
		new_queue[i] = q->queue[(q->head + i) % q->cap];	//将原队列消息搬到新队列
	}
	q->head = 0;
	q->tail = q->cap;
	q->cap *= 2;
	
	skynet_free(q->queue);
	q->queue = new_queue;
}

void skynet_mq_push(struct message_queue *q, struct skynet_message *message) 
{
	assert(message);
	SPIN_LOCK(q)

	q->queue[q->tail] = *message;
	if(++q->tail >= q->cap) 
	{
		q->tail = 0;
	}

	if(q->head == q->tail) 
	{
		expand_queue(q);	 // 队列已满扩大队列容量2倍
	}

	if(q->in_global == 0) 
	{
		q->in_global = MQ_IN_GLOBAL;
		skynet_globalmq_push(q);
	}
	
	SPIN_UNLOCK(q)
}

// 初始化全局消息队列，容量固定64K
// 单机服务最大值64K,因而全局消息队列容量固定64K,方便全局消息队列实现为无锁队列
void skynet_mq_init() 
{
	struct global_queue *q = skynet_malloc(sizeof(*q));
	memset(q, 0, sizeof(*q));
	SPIN_INIT(q);
	Q = q;
}

void skynet_mq_mark_release(struct message_queue *q) 
{
	SPIN_LOCK(q)
	assert(q->release == 0);
	q->release = 1;
	if(q->in_global != MQ_IN_GLOBAL) 
	{
		skynet_globalmq_push(q);
	}
	SPIN_UNLOCK(q)
}

static void _drop_queue(struct message_queue *q, message_drop drop_func, void *ud) 
{
	struct skynet_message msg;
	while(!skynet_mq_pop(q, &msg)) 
	{
		drop_func(&msg, ud);
	}
	_release(q);
}

void skynet_mq_release(struct message_queue *q, message_drop drop_func, void *ud) 
{
	SPIN_LOCK(q)
	
	if(q->release) 
	{
		SPIN_UNLOCK(q)
		_drop_queue(q, drop_func, ud);
	} 
	else 
	{
		skynet_globalmq_push(q);
		SPIN_UNLOCK(q)
	}
}
