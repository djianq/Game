local MercenaryCfg = GetFileConfig(OUTPUTBASE .. "server/setting/yongbing_cfg.lua").ConstInfo["佣兵表"]
return function (Data)
	local TableString, ErrMsg = Split(tostring(Data), "|")
	if not TableString then
		return nil, ErrMsg
	end

	for i, Str in ipairs(TableString) do
		local IntValue = tonumber(Str)
		-- 非数字错误
		if not IntValue then 
			return nil, "错误:佣兵ID填的不是int型"
		end

		local Info = MercenaryCfg[IntValue]
		assert(Info, "没有该佣兵！！")

		TableString[i] = IntValue
	end

	return TableString
end
