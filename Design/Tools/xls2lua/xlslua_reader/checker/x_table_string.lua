return function (Data)
	local TableString, ErrMsg = Split(tostring(Data), "|")
	if not TableString then
		return nil, ErrMsg
	end
	return TableString
end