local skynet = require "skynet"
local gateserver = require "snax.gateserver"
local netpack = require "netpack"
local crypt = require "crypt"

local b64encode = crypt.base64encode
local b64decode = crypt.base64decode

local loginservice = tonumber(...)

local watchdog
local connection = {}	-- fd -> connection : { fd , client, agent , ip, mode }
local forwarding = {}	-- agent -> connection
local users = {}
local account_map = {}
local userfd_map = {}
local internal_id = 0
local servername

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}


local handler = {}

function handler.open(source, conf)
	watchdog = conf.watchdog or source
	skynet.call(loginservice, "lua", "register", skynet.self(), watchdog)
end

function handler.message(fd, msg, sz)
	-- recv a package, forward it
	local c = connection[fd]
	local agent = c.agent
	if agent and userfd_map[fd] then
		skynet.redirect(agent, c.client, "client", 0, msg, sz)
	else
		-- skynet.send(watchdog, "lua", "socket", "data", fd, netpack.tostring(msg, sz))
		skynet.send(watchdog, "lua", "socket", "data", fd, msg, sz)
	end
end

function handler.connect(fd, addr)
	local c = 
	{
		fd = fd,
		ip = addr,
	}
	connection[fd] = c
	skynet.send(watchdog, "lua", "socket", "open", fd, addr)
end

local function unforward(c)
	if c.agent then
		forwarding[c.agent] = nil
		c.agent = nil
		c.client = nil
	end
end

local function clear_all(fd)
	local u = userfd_map[fd]
	if u then
		account_map[u.account] = nil
		users[u.uid] = nil
		userfd_map[fd] = nil
	end
end

local function close_fd(fd)
	local c = connection[fd]

	local u = userfd_map[fd]
	if u then
		users[u.uid] = nil
		account_map[u.account] = nil
		userfd_map[fd] = nil
		skynet.call(loginservice, "lua", "logout", u.account)
	end

	if c then
		unforward(c)
		connection[fd] = nil
	end

	clear_all(fd)
end

function handler.disconnect(fd)
	close_fd(fd)
	skynet.send(watchdog, "lua", "socket", "close", fd)
end

function handler.error(fd, msg)
	close_fd(fd)
	skynet.send(watchdog, "lua", "socket", "error", fd, msg)
end

function handler.warning(fd, size)
	skynet.send(watchdog, "lua", "socket", "warning", fd, size)
end

local CMD = {}

function CMD.forward(source, fd, client, address)
	local c = assert(connection[fd])
	unforward(c)
	c.client = client or 0
	c.agent = address or source
	forwarding[c.agent] = c
	gateserver.openclient(fd)
end

function CMD.accept(source, fd)
	local c = assert(connection[fd])
	unforward(c)
	gateserver.openclient(fd)
end

function CMD.kick(source, fd)
	gateserver.closeclient(fd)
end

function CMD.override(source, account)
	local u = account_map[account]
	if u then
		local fd = u.fd
		
		skynet.call(watchdog, "lua", "close", fd)

		local c = connection[fd]
		if c then
			unforward(c)
			connection[fd] = nil
		end

		account_map[account] = nil
		users[u.uid] = nil
		userfd_map[fd] = nil
	end

	skynet.call(loginservice, "lua", "logout", account)
end

function CMD.login(source, uid, account)
	if users[uid] then
		error(string.format("%s is already login", uid))
	end

	internal_id = internal_id + 1
	local id = internal_id	-- don't use internal_id directly
	
	local u = 
	{
		account = account,
		uid = uid,
		subid = id,
	}

	users[uid] = u
	account_map[account] = u

	-- you should return unique subid

	return id, account
end

function CMD.auth(source, subid, account)
	if account_map[account] and subid == account_map[account].subid then 
		return true
	else 
		return false
	end
end

function CMD.enter(source, uid, fd)
	local u = users[uid]
	if not u then return false, "用户未通过验证" end
	if userfd_map[fd] then return false, "用户已经存在" end

	u.fd = fd
	userfd_map[fd] = u
	return true, "登录成功"
end

function handler.command(cmd, source, ...)
	local f = assert(CMD[cmd])
	return f(source, ...)
end

gateserver.start(handler)
