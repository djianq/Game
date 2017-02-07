#ifndef __STACK_BUFF__
#define __STACK_BUFF__
#define	STEP_SIZE 1024
	struct StackBuff
	{
		char *m_szBuff;
		int	m_iCurrent;
		int	m_iUseSize;
		int	m_iPoolSize;
		_Bool m_bIsAutoMode;
	};

	int	StackGetSize(struct StackBuff *s);
	void StackClear(struct StackBuff *s);
	void StackSet(struct StackBuff *s, int i, char c);
	void StackWrite(struct StackBuff *s, const char *szBuff, int iSize);
	void StackWriteString(struct StackBuff *s, const char *szStr);
	char *StackRead(struct StackBuff *s, int iSize);
	char *StackGetBuff(struct StackBuff *s);
#endif