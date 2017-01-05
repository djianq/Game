return function (Data)
	Data = MultiFilter(Data)
	local TableString, ErrMsg = SafeSplit(tostring(Data))
	if not TableString then
		return nil, ErrMsg
	end
	
	return TableString
end
