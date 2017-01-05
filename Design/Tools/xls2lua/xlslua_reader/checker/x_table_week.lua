return function (Data)
	local TableString, ErrMsg = Split(tostring(Data), "|")
	if not TableString then
		return nil, ErrMsg
	end

	local week = {
		[0] = "Sunday",
		[1] = "Monday",
		[2] = "Tuesday",
		[3] = "Wednesday",
		[4] = "Thursday",
		[5] = "Friday",
		[6] = "Saturday",
	}
	
	local tbl = {}
	for i, Str in ipairs(TableString) do
		local IntValue = tonumber(Str)
		-- 非数字错误
		if not IntValue then 
			return nil, "错误:x_split_int填的不是int型"
		end

		if IntValue > 6 or IntValue < 0 then return nil, "错误:x_split_int填的不是0-6" end

		tbl[week[IntValue]] = true
	end
	
	return tbl
end