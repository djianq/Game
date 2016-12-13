#include "skynet.h"

#include "skynet_timer.h"
#include "skynet_mq.h"
#include "skynet_server.h"
#include "skynet_handle.h"
#include "spinlock.h"

#include <time.h>
#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>

#if defined(__APPLE__)
#include <sys/time.h>
#include <mach/task.h>
#include <mach/mach.h>
#endif

typedef void (*timer_execute_func)(void *ud,void *arg);

#define TIME_NEAR_SHIFT 8
#define TIME_NEAR (1 << TIME_NEAR_SHIFT)
#define TIME_LEVEL_SHIFT 6
#define TIME_LEVEL (1 << TIME_LEVEL_SHIFT)
#define TIME_NEAR_MASK (TIME_NEAR - 1)
#define TIME_LEVEL_MASK (TIME_LEVEL - 1)

// skynet 定时器的实现为linux内核的标准做法  精度为 0.01s 对游戏一般来说够了 高精度的定时器很费CPU
// 对于内核最关心的、interval值在［0，255］
// 内核在处理是否有到期定时器时，它就只从定时器向量数组tv1.vec［256］中的某个定时器向量内进行扫描。
// （2）而对于内核不关心的、interval值在［0xff，0xffffffff］之间的定时器，
// 它们的到期紧迫程度也随其interval值的不同而不同。显然interval值越小，定时器紧迫程度也越高。
// 因此在将它们以松散定时器向量进行组织时也应该区别对待。通常，定时器的interval值越小，
// 它所处的定时器向量的松散度也就越低（也即向量中的各定时器的expires值相差越小）；而interval值越大，
// 它所处的定时器向量的松散度也就越大（也即向量中的各定时器的expires值相差越大）。

// 内核规定，对于那些满足条件：0x100≤interval≤0x3fff的定时器，
// 只要表达式（interval>>8）具有相同值的定时器都将被组织在同一个松散定时器向量中，
// 即以1》8＝256为一个基本单位。因此，为组织所有满足条件0x100≤interval≤0x3fff的定时器，
// 就需要2^6＝64个松散定时器向量。同样地，为方便起见，这64个松散定时器向量也放在一起形成数组，并作为数据结构timer_vec的一部分。

struct timer_event 
{
	uint32_t handle;
	int session;
};

struct timer_node 
{
	struct timer_node *next;
	uint32_t expire;	// 超时滴答计数 即超时间隔
};

struct link_list 
{
	struct timer_node head;
	struct timer_node *tail;
};

struct timer 
{
	struct link_list near[TIME_NEAR];	// 定时器容器组 存放了不同的定时器容器
	struct link_list t[4][TIME_LEVEL];	// 4级梯队 4级不同的定时器
	struct spinlock lock;				// 用于实现自旋锁
	uint32_t time;						// 当前已经流过的滴答计数
	uint32_t starttime;					// 开机启动时间（绝对时间）
	uint64_t current;					// 当前时间，相对系统开机时间（相对时间）
	uint64_t current_point;
};

static struct timer *TI = NULL;

// 清除链表，返回原链表第一个节点指针
static inline struct timer_node *link_clear(struct link_list *list) 
{
	struct timer_node *ret = list->head.next;
	list->head.next = 0;
	list->tail = &(list->head);

	return ret;
}

// 将node添加到链表尾部
static inline void link(struct link_list *list, struct timer_node *node) 
{
	list->tail->next = node;
	list->tail = node;
	node->next = 0;
}

static void add_node(struct timer *T, struct timer_node *node) 
{
	uint32_t time = node->expire;	// 超时的滴答数
	uint32_t current_time = T->time;
	
	// 如果就是当前时间 没有超时
	if((time | TIME_NEAR_MASK) == (current_time | TIME_NEAR_MASK)) 
	{
		link(&T->near[time & TIME_NEAR_MASK], node);	// 将节点添加到对应的链表中
	} 
	else 
	{
		int i;
		uint32_t mask = TIME_NEAR << TIME_LEVEL_SHIFT;
		for(i = 0; i < 3; ++i) 
		{
			if((time | ( mask - 1 )) == (current_time | (mask - 1))) 
			{
				break;
			}
			mask <<= TIME_LEVEL_SHIFT;
		}

		link(&T->t[i][((time >> (TIME_NEAR_SHIFT + i * TIME_LEVEL_SHIFT)) & TIME_LEVEL_MASK)], node);	
	}
}

static void timer_add(struct timer *T, void *arg, size_t sz, int time) 
{
	struct timer_node *node = (struct timer_node *)skynet_malloc(sizeof(*node) + sz);
	memcpy(node + 1, arg, sz);

	SPIN_LOCK(T);
		node->expire = time + T->time;
		add_node(T, node);
	SPIN_UNLOCK(T);
}

static void move_list(struct timer *T, int level, int idx) 
{
	struct timer_node *current = link_clear(&T->t[level][idx]);
	while(current) 
	{
		struct timer_node *temp = current->next;
		add_node(T, current);
		current = temp;
	}
}

static void timer_shift(struct timer *T) 
{
	/*
		256~16383 都是插入在timer数组time[0][1~63] 其中跨度都为 1 << TIME_NEAR_SHIFT，即256
		16384~1048576插入timer数组位置为time[1][1~63] 其中跨度都为 1 << TIME_NEAR_SHIFT，即256
		......
	*/
	int mask = TIME_NEAR;
	uint32_t ct = ++T->time;
	if(ct == 0) 
	{
		move_list(T, 3, 0);
	} 
	else 
	{
		uint32_t time = ct >> TIME_NEAR_SHIFT; // ct / 256
		int i = 0;

		while((ct & (mask - 1)) == 0)  // ct % 256 == 0  为真
		{
			int idx = time & TIME_LEVEL_MASK;	// 保证idx在数组中不越界，t[level][idx]中idx最多为 1 << TIME_LEVEL_MASK
			if(idx != 0) 
			{
				move_list(T, i, idx);
				break;				
			}
			mask <<= TIME_LEVEL_SHIFT;	// mask * 64
			time >>= TIME_LEVEL_SHIFT;  // time / 64
			++i;
		}
	}
}

static inline void dispatch_list(struct timer_node *current) 
{
	do 
	{
		struct timer_event *event = (struct timer_event *)(current + 1);
		struct skynet_message message;
		message.source = 0;
		message.session = event->session;
		message.data = NULL;
		message.sz = (size_t)PTYPE_RESPONSE << MESSAGE_TYPE_SHIFT;	// 向左偏移了 24 位

		skynet_context_push(event->handle, &message);	// 将消息发送到对应的 handle 去处理
		
		struct timer_node *temp = current;
		current = current->next;
		skynet_free(temp);	
	}while(current);
}


// 从超时列表中获取到时的消息来分发
static inline void timer_execute(struct timer *T) 
{
	int idx = T->time & TIME_NEAR_MASK;	//TIME_NEAR_MASK = 0xFF 255

	while(T->near[idx].head.next) 
	{
		struct timer_node *current = link_clear(&T->near[idx]);
		SPIN_UNLOCK(T);
		// dispatch_list don't need lock T
		dispatch_list(current);
		SPIN_LOCK(T);
	}
}

// 时间每过一个滴答，执行一次该函数
static void timer_update(struct timer *T) 
{
	SPIN_LOCK(T);

	// try to dispatch timeout 0 (rare condition)
	timer_execute(T);

	// shift time first, and then dispatch timer message
	// 偏移定时器 并且分发定时器消息 定时器迁移到它合法的容器位置
	timer_shift(T);

	timer_execute(T);

	SPIN_UNLOCK(T);
}

static struct timer *timer_create_timer() 
{
	struct timer *r = (struct timer *)skynet_malloc(sizeof(struct timer));
	memset(r, 0, sizeof(*r));

	int i, j;

	for(i = 0; i < TIME_NEAR; ++i) 	//TIME_NEAR = 1 << 8 = 256
	{
		link_clear(&r->near[i]);
	}

	for(i = 0; i < 4; ++i) 
	{
		for(j = 0; j < TIME_LEVEL; ++j) 	//TIME_LEVEL = 1 << 6 = 64
		{
			link_clear(&r->t[i][j]);
		}
	}

	SPIN_INIT(r)

	r->current = 0;

	return r;
}

// 插入定时器，time的单位是0.01秒，如time=300，表示3秒
int skynet_timeout(uint32_t handle, int time, int session) 
{
	if(time <= 0) 
	{
		struct skynet_message message;
		message.source = 0;
		message.session = session;
		message.data = NULL;
		message.sz = (size_t)PTYPE_RESPONSE << MESSAGE_TYPE_SHIFT;

		if(skynet_context_push(handle, &message)) 
		{
			return -1;
		}
	} 
	else 
	{
		struct timer_event event;
		event.handle = handle;
		event.session = session;
		timer_add(TI, &event, sizeof(event), time);
	}

	return session;
}

// centisecond: 1/100 second
static void systime(uint32_t *sec, uint32_t *cs) 
{
#if !defined(__APPLE__)
	struct timespec ti;
	clock_gettime(CLOCK_REALTIME, &ti);
	*sec = (uint32_t)ti.tv_sec;
	*cs = (uint32_t)(ti.tv_nsec / 10000000);
#else
	struct timeval tv;
	gettimeofday(&tv, NULL);
	*sec = tv.tv_sec;
	*cs = tv.tv_usec / 10000;
#endif
}

// 返回系统开机到现在的时间，单位是百分之一秒 0.01s
static uint64_t gettime() 
{
	uint64_t t;
#if !defined(__APPLE__)
	struct timespec ti;
	clock_gettime(CLOCK_MONOTONIC, &ti);
	t = (uint64_t)ti.tv_sec * 100;
	t += ti.tv_nsec / 10000000;
#else
	struct timeval tv;
	gettimeofday(&tv, NULL);
	t = (uint64_t)tv.tv_sec * 100;	 // 实际上这里如果是相对时间的话舍弃也是不影响的 再乘100 1s等于100个0.01s
	t += tv.tv_usec / 10000;		 // 单位是 0.01 即 10^-2s与 10^-6s的转化
#endif
	return t;
}

void skynet_updatetime() 
{
	uint64_t cp = gettime();
	if(cp < TI->current_point) 
	{
		skynet_error(NULL, "time diff error: change from %lld to %lld", cp, TI->current_point);
		TI->current_point = cp;
	} 
	else if(cp != TI->current_point) 
	{
		uint32_t diff = (uint32_t)(cp - TI->current_point);	// 得到时间间隔
		TI->current_point = cp;
		TI->current += diff;
		int i;
		for(i = 0; i< diff; ++i) 
		{
			timer_update(TI);
		}
	}
}

uint32_t skynet_starttime() 
{
	return TI->starttime;
}

uint64_t skynet_now() 
{
	return TI->current;
}

void skynet_timer_init() 
{
	TI = timer_create_timer();	// 分配定时器结构
	uint32_t current = 0;
	systime(&TI->starttime, &current);
	TI->current = current;
	TI->current_point = gettime();
}

// for profile

#define NANOSEC 1000000000
#define MICROSEC 1000000

uint64_t skynet_thread_time(void) 
{
#if !defined(__APPLE__)
	struct timespec ti;
	clock_gettime(CLOCK_THREAD_CPUTIME_ID, &ti);

	return (uint64_t)ti.tv_sec * MICROSEC + (uint64_t)ti.tv_nsec / (NANOSEC / MICROSEC);
#else
	struct task_thread_times_info aTaskInfo;
	mach_msg_type_number_t aTaskInfoCount = TASK_THREAD_TIMES_INFO_COUNT;
	if(KERN_SUCCESS != task_info(mach_task_self(), TASK_THREAD_TIMES_INFO, (task_info_t )&aTaskInfo, &aTaskInfoCount)) 
	{
		return 0;
	}

	return (uint64_t)(aTaskInfo.user_time.seconds) + (uint64_t)aTaskInfo.user_time.microseconds;
#endif
}
