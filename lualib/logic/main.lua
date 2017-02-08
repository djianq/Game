local skynet = require "skynet"
local sprotoloader = require "sprotoloader"
local snax = require "snax"

local max_client = 64

skynet.start(function()
	skynet.error("Server start")
	skynet.uniqueservice("protoloader")
	skynet.uniqueservice("configloader")
	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("mongodb_mgr", "127.0.0.1", "skynet")
	local loginserver = skynet.newservice("logind")
	skynet.call(loginserver, "lua", "open", 
	{
		host = "0.0.0.0",
		port = 1922,
		multilogin = false,	-- disallow multilogin
		name = "login_master",
	})

	local watchdog = skynet.newservice("watchdog", loginserver)
	skynet.call(watchdog, "lua", "start", 
	{
		port = 1920,
		maxclient = max_client,
		nodelay = true,
	})
	skynet.error("Watchdog listen on", 1920)
	skynet.exit()
end)
