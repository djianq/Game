return function (Data)
	local TmpTable = {}

	local ArrayString, ErrMsg = Split(tostring(Data), ";")
	if not ArrayString then
		return nil, ErrMsg
	end

	for i,TmpData in pairs(ArrayString) do
		local TableString, ErrMsg = Split(tostring(TmpData), "|")
		if not TableString then
			return nil, ErrMsg
		end

		assert(#TableString==2,"参数个数错误,应为数字|数字")

		table.insert(TmpTable,{tonumber(TableString[1]),tonumber(TableString[2])})
	end



	return TmpTable
end