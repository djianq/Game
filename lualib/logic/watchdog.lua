local skynet = require "skynet"
local netpack = require "netpack"
local sprotoloader = require "sprotoloader"
local socket = require "socket"

local loginservice = tonumber(...)

local CMD = {}
local SOCKET = {}
local agent = {}
local gate
local host
local send_request

local function send_package(fd, pack)
	local package = string.pack(">s2", pack)
	socket.write(fd, package)
end

function SOCKET.open(fd, addr)
	skynet.error("New client from : " .. addr)
	agent[fd] = skynet.newservice("agent")
	skynet.call(agent[fd], "lua", "start", {gate = gate, client = fd, watchdog = skynet.self()})
end

local function close_agent(fd)
	local a = agent[fd]
	agent[fd] = nil
	if a then
		skynet.call(gate, "lua", "kick", fd)
		-- disconnect never return
		skynet.send(a, "lua", "disconnect")
	end
end

function SOCKET.close(fd)
	print("socket close",fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	print("socket error", fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	print("socket warning", fd, size)
end

function SOCKET.data(fd, msg, sz)
	local t, pname, args, response = host:dispatch(msg, sz)
	assert(t == "REQUEST")

	if pname == "login_game" and args then
		local uid = args["uid"]
		local account = args["account"]
		local subid = args["subid"]

		local ret = skynet.call(gate, "lua", "auth", subid, account)
		if not ret then 
			send_package(fd, send_request(pname, {result = 0, uid = uid or 0, desc = "用户未通过验证"}))
		else
			local desc
			ret, desc = skynet.call(gate, "lua", "enter", uid or 0, fd)
			send_package(fd, send_request(pname, {result = (ret and 1) or 0, uid = uid or 0, desc = desc}))
		end
	end
end

function CMD.start(conf)
	skynet.call(gate, "lua", "open" , conf)

	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
end

function CMD.close(fd)
	close_agent(fd)
end

function CMD.agent(fd, agent)
	agent[fd] = agent
	skynet.call(agent[fd], "lua", "start", {gate = gate, client = fd, watchdog = skynet.self()})
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

	gate = skynet.newservice("gate", loginservice)
end)
