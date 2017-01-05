return function (Data)
	local TableString, ErrMsg = SafeSplit(tostring(Data))
	if not TableString then
		return nil, ErrMsg
	end
	
	local TableInt = {}
	for _, Str in ipairs(TableString) do
		local IntValue = tonumber(Str)
		
		-- 非数字错误
		if not IntValue then 
			return nil
		end

		table.insert(TableInt, IntValue)
	end
	
	return TableInt
end