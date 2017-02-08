package.path = "./examples/?.lua;" .. package.path

local skynet = require "skynet"
local sconfigloader = require "sconfigloader"
local setting = require "setting"

skynet.start(function()
	for sname, _ in pairs(setting.FileCfg or {}) do
		if setting[sname] then
			sconfigloader.save(sname, setting[sname])
		end
	end
end)
