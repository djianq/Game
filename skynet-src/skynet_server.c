#include "skynet.h"

#include "skynet_server.h"
#include "skynet_module.h"
#include "skynet_handle.h"
#include "skynet_mq.h"
#include "skynet_timer.h"
#include "skynet_harbor.h"
#include "skynet_env.h"
#include "skynet_monitor.h"
#include "skynet_imp.h"
#include "skynet_log.h"
#include "skynet_timer.h"
#include "spinlock.h"
#include "atomic.h"

#include <pthread.h>

#include <string.h>
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <execinfo.h>

#ifdef CALLING_CHECK

#define CHECKCALLING_BEGIN(ctx) if(!(spinlock_trylock(&ctx->calling))) {assert(0);}
#define CHECKCALLING_END(ctx) spinlock_unlock(&ctx->calling);
#define CHECKCALLING_INIT(ctx) spinlock_init(&ctx->calling);
#define CHECKCALLING_DESTROY(ctx) spinlock_destroy(&ctx->calling);
#define CHECKCALLING_DECL struct spinlock calling;

#else

#define CHECKCALLING_BEGIN(ctx)
#define CHECKCALLING_END(ctx)
#define CHECKCALLING_INIT(ctx)
#define CHECKCALLING_DESTROY(ctx)
#define CHECKCALLING_DECL

#endif


// skynet 主要功能 加载服务和通知服务
/*
* 一个模块(.so)加载到skynet框架中，创建出来的一个实例就是一个服务，
* 为每个服务分配一个skynet_context结构
*/


// 每一个服务对应的 skynet_ctx 结构
struct skynet_context 
{
	void *instance;					// 模块xxx_create函数返回的实例 对应 模块的句柄
	struct skynet_module *mod;		// 模块
	void *cb_ud;					// 传递给回调函数的参数，一般是xxx_create函数返回的实例
	skynet_cb cb;					// 回调函数
	struct message_queue *queue;	// 消息队列
	FILE *logfile;
	uint64_t cpu_cost;				// in microsec
	uint64_t cpu_start;				// in microsec
	char result[32];				// 保存命令执行返回结果
	uint32_t handle;				// 服务句柄
	int session_id;					// 会话id
	int ref;						// 线程安全的引用计数，保证在使用的时候，没有被其它线程释放
	int message_count;
	bool init;						// 是否初始化
	bool endless;					// 是否无限循环
	bool profile;

	CHECKCALLING_DECL
};

// skynet 的节点 结构
struct skynet_node 
{
	int total;				// 一个skynet_node的服务数 一个 node 的服务数量
	int init;
	uint32_t monitor_exit;
	pthread_key_t handle_key;
	bool profile;			// default is off
};

static struct skynet_node G_NODE;

int skynet_context_total() 
{
	return G_NODE.total;
}

static void context_inc() 
{
	ATOM_INC(&G_NODE.total);
}

static void context_dec() 
{
	ATOM_DEC(&G_NODE.total);
}

uint32_t skynet_current_handle(void) 
{
	if(G_NODE.init) 
	{
		void *handle = pthread_getspecific(G_NODE.handle_key);
		return (uint32_t)(uintptr_t)handle;
	} 
	else 
	{
		uint32_t v = (uint32_t)(-THREAD_MAIN);
		return v;
	}
}

static void id_to_hex(char * str, uint32_t id) 
{
	int i;
	static char hex[16] = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};
	str[0] = ':';

	 // 转成 16 进制的 0xff ff ff ff 8位
	for(i = 0; i < 8; ++i) 
	{
		str[i + 1] = hex[(id >> ((7 - i) * 4)) & 0xf]; // 依次取 4位 从最高的4位 开始取 在纸上画一下就清楚了
	}
	str[9] = '\0';
}

struct drop_t 
{
	uint32_t handle;
};

static void drop_message(struct skynet_message *msg, void *ud) 
{
	struct drop_t *d = ud;
	skynet_free(msg->data);
	uint32_t source = d->handle;
	assert(source);
	// report error to the message source
	skynet_send(NULL, source, msg->source, PTYPE_ERROR, 0, NULL, 0);
}

// skynet 新的 ctx
struct skynet_context *skynet_context_new(const char *name, const char *param) 
{
	struct skynet_module *mod = skynet_module_query(name);

	if(mod == NULL)
		return NULL;

	void *inst = skynet_module_instance_create(mod);		// 调用模块创建函数
	if(inst == NULL)
		return NULL;
	struct skynet_context *ctx = skynet_malloc(sizeof(*ctx));
	CHECKCALLING_INIT(ctx)

	ctx->mod = mod;
	ctx->instance = inst;
	ctx->ref = 2;
	ctx->cb = NULL;
	ctx->cb_ud = NULL;
	ctx->session_id = 0;
	ctx->logfile = NULL;

	ctx->init = false;
	ctx->endless = false;

	ctx->cpu_cost = 0;
	ctx->cpu_start = 0;
	ctx->message_count = 0;
	ctx->profile = G_NODE.profile;
	// Should set to 0 first to avoid skynet_handle_retireall get an uninitialized handle
	ctx->handle = 0;	
	ctx->handle = skynet_handle_register(ctx);	// 注册，得到一个唯一的句柄
	struct message_queue *queue = ctx->queue = skynet_mq_create(ctx->handle);
	// init function maybe use ctx->handle, so it must init at last
	context_inc();	// 节点服务数加1

	CHECKCALLING_BEGIN(ctx)
	int r = skynet_module_instance_init(mod, inst, ctx, param);
	CHECKCALLING_END(ctx)
	if(r == 0) 
	{
		struct skynet_context *ret = skynet_context_release(ctx);
		if(ret) 
		{
			ctx->init = true;
		}

		/*
		ctx 的初始化流程是可以发送消息出去的（同时也可以接收到消息），但在初始化流程完成前，
		接收到的消息都必须缓存在 mq 中，不能处理。我用了个小技巧解决这个问题。就是在初始化流程开始前，
		假装 mq 在 globalmq 中（这是由 mq 中一个标记位决定的）。这样，向它发送消息，并不会把它的 mq 压入 globalmq ，
		自然也不会被工作线程取到。等初始化流程结束，在强制把 mq 压入 globalmq （无论是否为空）。即使初始化失败也要进行这个操作。
		*/

		// 初始化流程结构后将这个 ctx 对应的 mq 强制压入 globalmq

		skynet_globalmq_push(queue);
		if(ret) 
		{
			skynet_error(ret, "LAUNCH %s %s", name, param ? param : "");
		}
		return ret;
	}
	else 
	{
		skynet_error(ctx, "FAILED launch %s", name);
		uint32_t handle = ctx->handle;
		skynet_context_release(ctx);
		skynet_handle_retire(handle);
		struct drop_t d = {handle};
		skynet_mq_release(queue, drop_message, &d);
		return NULL;
	}
}

// 分配一个session id
int skynet_context_newsession(struct skynet_context *ctx) 
{
	// session always be a positive number
	int session = ++ctx->session_id;
	if (session <= 0) {
		ctx->session_id = 1;
		return 1;
	}
	return session;
}

void skynet_context_grab(struct skynet_context *ctx) 
{
	ATOM_INC(&ctx->ref); // skynet_context引用计数加1
}

/*
问题就在这里:
handle 和 ctx 的绑定关系是在 ctx 模块外部操作的（不然也做不到 ctx 的正确销毁），

无法确保从 handle 确认对应的 ctx 无效的同时，ctx 真的已经被销毁了。
所以，当工作线程判定 mq 可以销毁时（对应的 handle 无效），ctx 可能还活着（另一个工作线程还持有其引用），
持有这个 ctx 的工作线程可能正在它生命的最后一刻，向其发送消息。结果 mq 已经销毁了。

当 ctx 销毁前，由它向其 mq 设入一个清理标记。然后在 globalmq 取出 mq ，发现已经找不到 handle 对应的 ctx 时，
先判断是否有清理标记。如果没有，再将 mq 重放进 globalmq ，直到清理标记有效，在销毁 mq 。
*/


void skynet_context_reserve(struct skynet_context *ctx) 
{
	skynet_context_grab(ctx);
	// don't count the context reserved, because skynet abort (the worker threads terminate) only when the total context is 0 .
	// the reserved context will be release at last.
	context_dec();
}

static void delete_context(struct skynet_context *ctx) 
{
	if(ctx->logfile) 
	{
		fclose(ctx->logfile);
	}
	skynet_module_instance_release(ctx->mod, ctx->instance);
	skynet_mq_mark_release(ctx->queue);	// 设置标记位 并且把它压入 global mq
	CHECKCALLING_DESTROY(ctx)
	skynet_free(ctx);
	context_dec();	// 这个节点对应的服务数也 减 1
}

struct skynet_context *skynet_context_release(struct skynet_context *ctx) 
{
	// 引用计数减1，减为0则删除skynet_context
	if(ATOM_DEC(&ctx->ref) == 0) 
	{
		delete_context(ctx);
		return NULL;
	}
	return ctx;
}

// 往handle标识的服务中插入一条消息
int skynet_context_push(uint32_t handle, struct skynet_message *message) 
{
	struct skynet_context *ctx = skynet_handle_grab(handle);
	if(ctx == NULL) 
	{
		return -1;
	}
	skynet_mq_push(ctx->queue, message);
	skynet_context_release(ctx);

	return 0;
}

void skynet_context_endless(uint32_t handle) 
{
	struct skynet_context *ctx = skynet_handle_grab(handle);
	if(ctx == NULL) 
	{
		return;
	}
	ctx->endless = true;
	skynet_context_release(ctx);
}

int skynet_isremote(struct skynet_context *ctx, uint32_t handle, int *harbor) 
{
	int ret = skynet_harbor_message_isremote(handle); // 判断是否是远程消息
	if(harbor) 
	{
		*harbor = (int)(handle >> HANDLE_REMOTE_SHIFT); // 返回harbor(注：高8位存的是harbor) yes
	}
	return ret;
}

static void dispatch_message(struct skynet_context *ctx, struct skynet_message *msg) 
{
	assert(ctx->init);
	CHECKCALLING_BEGIN(ctx)
	pthread_setspecific(G_NODE.handle_key, (void *)(uintptr_t)(ctx->handle));
	int type = msg->sz >> MESSAGE_TYPE_SHIFT; // 高8位存消息类别
	size_t sz = msg->sz & MESSAGE_TYPE_MASK; // 低24位消息大小
	if(ctx->logfile) 
	{
		skynet_log_output(ctx->logfile, msg->source, type, msg->session, msg->data, sz);
	}
	++ctx->message_count;
	int reserve_msg;
	if(ctx->profile) 
	{
		ctx->cpu_start = skynet_thread_time();
		reserve_msg = ctx->cb(ctx, ctx->cb_ud, type, msg->session, msg->source, msg->data, sz);
		uint64_t cost_time = skynet_thread_time() - ctx->cpu_start;
		ctx->cpu_cost += cost_time;
	} 
	else
	 {
		reserve_msg = ctx->cb(ctx, ctx->cb_ud, type, msg->session, msg->source, msg->data, sz);
	}
	if(!reserve_msg)
	{
		skynet_free(msg->data);
	}
	CHECKCALLING_END(ctx)
}

void skynet_context_dispatchall(struct skynet_context *ctx) 
{
	// for skynet_error
	struct skynet_message msg;
	struct message_queue *q = ctx->queue;
	while(!skynet_mq_pop(q, &msg)) 
	{
		dispatch_message(ctx, &msg);
	}
}

struct message_queue *skynet_context_message_dispatch(struct skynet_monitor *sm, struct message_queue *q, int weight) 
{
	if(q == NULL) 
	{
		q = skynet_globalmq_pop();
		if(q == NULL)
			return NULL;
	}

	uint32_t handle = skynet_mq_handle(q);

	struct skynet_context *ctx = skynet_handle_grab(handle);
	if(ctx == NULL) 
	{
		struct drop_t d = {handle};
		skynet_mq_release(q, drop_message, &d);
		return skynet_globalmq_pop();
	}

	int i, n = 1;
	struct skynet_message msg;

	for(i = 0; i < n; ++i) 
	{
		if(skynet_mq_pop(q, &msg)) 
		{
			skynet_context_release(ctx);
			return skynet_globalmq_pop();
		} 
		else if(i == 0 && weight >= 0) 
		{
			n = skynet_mq_length(q);
			n >>= weight;
		}
		int overload = skynet_mq_overload(q);
		if(overload) 
		{
			skynet_error(ctx, "May overload, message queue length = %d", overload);
		}

		skynet_monitor_trigger(sm, msg.source, handle);

		if(ctx->cb == NULL) 
		{
			skynet_free(msg.data);
		} 
		else 
		{
			dispatch_message(ctx, &msg);
		}

		skynet_monitor_trigger(sm, 0, 0);
	}

	assert(q == ctx->queue);
	struct message_queue *nq = skynet_globalmq_pop();
	if(nq) 
	{
		// If global mq is not empty , push q back, and return next queue (nq)
		// Else (global mq is empty or block, don't push q back, and return q again (for next dispatch)
		skynet_globalmq_push(q);
		q = nq;
	} 
	skynet_context_release(ctx);

	return q;
}

static void copy_name(char name[GLOBALNAME_LENGTH], const char *addr) 
{
	int i;
	for(i = 0; i < GLOBALNAME_LENGTH && addr[i]; ++i) 
	{
		name[i] = addr[i];
	}
	for(; i < GLOBALNAME_LENGTH; ++i) 
	{
		name[i] = '\0';
	}
}

uint32_t skynet_queryname(struct skynet_context *context, const char *name) 
{
	switch(name[0]) 
	{
	case ':':
		return strtoul(name + 1, NULL, 16);
	case '.':
		return skynet_handle_findname(name + 1);
	}
	skynet_error(context, "Don't support query global name %s", name);
	return 0;
}

static void handle_exit(struct skynet_context *context, uint32_t handle) 
{
	if(handle == 0) 
	{
		handle = context->handle;
		skynet_error(context, "KILL self");
	} 
	else 
	{
		skynet_error(context, "KILL :%0x", handle);
	}
	if(G_NODE.monitor_exit) 
	{
		skynet_send(context,  handle, G_NODE.monitor_exit, PTYPE_CLIENT, 0, NULL, 0);
	}
	skynet_handle_retire(handle);
}

// skynet command

struct command_func 
{
	const char *name;
	const char *(*func)(struct skynet_context *context, const char *param);
};

static const char *cmd_timeout(struct skynet_context *context, const char *param) 
{
	char *session_ptr = NULL;
	int ti = strtol(param, &session_ptr, 10);
	int session = skynet_context_newsession(context);
	skynet_timeout(context->handle, ti, session);
	sprintf(context->result, "%d", session);
	return context->result;
}

static const char *cmd_reg(struct skynet_context *context, const char *param) 
{
	if(param == NULL || param[0] == '\0') 
	{
		sprintf(context->result, ":%x", context->handle);
		return context->result;
	} 
	else if(param[0] == '.') 
	{
		return skynet_handle_namehandle(context->handle, param + 1);
	} 
	else 
	{
		skynet_error(context, "Can't register global name %s in C", param);
		return NULL;
	}
}

static const char *cmd_query(struct skynet_context *context, const char *param) 
{
	if(param[0] == '.') 
	{
		uint32_t handle = skynet_handle_findname(param + 1);
		if(handle) 
		{
			sprintf(context->result, ":%x", handle);
			return context->result;
		}
	}
	return NULL;
}

static const char *cmd_name(struct skynet_context *context, const char *param) 
{
	int size = strlen(param);
	char name[size + 1];
	char handle[size + 1];
	sscanf(param, "%s %s", name, handle);
	if(handle[0] != ':') 
	{
		return NULL;
	}
	uint32_t handle_id = strtoul(handle + 1, NULL, 16);
	if(handle_id == 0) 
	{
		return NULL;
	}
	if(name[0] == '.') 
	{
		return skynet_handle_namehandle(handle_id, name + 1);
	} 
	else 
	{
		skynet_error(context, "Can't set global name %s in C", name);
	}
	return NULL;
}

static const char *cmd_exit(struct skynet_context *context, const char *param) 
{
	handle_exit(context, 0);
	return NULL;
}

static uint32_t tohandle(struct skynet_context *context, const char *param) 
{
	uint32_t handle = 0;
	if(param[0] == ':') 
	{
		handle = strtoul(param+1, NULL, 16);
	} 
	else if(param[0] == '.') 
	{
		handle = skynet_handle_findname(param + 1);
	} 
	else 
	{
		skynet_error(context, "Can't convert %s to handle", param);
	}

	return handle;
}

static const char *cmd_kill(struct skynet_context *context, const char *param) 
{
	uint32_t handle = tohandle(context, param);
	if(handle) 
	{
		handle_exit(context, handle);
	}
	return NULL;
}

static const char *cmd_launch(struct skynet_context *context, const char *param) 
{
	size_t sz = strlen(param);
	char tmp[sz + 1];
	strcpy(tmp, param);
	char *args = tmp;
	char *mod = strsep(&args, " \t\r\n");
	args = strsep(&args, "\r\n");
	if(strcmp("cmaster", args) == 0)
	{
		// print_stacktrace();
	}
	struct skynet_context *inst = skynet_context_new(mod, args);
	if(inst == NULL) 
	{
		return NULL;
	} 
	else 
	{
		id_to_hex(context->result, inst->handle);
		return context->result;
	}
}

static const char *cmd_getenv(struct skynet_context *context, const char *param) 
{
	return skynet_getenv(param);
}

static const char *cmd_setenv(struct skynet_context *context, const char *param) 
{
	size_t sz = strlen(param);
	char key[sz + 1];
	int i;
	for(i = 0; param[i] != ' ' && param[i]; ++i) 
	{
		key[i] = param[i];
	}
	if(param[i] == '\0')
		return NULL;

	key[i] = '\0';
	param += i + 1;
	
	skynet_setenv(key,param);
	return NULL;
}

static const char *cmd_starttime(struct skynet_context *context, const char *param) 
{
	uint32_t sec = skynet_starttime();
	sprintf(context->result, "%u", sec);
	return context->result;
}

static const char *cmd_abort(struct skynet_context *context, const char *param) 
{
	skynet_handle_retireall();
	return NULL;
}

static const char *cmd_monitor(struct skynet_context *context, const char *param) 
{
	uint32_t handle = 0;
	if(param == NULL || param[0] == '\0') 
	{
		if(G_NODE.monitor_exit) 
		{
			// return current monitor serivce
			sprintf(context->result, ":%x", G_NODE.monitor_exit);
			return context->result;
		}
		return NULL;
	} 
	else 
	{
		handle = tohandle(context, param);
	}
	G_NODE.monitor_exit = handle;
	return NULL;
}

static const char *cmd_stat(struct skynet_context *context, const char *param) 
{
	if(strcmp(param, "mqlen") == 0) 
	{
		int len = skynet_mq_length(context->queue);
		sprintf(context->result, "%d", len);
	} 
	else if(strcmp(param, "endless") == 0) 
	{
		if(context->endless) 
		{
			strcpy(context->result, "1");
			context->endless = false;
		} 
		else 
		{
			strcpy(context->result, "0");
		}
	} 
	else if(strcmp(param, "cpu") == 0) 
	{
		double t = (double)context->cpu_cost / 1000000.0;	// microsec
		sprintf(context->result, "%lf", t);
	} 
	else if(strcmp(param, "time") == 0) 
	{
		if(context->profile) 
		{
			uint64_t ti = skynet_thread_time() - context->cpu_start;
			double t = (double)ti / 1000000.0;	// microsec
			sprintf(context->result, "%lf", t);
		} 
		else 
		{
			strcpy(context->result, "0");
		}
	} 
	else if(strcmp(param, "message") == 0) 
	{
		sprintf(context->result, "%d", context->message_count);
	} 
	else 
	{
		context->result[0] = '\0';
	}
	return context->result;
}
static const char *cmd_logon(struct skynet_context *context, const char *param) 
{
	uint32_t handle = tohandle(context, param);
	if(handle == 0)
		return NULL;
	struct skynet_context *ctx = skynet_handle_grab(handle);
	if(ctx == NULL)
		return NULL;
	FILE *f = NULL;
	FILE *lastf = ctx->logfile;
	if(lastf == NULL) 
	{
		f = skynet_log_open(context, handle);
		if(f) 
		{
			if(!ATOM_CAS_POINTER(&ctx->logfile, NULL, f)) 
			{
				// logfile opens in other thread, close this one.
				fclose(f);
			}
		}
	}
	skynet_context_release(ctx);
	return NULL;
}

static const char *cmd_logoff(struct skynet_context *context, const char *param) 
{
	uint32_t handle = tohandle(context, param);
	if(handle == 0)
		return NULL;
	struct skynet_context *ctx = skynet_handle_grab(handle);
	if(ctx == NULL)
		return NULL;
	FILE *f = ctx->logfile;
	if(f)
	{
		// logfile may close in other thread
		if(ATOM_CAS_POINTER(&ctx->logfile, f, NULL)) 
		{
			skynet_log_close(context, f, handle);
		}
	}
	skynet_context_release(ctx);
	return NULL;
}

static const char *cmd_signal(struct skynet_context *context, const char *param) 
{
	uint32_t handle = tohandle(context, param);
	if(handle == 0)
		return NULL;
	struct skynet_context *ctx = skynet_handle_grab(handle);
	if(ctx == NULL)
		return NULL;
	param = strchr(param, ' ');
	int sig = 0;
	if(param) 
	{
		sig = strtol(param, NULL, 0);
	}
	// NOTICE: the signal function should be thread safe.
	skynet_module_instance_signal(ctx->mod, ctx->instance, sig);

	skynet_context_release(ctx);
	return NULL;
}

static struct command_func cmd_funcs[] = 
{
	{"TIMEOUT", cmd_timeout},
	{"REG", cmd_reg},
	{"QUERY", cmd_query},
	{"NAME", cmd_name},
	{"EXIT", cmd_exit},
	{"KILL", cmd_kill},
	{"LAUNCH", cmd_launch},
	{"GETENV", cmd_getenv},
	{"SETENV", cmd_setenv},
	{"STARTTIME", cmd_starttime},
	{"ABORT", cmd_abort},
	{"MONITOR", cmd_monitor},
	{"STAT", cmd_stat},
	{"LOGON", cmd_logon},
	{"LOGOFF", cmd_logoff},
	{"SIGNAL", cmd_signal},
	{NULL, NULL},
};

// 使用了简单的文本协议 来 cmd 操作 skynet的服务
/*
* skynet 提供了一个叫做 skynet_command 的 C API ，作为基础服务的统一入口。
* 它接收一个字符串参数，返回一个字符串结果。你可以看成是一种文本协议。
* 但 skynet_command 保证在调用过程中，不会切出当前的服务线程，导致状态改变的不可预知性。
* 其每个功能的实现，其实也是内嵌在 skynet 的源代码中，相同上层服务，还是比较高效的。
*（因为可以访问许多内存 api ，而不必用消息通讯的方式实现）
*/
void print_stacktrace()
{
	int size = 16;
	void *array[16];
	int stack_num = backtrace(array, size);
	char **stacktrace = backtrace_symbols(array, stack_num);
	int i;
	for(i = 0; i < stack_num; ++i)
	{
		printf("%s\n", stacktrace[i]);
	}
	free(stacktrace);
}

const char *skynet_command(struct skynet_context *context, const char *cmd , const char *param) 
{
	struct command_func *method = &cmd_funcs[0];
	while(method->name) 
	{
		if(strcmp(cmd, method->name) == 0) 
		{
			return method->func(context, param);
		}
		++method;
	}

	return NULL;
}

// 参数过滤
static void _filter_args(struct skynet_context *context, int type, int *session, void **data, size_t *sz) 
{
	int needcopy = !(type & PTYPE_TAG_DONTCOPY);
	int allocsession = type & PTYPE_TAG_ALLOCSESSION;	 // type中含有 PTYPE_TAG_ALLOCSESSION ，则session必须是0
	type &= 0xff;

	if(allocsession) 
	{
		assert(*session == 0);
		*session = skynet_context_newsession(context);	// 分配一个新的 session id
	}

	if(needcopy && *data) 
	{
		char *msg = skynet_malloc(*sz + 1);
		memcpy(msg, *data, *sz);
		msg[*sz] = '\0';
		*data = msg;
	}

	*sz |= (size_t)type << MESSAGE_TYPE_SHIFT;
}

/*
* 向handle为destination的服务发送消息(注：handle为destination的服务不一定是本地的)
* type中含有 PTYPE_TAG_ALLOCSESSION ，则session必须是0
* type中含有 PTYPE_TAG_DONTCOPY ，则不需要拷贝数据
*/

int skynet_send(struct skynet_context *context, uint32_t source, uint32_t destination , int type, int session, void *data, size_t sz) 
{
	if((sz & MESSAGE_TYPE_MASK) != sz) 
	{
		skynet_error(context, "The message to %x is too large", destination);
		if(type & PTYPE_TAG_DONTCOPY) 
		{
			skynet_free(data);
		}
		return -1;
	}
	_filter_args(context, type, &session, (void **)&data, &sz);

	if(source == 0) 
	{
		source = context->handle;
	}

	if(destination == 0) 
	{
		return session;
	}

	// 如果消息时发给远程的
	if(skynet_harbor_message_isremote(destination)) 
	{
		struct remote_message *rmsg = skynet_malloc(sizeof(*rmsg));
		rmsg->destination.handle = destination;
		rmsg->message = data;
		rmsg->sz = sz;
		skynet_harbor_send(rmsg, source, session);
	} 
	else 	// 本机消息 直接压入消息队列
	{
		struct skynet_message smsg;
		smsg.source = source;
		smsg.session = session;
		smsg.data = data;
		smsg.sz = sz;

		if(skynet_context_push(destination, &smsg)) 
		{
			skynet_free(data);
			return -1;
		}
	}
	return session;
}

int skynet_sendname(struct skynet_context *context, uint32_t source, const char *addr , int type, int session, void *data, size_t sz) 
{
	if(source == 0) 
	{
		source = context->handle;
	}
	uint32_t des = 0;
	if(addr[0] == ':') 
	{
		des = strtoul(addr + 1, NULL, 16);	 // strtoul （将字符串转换成无符号长整型数） 如果开始时 :2343 这种形式的 说明就是直接的 handle
	} 
	else if(addr[0] == '.') 	// . 说明是以名字开始的地址 需要根据名字查找 对应的 handle
	{
		des = skynet_handle_findname(addr + 1);	 // 根据名称查找对应的 handle
		if(des == 0) 	// 不需要拷贝的消息类型
		{
			if(type & PTYPE_TAG_DONTCOPY) 
			{
				skynet_free(data);
			}
			return -1;
		}
	} 
	else 	// 其他的目的地址 即远程的地址
	{
		_filter_args(context, type, &session, (void **)&data, &sz);

		struct remote_message *rmsg = skynet_malloc(sizeof(*rmsg));
		copy_name(rmsg->destination.name, addr);
		rmsg->destination.handle = 0;
		rmsg->message = data;
		rmsg->sz = sz;

		skynet_harbor_send(rmsg, source, session);	// 发送给 harbor 去处理远程的消息
		return session;
	}

	return skynet_send(context, source, des, type, session, data, sz);
}

uint32_t skynet_context_handle(struct skynet_context *ctx) 
{
	return ctx->handle;
}

void skynet_callback(struct skynet_context *context, void *ud, skynet_cb cb) 
{
	context->cb = cb;
	context->cb_ud = ud;
}

// 向ctx服务发送消息(注：ctx服务一定是本地的)
void skynet_context_send(struct skynet_context *ctx, void *msg, size_t sz, uint32_t source, int type, int session) 
{
	struct skynet_message smsg;
	smsg.source = source;
	smsg.session = session;
	smsg.data = msg;
	smsg.sz = sz | (size_t)type << MESSAGE_TYPE_SHIFT;

	skynet_mq_push(ctx->queue, &smsg);	// 压入消息队列
}

void skynet_globalinit(void) 
{
	G_NODE.total = 0;
	G_NODE.monitor_exit = 0;
	G_NODE.init = 1;
	if(pthread_key_create(&G_NODE.handle_key, NULL)) 
	{
		fprintf(stderr, "pthread_key_create failed");
		exit(1);
	}
	// set mainthread's key
	skynet_initthread(THREAD_MAIN);
}

void skynet_globalexit(void) 
{
	pthread_key_delete(G_NODE.handle_key);
}

void skynet_initthread(int m) 
{
	uintptr_t v = (uint32_t)(-m);
	pthread_setspecific(G_NODE.handle_key, (void *)v);
}

void skynet_profile_enable(int enable) 
{
	G_NODE.profile = (bool)enable;
}
