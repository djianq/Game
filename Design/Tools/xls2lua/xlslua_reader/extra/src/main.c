#include "lua.h"

#include "lauxlib.h"
#include "lualib.h"

#include "md5/lmd5lib.h"
#include "serialize/serialize.h"
#include "unicode/unicode.h"
#include "bit/bit.c"

#define LUA_EXTRALIBNAME "extra"

static const luaL_Reg all_extra[] = {
  {"md5",		calc_md5},
  
  {"serialize", serialize},
  {"reservedtag", get_reserved_tag},

  {"utf8_to_ansi", utf8_to_ansi},
  {"ansi_to_utf8", ansi_to_utf8},

  { "tobit",	bit_tobit },
  { "bnot",	bit_bnot },
  { "band",	bit_band },
  { "bor",	bit_bor },
  { "bxor",	bit_bxor },
  { "lshift",	bit_lshift },
  { "rshift",	bit_rshift },
  { "arshift",	bit_arshift },
  { "rol",	bit_rol },
  { "ror",	bit_ror },
  { "bswap",	bit_bswap },
  { "tohex",	bit_tohex },
  {NULL, NULL}
};

__declspec(dllexport) LUALIB_API int luaopen_extra (lua_State *L) {
  luaL_register(L, LUA_EXTRALIBNAME, all_extra);
  return 1;
}
