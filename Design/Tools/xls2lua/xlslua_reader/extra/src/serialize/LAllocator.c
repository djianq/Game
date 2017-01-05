#include "FFAllocator.h"

static buckets_t bucket;

void lmemory_init()
{
	ff_buckets_t_init(&bucket);
}

void* lmemory_malloc(size_t size)
{
#ifdef ARK_ALLOC_DETAIL_LOG
	char logbuf[128];
	void* ptr = ff_malloc(&bucket, size);
	sprintf(logbuf, "malloc(%08X) => %08X", size, ptr);
	ff_alloc_detail_log(logbuf);
	return ptr;
#else
	return ff_malloc(&bucket, size);
#endif
}

void lmemory_free(void* ptr)
{
#ifdef ARK_ALLOC_DETAIL_LOG
	char logbuf[128];
	sprintf(logbuf, "free(%08X)", ptr);
	ff_alloc_detail_log(logbuf);
#endif
	ff_free(&bucket, ptr);
}

void* lmemory_realloc(void* ptr, size_t size)
{
#ifdef ARK_ALLOC_DETAIL_LOG
	char logbuf[128];
	void* new_ptr = ff_realloc(&bucket, ptr, 0, size);
	sprintf(logbuf, "realloc(%08X, %08X) => %08X", ptr, size, new_ptr);
	ff_alloc_detail_log(logbuf);
	return new_ptr;
#else
	return ff_realloc(&bucket, ptr, 0, size);
#endif
}

