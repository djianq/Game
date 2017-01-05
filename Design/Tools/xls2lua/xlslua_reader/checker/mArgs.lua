return function (Data)
	local Table = {} 
	local Tmp1 = Split(Data, ",")
	for _, Tmp2 in ipairs(Tmp1) do
		local Tmp3 = Split(Tmp2, "|")
		table.insert(Table, Tmp3)
	end
	return Table
end