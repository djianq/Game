return function (Data)
	local TableString, ErrMsg = Split(tostring(Data), ";")
	if not TableString then
		return nil, ErrMsg
	end

	for Key, Str in pairs(TableString) do
		TableString[Key] = CheckMultiLanguage(Str) 
	end
	
	return TableString
end
