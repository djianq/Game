#include "skynet.h"
#include "skynet_server.h"
#include "skynet_imp.h"
#include "skynet_mq.h"
#include "skynet_handle.h"
#include "skynet_module.h"
#include "skynet_timer.h"
#include "skynet_monitor.h"
#include "skynet_socket.h"
#include "skynet_daemon.h"
#include "skynet_harbor.h"

#include <pthread.h>
#include <unistd.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>

struct monitor 
{
	int count;					// 工作者线程数 skynet内部实际上是 count + 3 多了3个线程的
	struct skynet_monitor **m;	// monitor 工作线程监控表
	pthread_cond_t cond;		// 条件变量
	pthread_mutex_t mutex;		// 互斥锁 条件变量和互斥锁实现线程的同步
	int sleep;					// 睡眠中的工作者线程数
	int quit;
};

// 用于线程参数 工作线程
struct worker_parm 
{
	struct monitor *m;
	int id;
	int weight;
};

static int SIG = 0;

static void handle_hup(int signal) 
{
	if(signal == SIGHUP) 
	{
		SIG = 1;
	}
}

#define CHECK_ABORT if(skynet_context_total() == 0) break;	// 服务数为0

static void create_thread(pthread_t *thread, void *(*start_routine)(void *), void *arg) 
{
	if(pthread_create(thread, NULL, start_routine, arg)) 
	{
		fprintf(stderr, "Create thread failed");
		exit(1);
	}
}

// 全部线程都睡眠的情况下才唤醒一个工作线程(即只要有工作线程处于工作状态，则不需要唤醒)
static void wakeup(struct monitor *m, int busy) 
{
	if(m->sleep >= m->count - busy) // 睡眠的线程
	{
		// signal sleep worker, "spurious wakeup" is harmless
		pthread_cond_signal(&m->cond);
	}
}

static void *thread_socket(void *p) 
{
	struct monitor *m = p;
	skynet_initthread(THREAD_SOCKET);
	for(;;) 
	{
		int r = skynet_socket_poll();
		if(r == 0)
			break;
		if(r < 0) 
		{
			CHECK_ABORT
			continue;
		}

		// 有socket消息返回
		wakeup(m, 0);	// 全部线程都睡眠的情况下才唤醒一个工作线程(即只要有工作线程处于工作状态，则不需要唤醒)
	}
	return NULL;
}

static void free_monitor(struct monitor *m) 
{
	int i;
	int n = m->count;
	for(i = 0; i < n; ++i) 
	{
		skynet_monitor_delete(m->m[i]);
	}
	pthread_mutex_destroy(&m->mutex);
	pthread_cond_destroy(&m->cond);
	skynet_free(m->m);
	skynet_free(m);
}

// 用于监控是否有消息没有即时处理
static void *thread_monitor(void *p) 
{
	struct monitor *m = p;
	int i;
	int n = m->count;
	skynet_initthread(THREAD_MONITOR);
	for(;;) 
	{
		CHECK_ABORT
		for(i = 0; i < n; ++i) 
		{
			skynet_monitor_check(m->m[i]);
		}
		for(i = 0; i < 5; ++i) 
		{
			CHECK_ABORT
			sleep(1);
		}
	}

	return NULL;
}

static void signal_hup() 
{
	// make log file reopen

	struct skynet_message smsg;
	smsg.source = 0;
	smsg.session = 0;
	smsg.data = NULL;
	smsg.sz = (size_t)PTYPE_SYSTEM << MESSAGE_TYPE_SHIFT;
	uint32_t logger = skynet_handle_findname("logger");
	if(logger) 
	{
		skynet_context_push(logger, &smsg);
	}
}

// 用于定时器
static void *thread_timer(void *p) 
{
	struct monitor *m = p;
	skynet_initthread(THREAD_TIMER);
	for(;;) 
	{
		skynet_updatetime();
		CHECK_ABORT
		wakeup(m, m->count - 1);	// 只要有一个睡眠线程就唤醒，让工作线程热起来
		usleep(2500);
		if(SIG) 
		{
			signal_hup();
			SIG = 0;
		}
	}
	// wakeup socket thread
	skynet_socket_exit();
	// wakeup all worker thread
	pthread_mutex_lock(&m->mutex);
	m->quit = 1;
	pthread_cond_broadcast(&m->cond);
	pthread_mutex_unlock(&m->mutex);
	return NULL;
}

// 工作线程
static void *thread_worker(void *p) 
{
	struct worker_parm *wp = p;
	int id = wp->id;
	int weight = wp->weight;
	struct monitor *m = wp->m;
	struct skynet_monitor *sm = m->m[id];
	skynet_initthread(THREAD_WORKER);
	struct message_queue *q = NULL;
	while(!m->quit) 
	{
		q = skynet_context_message_dispatch(sm, q, weight);
		if(q == NULL) 
		{
			if(pthread_mutex_lock(&m->mutex) == 0) 
			{
				++m->sleep;
				// "spurious wakeup" is harmless,
				// because skynet_context_message_dispatch() can be call at any time.
				// 假装的醒来时无害的 因为 skynet_ctx_msg_dispatch() 可以在任何时候被调用
				if(!m->quit)
					pthread_cond_wait(&m->cond, &m->mutex);
				--m->sleep;
				if(pthread_mutex_unlock(&m->mutex)) 
				{
					fprintf(stderr, "unlock mutex error");
					exit(1);
				}
			}
		}
	}
	return NULL;
}

static void start(int thread) 
{
	pthread_t pid[thread + 3];	// 线程数+3 3个线程分别用于 _monitor _timer  _socket 监控 定时器 socket IO

	struct monitor *m = skynet_malloc(sizeof(*m));
	memset(m, 0, sizeof(*m));
	m->count = thread;
	m->sleep = 0;

	m->m = skynet_malloc(thread * sizeof(struct skynet_monitor *));
	int i;
	for(i = 0; i < thread; ++i) 
	{
		m->m[i] = skynet_monitor_new();
	}
	if(pthread_mutex_init(&m->mutex, NULL)) 
	{
		fprintf(stderr, "Init mutex error");
		exit(1);
	}
	if(pthread_cond_init(&m->cond, NULL)) 
	{
		fprintf(stderr, "Init cond error");
		exit(1);
	}

	create_thread(&pid[0], thread_monitor, m);
	create_thread(&pid[1], thread_timer, m);
	create_thread(&pid[2], thread_socket, m);

	static int weight[] = 
	{ 
		-1, -1, -1, -1, 0, 0, 0, 0,
		1, 1, 1, 1, 1, 1, 1, 1, 
		2, 2, 2, 2, 2, 2, 2, 2, 
		3, 3, 3, 3, 3, 3, 3, 3, 
	};

	struct worker_parm wp[thread];
	for(i = 0; i < thread; ++i) 
	{
		wp[i].m = m;
		wp[i].id = i;
		if(i < sizeof(weight) / sizeof(weight[0])) 
		{
			wp[i].weight= weight[i];
		} 
		else 
		{
			wp[i].weight = 0;
		}
		create_thread(&pid[i + 3], thread_worker, &wp[i]);
	}

	for(i = 0; i < thread + 3; ++i) 
	{
		pthread_join(pid[i], NULL); 	// 等待所有线程退出
	}

	free_monitor(m); // 释放监控
}

static void bootstrap(struct skynet_context *logger, const char *cmdline) 
{
	int sz = strlen(cmdline);
	char name[sz + 1];
	char args[sz + 1];
	sscanf(cmdline, "%s %s", name, args);
	struct skynet_context *ctx = skynet_context_new(name, args);
	if(ctx == NULL) 
	{
		skynet_error(NULL, "Bootstrap error : %s\n", cmdline);
		skynet_context_dispatchall(logger);
		exit(1);
	}
}

// skynet 启动的时候 初始化
void skynet_start(struct skynet_config *config) 
{
	// register SIGHUP for log file reopen
	struct sigaction sa;
	sa.sa_handler = &handle_hup;
	sa.sa_flags = SA_RESTART;
	sigfillset(&sa.sa_mask);
	sigaction(SIGHUP, &sa, NULL);

	if(config->daemon) 
	{
		if(daemon_init(config->daemon)) 
		{
			exit(1);
		}
	}

	skynet_harbor_init(config->harbor);
	skynet_handle_init(config->harbor);
	skynet_mq_init();
	skynet_module_init(config->module_path);
	skynet_timer_init();
	skynet_socket_init();
	skynet_profile_enable(config->profile);

	struct skynet_context *ctx = skynet_context_new(config->logservice, config->logger);
	if(ctx == NULL) 
	{
		fprintf(stderr, "Can't launch %s service\n", config->logservice);
		exit(1);
	}

	bootstrap(ctx, config->bootstrap);

	start(config->thread);

	// harbor_exit may call socket send, so it should exit before socket_free
	skynet_harbor_exit();
	skynet_socket_free();
	if(config->daemon) 
	{
		daemon_exit(config->daemon);
	}
}
