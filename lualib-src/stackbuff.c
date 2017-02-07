#include <stdio.h>
#include <string.h>
#include "stackBuff.h"

int	StackGetSize(struct StackBuff *s)
{ 
	return s->m_iUseSize - s->m_iCurrent; 
}

void StackClear(struct StackBuff *s)
{
	s->m_iCurrent = 0;
	s->m_iUseSize = 0;
}

void StackSet(struct StackBuff *s, int i, char c)						
{ 
	s->m_szBuff[i] = c;
}

void StackWrite(struct StackBuff *s, const char *szBuff, int iSize)
{
	int iRemainSize = s->m_iPoolSize - s->m_iUseSize;
	if(iRemainSize < iSize)
	{
		if((s->m_iUseSize - s->m_iCurrent) + iSize <= s->m_iPoolSize)
		{
			s->m_iUseSize -= s->m_iCurrent;
			memcpy(s->m_szBuff, s->m_szBuff + s->m_iCurrent, s->m_iUseSize);
			s->m_iCurrent = 0;
		}
		else
		{
			int iScale = iSize / STEP_SIZE + 1;
			int iNewBuffSize = s->m_iPoolSize + STEP_SIZE * iScale;
			char *szNewBuff = (char *)malloc(iNewBuffSize * sizeof(char));
			
			s->m_iUseSize = s->m_iUseSize - s->m_iCurrent;
			memcpy(szNewBuff, s->m_szBuff + s->m_iCurrent, s->m_iUseSize);
			s->m_iCurrent = 0;
			
			s->m_iPoolSize = iNewBuffSize;
			free(s->m_szBuff);
			s->m_szBuff = NULL;
			s->m_szBuff = szNewBuff;
		}
	}
	memcpy(s->m_szBuff + s->m_iUseSize, szBuff, iSize);
	s->m_iUseSize += iSize;
	return;
}

void StackWriteString(struct StackBuff *s, const char *szStr)
{ 
	StackWrite(s, szStr, strlen(szStr)); 
}

char *StackRead(struct StackBuff *s, int iSize)
{
	char *p = s->m_szBuff + s->m_iCurrent;
	s->m_iCurrent += iSize;
	if(m_iCurrent == m_iUseSize) 
	{
		StackClear(s);
	}
	return p;
}

char *StackGetBuff(struct StackBuff *s)								
{ 
	return s->m_szBuff + s->m_iCurrent;
}
