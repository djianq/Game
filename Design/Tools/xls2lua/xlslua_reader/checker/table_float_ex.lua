return function (Data)
	local TableString= Split(Data,"|")
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