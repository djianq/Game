#ifndef l_allocator_h
#define l_allocator_h

extern void  lmemory_init();
extern void* lmemory_malloc(size_t size);
extern void  lmemory_free(void* ptr);
extern void* lmemory_realloc(void* ptr, size_t size);

#endif

