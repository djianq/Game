return function (Data)
	local Tbl = Split(tostring(Data), ";")

	local TableString, ErrMsg = SafeSplit(tostring(Data))
	if not TableString then
		return nil, ErrMsg
	end
	
	local TableInt = {}
	for _, Str in ipairs(Tbl) do
		if Str and Str~="" then
			local SubTbl = Split(tostring(Str), ",")
			table.insert(TableInt, {tonumber(SubTbl[1]), tonumber(SubTbl[2])})
		end
	end
	
	return TableInt
end