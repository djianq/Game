local Cfg = GetFileConfig("client/setting/res_cfg.lua").ButtonResConfig
return function (Data)
	assert(Cfg[Data], "在《资源配置表.xls》中找不到【" .. Data .. "】")
	return Data
end