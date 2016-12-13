local gateserver = require "snax.gateserver"
local netpack = require "netpack"
local crypt = require "crypt"
local skynet = require "skynet"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local filter = require "filter"

local b64encode = crypt.base64encode
local b64decode = crypt.base64decode

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

local host
local gate
local watchdog
local handler = {}
local REQUEST = {}
local CMD = {}

local user_online = {}
local server_list = {}
local account_in = {}

local function send_package(fd, pack)
	local package = string.pack(">s2", pack)
	gateserver.send(fd, package)
end

function REQUEST:login_account()
	local collection = "account"
	local account = crypt.base64decode(self.account)
	local passwd = crypt.base64decode(self.password)

	local amount, _ = skynet.call("MONGODB", "lua", "find", collection, {account = account, password = passwd})
	local desc
	if amount < 1 then
		desc = "不存在这个用户。"
		return {result = 0, desc = desc}
	else
		local last = user_online[account]
		if last then
			skynet.call(gate, "lua", "override", account)
		end
		if user_online[account] then
			desc = string.format("用户%s已经在线。", account)
			error(desc)
			return {result = 0, desc = desc}
		end

		account_in[self.fd] = account
		desc = "用户登录成功！"

		local account, ret = skynet.call("MONGODB", "lua", "find", "user", {account = account})

		local userList = {}
		for _, u in pairs(ret or {}) do
			table.insert(userList, {uid = u.uid, name = u.name})
		end
		send_package(self.fd, send_request("user_list", {amount = #userList, user = userList}))

		return {result = 1, desc = desc}
	end
end

function REQUEST:add_account()
	local collection = "account"
	local account = crypt.base64decode(self.account)
	local passwd = crypt.base64decode(self.password)

	local amount, ret = skynet.call("MONGODB", "lua", "find", collection, {account = account})
	if amount > 0 then
		return {result = 0, account = self.account, password = self.password, desc = "注册用户失败"}
	else
		ret = skynet.call("MONGODB", "lua", "insert", collection, {account = account, password = passwd})
		if ret < 1 then 
			return {result = 0, account = self.account, password = self.password, desc = "注册用户失败"}
		else 
			return {result = 1, account = self.account, password = self.password, desc = "注册用户成功"}
		end
	end
end

function REQUEST:add_user()
	if not account_in[self.fd] then
		return {result = 0, name = self.name, desc = "账号未登录", uid = 0}
	end

	local ok, s = ValidGameMsg(self.name, 2, 10, true)
	if not ok then
		return {result = 0, name = self.name, desc = s, uid = 0}
	end

	local collection = "idmng"

	local amount, ret = skynet.call("MONGODB", "lua", "find", collection, {keyname = "userid"})
	local uid
	if not amount or amount <= 0 then
		uid = 1
	else
		local CurUid = ret[1].value
		uid = CurUid + 1
	end

	if not amount or amount <= 0 then
		ret = skynet.call("MONGODB", "lua", "insert", collection, {keyname = "userid", value = uid})
		if ret < 1 then return {result = 0, name = self.name, desc = "生成UID失败", uid = 0} end

	else
		skynet.call("MONGODB", "lua", "update", collection, {keyname = "userid"}, {value = uid, keyname = "userid"})
	end

	amount, ret = skynet.call("MONGODB", "lua", "find", "user", {name = self.name})
	if amount and amount > 0 then return {result = 0, name = self.name, desc = "角色创建失败，名字已经存在", uid = 0} end

	local player = {}
	player.uid = uid
	player.createtime = os.time()
	player.name = self.name
	player.account = account_in[self.fd]

	ret = skynet.call("MONGODB", "lua", "insert", "user", player)
	if ret < 1 then 
		return {result = 0, name = self.name, desc = "角色创建失败", uid = 0}
	else 
		return {result = 1, name = self.name, desc = "角色创建成功", uid = uid}
	end
end

function REQUEST:login_user()
	if not account_in[self.fd] then
		return {result = 0, desc = "账号未登录", uid = self.uid, subid = 0}
	end

	local uid = self.uid
	local collection = "user"
	local amount, ret = skynet.call("MONGODB", "lua", "find", collection, {uid = uid})
	if not amount or amount <= 0 then
		return {result = 0, desc = "角色不存在", uid = self.uid, subid = 0}
	end

	local account = account_in[self.fd]
	assert(account)
	user_online[account] = {}
	account_in[self.fd] = nil

	local subid = skynet.call(gate, "lua", "login", uid, account)
	user_online[account].subid = subid

	return {result = 1, desc = "角色登录成功", uid = self.uid, subid = subid, port = 1920}
end

local function request(name, args)
	local f = assert(REQUEST[name])
	return f(args)
end

function handler.message(fd, msg, sz)
	local t, name, args, response = host:dispatch(msg, sz)
	if t == "REQUEST" then
		args["fd"] = fd
		local ok, result = pcall(request, name, args)
		if ok then
			send_package(fd, send_request(name, result))
		end
	else
		assert(type == "RESPONSE")
		error "This proto doesn't support request client"
	end
end

function handler.connect(fd, addr)
	gateserver.openclient(fd)
end

function handler.open(source, conf)
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))

	handler.conf = conf
end

function CMD.register(source, address, watchdog)
	gate = address
	watchdog = watchdog
end

function CMD.logout(source, account)
	local u = user_online[account]
	if u then
		print(string.format("%s is logout", account))
		user_online[account] = nil
	end
end

function handler.command(cmd, source, ...)
	local f = assert(CMD[cmd])
	return f(source, ...)
end

gateserver.start(handler)
