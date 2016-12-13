#ifndef SKYNET_CONTEXT_HANDLE_H
#define SKYNET_CONTEXT_HANDLE_H

#include <stdint.h>

// reserve high 8 bits for remote id
#define HANDLE_MASK 0xffffff	// 24 bits 这里的 handle 只使用了 低  24 位  高  8 位留给远程服务使用 可能在分布式系统中会用到
#define HANDLE_REMOTE_SHIFT 24	// 远程 id 需要偏移 24位得到

struct skynet_context;

uint32_t skynet_handle_register(struct skynet_context *);
int skynet_handle_retire(uint32_t handle);
struct skynet_context *skynet_handle_grab(uint32_t handle);
void skynet_handle_retireall();

uint32_t skynet_handle_findname(const char *name);
const char *skynet_handle_namehandle(uint32_t handle, const char *name);

void skynet_handle_init(int harbor);

#endif
