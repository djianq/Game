/* $Id: lmd5lib.c 9576 2009-04-24 12:07:00Z akara $
** md5 lib from python by AKara
*/

#include <errno.h>
#include <locale.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define LUA_LIB

#include "lua.h"

#include "lmd5lib.h"
#include "md5.h"

int calc_md5 (lua_State *L) {
	md5_state_t md5;
	int i, j;
	size_t textlen;
	unsigned char digest[16];
	unsigned char hexdigest[32];
	const char *text = lua_tolstring(L, 1, &textlen);

	if (text == NULL)
	{
		lua_pushnil(L);
		return 1;
	}

	md5_init(&md5);	/* actual initialisation */
	md5_append(&md5, (const unsigned char*)text, textlen);
	md5_finish(&md5, digest);

	/* Make hex version of the digest */
	for(i=j=0; i<16; i++) {
		char c;
		c = (digest[i] >> 4) & 0xf;
		c = (c>9) ? c+'a'-10 : c + '0';
		hexdigest[j++] = c;
		c = (digest[i] & 0xf);
		c = (c>9) ? c+'a'-10 : c + '0';
		hexdigest[j++] = c;
	}
	
	lua_pushlstring(L, hexdigest, 32);
	return 1;
}
