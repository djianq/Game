local ImageCfg = GetFileConfig("client/setting/res_cfg.lua").ImageResConfig
return function (Data)
	local TableString, ErrMsg = SafeSplit(tostring(Data))
	if not TableString then return nil, ErrMsg end
	for _, ImageStr in ipairs(TableString) do
		assert(ImageCfg[ImageStr],"image resourc not found ["..ImageStr.."]")
	end
	return TableString
end
