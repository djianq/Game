#ifndef SKYNET_SPINLOCK_H
#define SKYNET_SPINLOCK_H

#define SPIN_INIT(q) spinlock_init(&(q)->lock);
#define SPIN_LOCK(q) spinlock_lock(&(q)->lock);
#define SPIN_UNLOCK(q) spinlock_unlock(&(q)->lock);
#define SPIN_DESTROY(q) spinlock_destroy(&(q)->lock);

#ifndef USE_PTHREAD_LOCK

struct spinlock 
{
	int lock;
};

static inline void spinlock_init(struct spinlock *lock) 
{
	lock->lock = 0;
}

static inline void spinlock_lock(struct spinlock *lock) 
{
	while(__sync_lock_test_and_set(&lock->lock, 1)){}	//利用__sync_lock_test_and_set实现的自旋锁 将q->lock设置为1，并返回修改前的值
}

static inline int spinlock_trylock(struct spinlock *lock) 
{
	return __sync_lock_test_and_set(&lock->lock, 1) == 0;
}

static inline void spinlock_unlock(struct spinlock *lock) 
{
	__sync_lock_release(&lock->lock);	// 将q->lock置为0
}

static inline void spinlock_destroy(struct spinlock *lock) 
{
	(void)lock;
}

#else

#include <pthread.h>

// we use mutex instead of spinlock for some reason
// you can also replace to pthread_spinlock

struct spinlock 
{
	pthread_mutex_t lock;
};

static inline void spinlock_init(struct spinlock *lock) 
{
	pthread_mutex_init(&lock->lock, NULL);
}

static inline void spinlock_lock(struct spinlock *lock) 
{
	pthread_mutex_lock(&lock->lock);
}

static inline int spinlock_trylock(struct spinlock *lock) 
{
	return pthread_mutex_trylock(&lock->lock) == 0;
}

static inline void spinlock_unlock(struct spinlock *lock) 
{
	pthread_mutex_unlock(&lock->lock);
}

static inline void spinlock_destroy(struct spinlock *lock) 
{
	pthread_mutex_destroy(&lock->lock);
}

#endif

#endif
