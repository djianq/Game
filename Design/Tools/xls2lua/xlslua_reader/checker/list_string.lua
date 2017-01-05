return function (Data)
	Data = MultiFilter(Data)
	local TableString, ErrMsg = Split(tostring(Data), ";")
	if not TableString then
		return nil, ErrMsg
	end
	
	return TableString
end
