#include "skynet.h"
#include "skynet_harbor.h"
#include "skynet_server.h"
#include "skynet_mq.h"
#include "skynet_handle.h"

#include <string.h>
#include <stdio.h>
#include <assert.h>

// harbor 用来与远程主机通信 master 统一来管理
// http://blog.codingnow.com/2012/09/the_design_of_skynet.html
// 这个是 skynet的设计综述 讲述了 session和 type的作用

static struct skynet_context *REMOTE = 0;	// harbor 服务对应的 skynet_context 指针
static unsigned int HARBOR = ~0;

void skynet_harbor_send(struct remote_message *rmsg, uint32_t source, int session) 
{
	int type = rmsg->sz >> MESSAGE_TYPE_SHIFT;	// 高  8 bite 用于保存 type
	rmsg->sz &= MESSAGE_TYPE_MASK;
	assert(type != PTYPE_SYSTEM && type != PTYPE_HARBOR && REMOTE);
	skynet_context_send(REMOTE, rmsg, sizeof(*rmsg) , source, type , session);
}

// 判断消息是不是来自远程主机的
int skynet_harbor_message_isremote(uint32_t handle) 
{
	assert(HARBOR != ~0);
	int h = (handle & ~HANDLE_MASK);	// 取高8位
	return h != HARBOR && h !=0;
}

void skynet_harbor_init(int harbor) 
{
	HARBOR = (unsigned int)harbor << HANDLE_REMOTE_SHIFT;	// 高8位就是对应远程主机通信的 harbor，将本来低8位置成高8位
}

void skynet_harbor_start(void *ctx) 
{
	// the HARBOR must be reserved to ensure the pointer is valid.
	// It will be released at last by calling skynet_harbor_exit
	skynet_context_reserve(ctx);
	REMOTE = ctx;
}

void skynet_harbor_exit() 
{
	struct skynet_context *ctx = REMOTE;
	REMOTE= NULL;
	if(ctx) 
	{
		skynet_context_release(ctx);
	}
}
