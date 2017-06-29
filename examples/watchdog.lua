local skynet = require "skynet"
local netpack = require "netpack"
local sprotoloader = require "sprotoloader"
local socket = require "socket"
local util = require "util"

local loginservice = tonumber(...)

local CMD = {}
local SOCKET = {}
local gate
local agent = {}
local host
local send_request

local function send_package(fd, pack)
	local package = string.pack(">s2", pack)
	socket.write(fd, package)
end

function SOCKET.open(fd, addr)
	skynet.error("New client from : " .. addr)
	-- agent[fd] = skynet.newservice("agent")
	-- skynet.call(agent[fd], "lua", "start", {gate = gate, client = fd, watchdog = skynet.self()})

	skynet.call(gate, "lua", "register", fd)
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
	local t, name, args, response = host:dispatch(msg, sz)

	if not agent[fd] then
		local subid = args["subid"]
		if not subid then return end
		local c = skynet.call(loginservice, "lua", "agent_get", tostring(subid))
		if not c then return end
		agent[fd] = c
		skynet.call(c, "lua", "start", {gate = gate, client = fd, watchdog = skynet.self()})
	end

	if t == "REQUEST" and args["subid"] then
		if name == "login" then
			local subid = args["subid"]
			local name = args["name"]
			local ret = skynet.call(gate, "lua", "auth", subid, name)
			if not ret then
				if response then
					local ret = response({result = "ERROR"})
					send_package(fd, ret)
				end 
				return 
			end

			if response then
				local ret = response({result = "OK"})
				send_package(fd, ret)
			end
		elseif name == "register" then
			skynet.call(c, "lua", "register", {args["name"], args["password"]})
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
