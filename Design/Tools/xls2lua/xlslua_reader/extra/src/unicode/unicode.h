#ifndef unicode_h
#define unicode_h

#define CHAR_SCALE (sizeof(wchar_t)/sizeof(char))

int ansi_to_utf8(lua_State *L);
int utf8_to_ansi(lua_State *L);

#endif