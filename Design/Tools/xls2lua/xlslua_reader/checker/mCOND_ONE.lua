return function (Data)
	local Cond = {}
	local Tmp = Split(Data, "|")
	for _, Args in pairs(Tmp) do
		table.insert(Cond, Args)
	end
	return Cond
end