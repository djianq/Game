package.path = "./examples/?.lua;" .. package.path

local skynet = require "skynet"
local sconfigloader = require "sconfigloader"
local classset = require "classset"

skynet.start(function()
	for sname, _ in pairs(classset.Classes or {}) do
		if classset[sname] then
			sconfigloader.save(sname, classset[sname])
		end
	end
end)
