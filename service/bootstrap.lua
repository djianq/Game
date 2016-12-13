local skynet = require "skynet"
local harbor = require "skynet.harbor"
require "skynet.manager"	-- import skynet.launch, ...
local memory = require "memory"

-- skynet.newservice到skynet.launch的过程
-- skynet.newservice执行，调用skynet.call函数
-- skynet.call函数根据typename为"lua"获取到proto中对应的处理方法和变量
-- 再调用c.send函数，c.send函数调用的是lua-skynet.c中的lsend函数
-- lsend函数发送这条消息到对应的context
-- 在这之前context的回调函数设置成lua-skynet.c中的_cb函数
-- 在_cb函数中回从lua栈中找到LUA_REGISTRYINDEX表中，以_cb地址为key的value
-- 该value的值又是什么？往前留意，在bootstrp.lua文件被loader.lua执行时，会
-- 首先执行skynet.start()，而skynet.start这个函数调用c.callback(skynet.dispatch_message)
-- 这句代码来设置LUA_REGISTRYINDEX表，以_cb地址为key的value，此时value的值正是skynet.dispatch_message这个函数
-- 所以当执行lua-skynet.c中的_cb函数时，就会调用skynet.dispatch_message方法来处理消息，然后
-- skynet.dispatch_message会调用raw_dispatch_message继续处理消息，接着raw_dispatch_message根据判断
-- 会继续执行到 local f = p.dispatch 这句代码上，再运用协程的方式来调用p.dispatch方法
-- 其实这个p.dispatch方法在初始化launcher模块时候已经被赋值，在launcher.lua中会调用skynet.dispatch
-- 这个函数来绑定p.dispatch调用的方法函数，因此，在调用p.dispatch方法时候就要回头launcher.lua的代码。
-- 从代码上可知会调用command中的一个方法，而调用哪个方法取决于命令参数，而这个命令参数
-- 在skynet.call中可知，是"LAUNCH"这个，因此，最后调用的是command.LAUNCH这个方法，这个方法后面就是
-- 新建Lua虚拟机之类的步骤了，之后就是执行相应的xxx.lua文件。


skynet.start(function()
	local sharestring = tonumber(skynet.getenv "sharestring" or 4096)
	memory.ssexpand(sharestring)

	local standalone = skynet.getenv "standalone"

	local launcher = assert(skynet.launch("snlua", "launcher"))	--初始化launcher模块
	skynet.name(".launcher", launcher)

	local harbor_id = tonumber(skynet.getenv "harbor" or 0)
	if harbor_id == 0 then
		assert(standalone ==  nil)
		standalone = true
		skynet.setenv("standalone", "true")

		local ok, slave = pcall(skynet.newservice, "cdummy")
		if not ok then
			skynet.abort()
		end
		skynet.name(".cslave", slave)

	else
		if standalone then
			if not pcall(skynet.newservice, "cmaster") then	----初始化cmaster模块
				skynet.abort()
			end
		end

		local ok, slave = pcall(skynet.newservice, "cslave")	----初始化cslave模块
		if not ok then
			skynet.abort()
		end
		skynet.name(".cslave", slave)
	end

	if standalone then
		local datacenter = skynet.newservice "datacenterd"	----初始化datacenter模块
		skynet.name("DATACENTER", datacenter)
	end
	skynet.newservice "service_mgr"		----初始化service_mgr模块
	pcall(skynet.newservice, skynet.getenv "start" or "main")	----初始化main模块
	skynet.exit()
end)
