local Name2Id=  GetFileConfig("server/setting/wakeup_cfg.lua")

return function (Data)
	assert(Name2Id[Data],Data.."没有该觉醒模板")
	
	return Data
end