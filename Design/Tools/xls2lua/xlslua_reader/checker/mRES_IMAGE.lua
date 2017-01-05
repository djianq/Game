local ImageCfg = GetFileConfig("client/setting/res_cfg.lua").ImageResConfig
return function (Data)
	assert(ImageCfg[Data],"image resourc not found ["..Data.."]")
	return Data
end
