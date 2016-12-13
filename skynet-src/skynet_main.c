#include "skynet.h"

#include "skynet_imp.h"
#include "skynet_env.h"
#include "skynet_server.h"
#include "luashrtbl.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <signal.h>
#include <assert.h>

static int optint(const char *key, int opt) 
{
	const char *str = skynet_getenv(key);
	if(str == NULL) 
	{
		char tmp[20];
		sprintf(tmp, "%d", opt);
		skynet_setenv(key, tmp);
		return opt;
	}
	return strtol(str, NULL, 10);
}

static int optboolean(const char *key, int opt) 
{
	const char *str = skynet_getenv(key);
	if(str == NULL) 
	{
		skynet_setenv(key, opt ? "true" : "false");
		return opt;
	}
	return strcmp(str, "true") == 0;
}

static const char *optstring(const char *key, const char *opt) 
{
	const char *str = skynet_getenv(key);
	if(str == NULL) 
	{
		if(opt) 
		{
			skynet_setenv(key, opt);
			opt = skynet_getenv(key);
		}
		return opt;
	}
	return str;
}

static void _init_env(lua_State *L) 
{
	lua_pushnil(L);  /* first key */
	while(lua_next(L, -2) != 0) // 弹出key并将全局变量表中的全局变量与全局变量值压入lua栈
	{
		int keyt = lua_type(L, -2); // 获取key类型
		if(keyt != LUA_TSTRING) 
		{
			fprintf(stderr, "Invalid config table\n");
			exit(1);
		}
		const char *key = lua_tostring(L, -2); // 获取key
		if(lua_type(L, -1) == LUA_TBOOLEAN) 
		{
			int b = lua_toboolean(L, -1);
			skynet_setenv(key, b ? "true" : "false" );
		} 
		else 
		{
			const char *value = lua_tostring(L, -1); // 获取value
			if(value == NULL)
			{
				fprintf(stderr, "Invalid config table key = %s\n", key);
				exit(1);
			}
			skynet_setenv(key, value);
		}
		lua_pop(L, 1); // 弹出value,保留key,以便下一次迭代
	}
	lua_pop(L, 1); // 弹出全局变量表
}

int sigign() 
{
	struct sigaction sa;
	sa.sa_handler = SIG_IGN; // 忽略信号 控制台关闭时候不结束程序`
	sigaction(SIGPIPE, &sa, 0);
	return 0;
}

static const char *load_config = "\
	local config_name = ...\
	local f = assert(io.open(config_name))\
	local code = assert(f:read \'*a\')\
	local function getenv(name) return assert(os.getenv(name), \'os.getenv() failed: \' .. name) end\
	code = string.gsub(code, \'%$([%w_%d]+)\', getenv)\
	f:close()\
	local result = {}\
	assert(load(code,\'=(load)\',\'t\',result))()\
	return result\
";

int main(int argc, char *argv[]) 
{
	const char *config_file = NULL;
	if(argc > 1) 
	{
		config_file = argv[1];
	} 
	else 
	{
		fprintf(stderr, "Need a config file. Please read skynet wiki : https://github.com/cloudwu/skynet/wiki/Config\n"
			"usage: skynet configfilename\n");
		return 1;
	}

	luaS_initshr();
	skynet_globalinit();
	skynet_env_init();

	sigign();

	struct skynet_config config;

	struct lua_State *L = luaL_newstate();
	luaL_openlibs(L);	// link lua lib

	int err = luaL_loadstring(L, load_config);	//载入lua代码
	assert(err == LUA_OK);
	lua_pushstring(L, config_file);

	err = lua_pcall(L, 1, 1, 0);
	if(err) 
	{
		fprintf(stderr, "%s\n", lua_tostring(L, -1));
		lua_close(L);
		return 1;
	}

	// 初始化 lua 环境
	_init_env(L);

	// 加载配置项
	config.thread = optint("thread", 8);
	config.module_path = optstring("cpath", "./cservice/?.so");
	config.harbor = optint("harbor", 1);
	config.bootstrap = optstring("bootstrap","snlua bootstrap");
	config.daemon = optstring("daemon", NULL);
	config.logger = optstring("logger", NULL);
	config.logservice = optstring("logservice", "logger");
	config.profile = optboolean("profile", 1);

	lua_close(L);

	skynet_start(&config);
	skynet_globalexit();
	luaS_exitshr();

	return 0;
}
