local skynet = require "skynet"
local mongo = require "mongo"
local bson = require "bson"

require "skynet.manager"	-- import skynet.register

local host, db_name = ...
local CMD = {}

function CMD.insert(cname, args)
	local db = mongo.client({host = host})
	local ret = db[db_name][cname]:safe_insert(args);
	assert(ret and ret.n == 1)
	return ret.n
end

function CMD.find(cname, args)
	local db = mongo.client({host = host})
	local ret = db[db_name][cname]:find(args)
	local tb = {}

	local count = ret:count()
	if ret:hasNext() then
		ret = ret:next()
		table.insert(tb, ret)
	end
	
	return count, tb
end

function CMD.update(cname, selector, update)
	local db = mongo.client({host = host})
	db[db_name][cname]:update(selector, update)
end

skynet.start(function()
	local db = mongo.client({host = host})
	assert(db)
	skynet.dispatch("lua", function(_, _, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)

	skynet.register "MONGODB"
end)
