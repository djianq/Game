return function (Data)
	local TmpTable = {}

	local GroupString, ErrMsg = Split(tostring(Data), "-")
	if not GroupString then
		return nil, ErrMsg
	end

	for k,TmpInfo in pairs(GroupString) do
		local ArrayString, ErrMsg = Split(tostring(TmpInfo), ",")
		if not ArrayString then
			return nil, ErrMsg
		end

		local GroupTable = {}
		for i,TmpData in pairs(ArrayString) do
			local TableString, ErrMsg = Split(tostring(TmpData), "|")
			if not TableString then
				return nil, ErrMsg
			end

			assert(#TableString==2,"参数个数错误,应为数字|数字")

			table.insert(GroupTable,{tonumber(TableString[1]),tonumber(TableString[2])})
		end
		if #GroupTable > 0 then
			table.insert(TmpTable,GroupTable)
		end
	end

	return TmpTable
end