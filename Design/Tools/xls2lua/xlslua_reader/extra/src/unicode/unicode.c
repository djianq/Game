/* $Id: unicode.c 10224 2009-05-07 01:55:35Z akara $
** 
** ansi <-> unicode <-> utf8
**
*/
#include <string.h>
#include "lua.h"
#include <windows.h>

#include "unicode.h"

wchar_t * AToU( const char* str )
{
	int textlen ;
	wchar_t * result;
	textlen = MultiByteToWideChar( CP_ACP, 0, str,-1, NULL,0 );
	result = (wchar_t *)malloc((textlen+1)*sizeof(wchar_t));
	memset(result,0,(textlen+1)*sizeof(wchar_t));
	MultiByteToWideChar(CP_ACP, 0,str,-1,(LPWSTR)result,textlen );
	return result;
}

char * UToA( const wchar_t *str )
{
	char * result;
	int textlen;
	textlen = WideCharToMultiByte( CP_ACP, 0, str, -1, NULL, 0, NULL, NULL);
	result =(char *)malloc((textlen+1)*sizeof(char));
	memset( result, 0, sizeof(char) * ( textlen + 1 ) );
	WideCharToMultiByte(CP_ACP, 0, str, -1, result, textlen, NULL, NULL);
	return result;
}

wchar_t * U8ToU( const char* str )
{
	int textlen ;
	wchar_t * result;
	textlen = MultiByteToWideChar( CP_UTF8, 0, str,-1, NULL,0 );
	result = (wchar_t *)malloc((textlen+1)*sizeof(wchar_t));
	memset(result,0,(textlen+1)*sizeof(wchar_t));
	MultiByteToWideChar(CP_UTF8, 0,str,-1,(LPWSTR)result,textlen );
	return result;
}

char * UToU8( const wchar_t *str )
{
	char * result;
	int textlen;
	textlen = WideCharToMultiByte( CP_UTF8, 0, str, -1, NULL, 0, NULL, NULL);
	result =(char *)malloc((textlen+1)*sizeof(char));
	memset(result, 0, sizeof(char) * ( textlen + 1 ) );
	WideCharToMultiByte(CP_UTF8, 0, str, -1, result, textlen, NULL, NULL );
	return result;
}

int ansi_to_utf8(lua_State *L)
{
	const char* str;
	wchar_t * temp;
	char* result;
	/*传递第一个参数*/
	str = lua_tostring(L, -1);
	/*开始转换*/
	temp = AToU(str);
	result = UToU8(temp);
	/*返回值，*/
	lua_pushstring(L, result);
	free(temp);
	free(result);
	return 1;
}

int utf8_to_ansi(lua_State *L)
{
	const char* str;
	wchar_t * temp;
	char* result;
	/*传递第一个参数*/
	str = lua_tostring(L, -1);
	/*开始转换*/
	temp = U8ToU(str);
	result = UToA(temp);
	/*返回值，*/
	lua_pushstring(L, result);
	free(temp);
	free(result);
	return 1;
}


