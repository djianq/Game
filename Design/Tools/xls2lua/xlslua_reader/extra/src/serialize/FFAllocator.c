//
// $Id: lmemory.cpp 71395 2009-02-17 07:03:20Z tony $
//

#include <sys/types.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

#include "FFAllocator.h"

#define FHEADER_SIZE (sizeof(free_list_t))
#define FREELIST_T( m ) ((free_list_t*)(m))
#define FHEADER( m ) ( (free_list_t*)((char*)m - FHEADER_SIZE) )

#define BIGHEADER_SIZE (sizeof(size_t))
#define FBIGHEADER(p) ( (size_t*)( (char*)(p) - FHEADER_SIZE - BIGHEADER_SIZE) )
#define BIGHEADER(p) (*(size_t*)(p))

#ifdef __DEBUG_LMEMORY
//观察哪个区段的内存用的最多
int size_view[NBUCKETS];
#endif

buckets_t* ff_buckets_t_init( buckets_t* ud )
{
	buckets_t* ret;
	size_t size;
	int i;

	if( ud == 0 )
	{
		ret = (buckets_t*)malloc( sizeof(buckets_t) );
		if( ret == 0 )
			return 0;
		ret->bfree_ = 1;
	}
	else
	{
		ret = (buckets_t*)ud;
		ret->bfree_ = 0;
	}
	
	//bzero( ret->first_, sizeof(ret->first_) );
	memset( ret->first_, 0, sizeof(ret->first_) );
	
	size = MINSIZE;
	for( i = 0; i < NBUCKETS; ++i )
	{
		ret->fsize_[i] = size;
		if( size < MAXSIZE )
			size *= 2;
		else
			size += MAXSIZE;
	}
	ret->nblocks_ = 0;
	ret->big_msize = 0;
	return ret;
}

void ff_create_memory( buckets_t* ud, free_list_t* fl )
{
	register void* mb;
	register void* ptr;
	register void* h;
	register size_t n;
	register size_t size;

	assert( ud && fl );

	mb = (void*)malloc( BLOCKSIZE );
	if( mb == 0 )
		return;

	ud->nblocks_++;

	assert( fl - ud->first_ >=0 && fl - ud->first_ < NBUCKETS );
	size = ( ud->fsize_[ fl - ud->first_ ] + FHEADER_SIZE );
#ifdef __DEBUG_LMEMORY
	size_view[fl - ud->first_]++;
#endif

	n = ( BLOCKSIZE - FHEADER_SIZE ) / size;
	ptr = (char*)mb + FHEADER_SIZE;

	while( n > 0 )
	{
		h = (char*)ptr + size;
		FREELIST_T(ptr)->next_ = (free_list_t*)h;
		ptr = h;
		n--;
	}
	FREELIST_T((char*)ptr - size)->next_ = fl->next_;
	fl->next_ = (free_list_t*)((char*)mb + FHEADER_SIZE);	
}

void* ff_malloc( buckets_t* ud, size_t nsize )
{
	register int n;
	register free_list_t* h;
	char* ptr;

	assert( ud );

	if( nsize <= 0 )
		return 0;

	n = 0;
	while( nsize > ud->fsize_[n] && n < NBUCKETS ) ++n;

	if( n >= 0 && n < NBUCKETS )
	{
		if( ud->first_[n].next_ == 0 )
		{
			ff_create_memory( ud, ud->first_+n );
		}
		if( ud->first_[n].next_ == 0 )
			return 0;
		
		h = ud->first_[n].next_;
		ud->first_[n].next_ = h->next_;
		h->next_ = ud->first_ + n;
		return (char*)h + FHEADER_SIZE;
	}
	else
	{
		size_t length = nsize + FHEADER_SIZE + BIGHEADER_SIZE;
		ptr = (char*)malloc( length );
		if( ptr )
		{
			ud->big_msize += length;
			BIGHEADER(ptr) = length;
			h = FREELIST_T(ptr + BIGHEADER_SIZE);
			h->next_ = ud->first_ + NBUCKETS;
			return (char*)h + FHEADER_SIZE;
		}
		return NULL;
	}
}

void ff_free( buckets_t* ud, void* ptr )
{
	register int n;
	register free_list_t* h;
	assert( ud );

	if( ptr == 0 )
		return;
	h = FHEADER( ptr );
	n = h->next_ - ud->first_;
	if( n >= 0 && n < NBUCKETS )
	{
		h->next_ = ud->first_[n].next_;
		ud->first_[n].next_ = h;
	}
	else
	{
		ud->big_msize -= BIGHEADER(FBIGHEADER(ptr));
		free( FBIGHEADER(ptr) );
	}
}


void* ff_realloc( void* bt, void* ptr, size_t nouse, size_t nsize )
{
	register buckets_t* ud;
	register int n;
	register size_t osize;
	register free_list_t* h;
	register void* nb;

	assert( bt );	
	ud = (buckets_t*)bt;
	if( ptr == 0 )
		return ff_malloc( ud, nsize );
	if( nouse == nsize )
		return ptr;

	h = FHEADER( ptr );
	n = h->next_ - ud->first_;
	if( n >=0 && n < NBUCKETS )
	{
		osize = ud->fsize_[n];
		if( nsize <= osize && nsize > ( (n>=1) ? ud->fsize_[n-1] : 0 ) )
			return ptr;
		nb = ff_malloc( ud, nsize );
		if( nb )
			memcpy( nb, ptr, ( (osize < nsize) ? osize : nsize ) );
		if( nb || nsize == 0 )
			ff_free( ud, ptr );
		return nb;
	}
	else
	{
		if( nsize > 0 )
		{
			size_t length = nsize + BIGHEADER_SIZE + FHEADER_SIZE;
			size_t olen = BIGHEADER(FBIGHEADER(ptr));
			char* nptr = (char*)realloc( FBIGHEADER(ptr), length);
			if (! nptr)
				return NULL;
			ud->big_msize += length - olen;
			BIGHEADER(nptr) = length;
			return ( nptr + FHEADER_SIZE + BIGHEADER_SIZE);
		}
		else
		{
			ff_free(ud, ptr );
			return NULL;
		}
	}
}

//只能取出在first_管理下的内存块数量
//非规则大小的内存块的大小是单独维护
unsigned int ff_bucket_count( buckets_t* ud ) 
{
	return ud->nblocks_ * BLOCKSIZE + ud->big_msize;
}
unsigned int bucket_free_count(buckets_t* ud)
{
	int i;
	int size;
	free_list_t* ptr;
	unsigned int count_size = 0;
	for(i = 0; i < NBUCKETS; i++)
	{
		size = ud->fsize_[i];
		for( ptr = &ud->first_[i]; ptr != NULL; ptr = ptr->next_)
			count_size += size;
	}
	return count_size;
}

#ifdef __DEBUG_LMEMORY
const char* get_size_view(buckets_t* ud)
{
	static char strbuf[512];
	bzero(strbuf, sizeof(strbuf));
	for (int i = 0; i < NBUCKETS; i++)
	{
		snprintf(strbuf, sizeof(strbuf), "%s, %d:%d", strbuf, ud->fsize_[i], size_view[i]);
	}
	return strbuf;
}
const char* get_free_view(buckets_t* ud)
{
	static char strbuf[512];
	bzero(strbuf, sizeof(strbuf));
	for (int i = 0; i < NBUCKETS; i++)
	{
		int size = ud->fsize_[i];
		int count = 0;
		for( free_list_t* ptr = &ud->first_[i]; ptr != NULL; ptr = ptr->next_)
			count += size;
		snprintf(strbuf, sizeof(strbuf), "%s, %d:%d", strbuf, size, count/1024/1024);
	}
	return strbuf;
}
#endif

