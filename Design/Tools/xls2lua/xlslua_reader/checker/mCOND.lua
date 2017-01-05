return function (Data)
	local Conds = {}
	local TmpCond = Split(Data, ",")
	for _, v in pairs(TmpCond) do
		local Tmp = Split(v, "|")
		local Cond = {}
		for _, Args in pairs(Tmp) do
			table.insert(Cond, Args)
		end
		table.insert(Conds, Cond)
	end
	return Conds
end