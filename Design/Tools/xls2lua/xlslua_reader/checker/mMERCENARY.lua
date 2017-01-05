local MercenaryCfg = GetFileConfig(OUTPUTBASE .. "server/setting/yongbing_cfg.lua").ConstInfo["佣兵表"]
return function (Data)
	local Info = MercenaryCfg[Data]
	assert(Info, "没有该佣兵！！")
	return Data
end
