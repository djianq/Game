-- module proto as examples/proto.lua
package.path = "./examples/?.lua;" .. package.path

local skynet = require "skynet"
local sconfigloader = require "sconfigloader"

skynet.start(function()
	local SETTING = Import("lualib/logic/setting.lua")
	for sname, _ in pairs(SETTING.FileCfg or {}) do
		if SETTING[sname] then
			sconfigloader.save(sname, SETTING[sname])
		end
	end
end)
