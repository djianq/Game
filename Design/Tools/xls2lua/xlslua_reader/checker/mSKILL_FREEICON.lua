return function (Data)
	local ICons = {}
	local TmpICon = Split(Data, ",")
	for _, v in pairs(TmpICon) do
		table.insert(ICons, v)		
	end
	return ICons
end