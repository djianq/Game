return function (Data)
	local TmpTable = {}
	local TableString, ErrMsg = Split(tostring(Data), "|")
	if not TableString then
		return nil, ErrMsg
	end

	assert(#TableString==2,"参数个数错误,应为数字|数字")

	TmpTable = {tonumber(TableString[1]),tonumber(TableString[2])}

	return TmpTable
end