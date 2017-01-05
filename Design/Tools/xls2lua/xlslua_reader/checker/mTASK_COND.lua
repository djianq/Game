return function (Data)
	local Conds = {}
	local TmpCond = Split(Data, ",")
	for _, v in pairs(TmpCond) do
		local Tmp = Split(v, "|")
		local Cond = {}
		Cond.Type = Tmp[1]
		if Tmp[2] and tonumber(Tmp[2]) ~= 0 then Cond.Id = tonumber(Tmp[2]) end
		Cond.Count = Tmp[3] and tonumber(Tmp[3]) or 1

		if Tmp[1] == "通关" then
			if Tmp[4] and Tmp[4] ~= "0" then Cond.StageType = tonumber(Tmp[4]) end
		elseif Tmp[1] == "强化" or Tmp[1] == "穿戴" or Tmp[1] == "打造" or Tmp[1] == "进阶" then
			if Tmp[4] and Tmp[4] ~= "0" then Cond.Category = Tmp[4] end
		elseif Tmp[1] == "血技升级" or Tmp[1] == "精炼" then
			if Tmp[4] and Tmp[4] ~= "0" then Cond.Level = tonumber(Tmp[4]) end
		end
		table.insert(Conds, Cond)
	end
	return Conds
end