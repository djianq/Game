return function (Data)
	local TableString, ErrMsg = Split(tostring(Data), "|")
	if not TableString then
		return nil, ErrMsg
	end
	
	for i, Str in ipairs(TableString) do
		local IntValue = tonumber(Str)
		
		-- 非数字错误
		if not IntValue then 
			return nil, "错误:x_split_int填的不是int型"
		end
		
		TableString[i] = IntValue
	end
	
	return TableString
end