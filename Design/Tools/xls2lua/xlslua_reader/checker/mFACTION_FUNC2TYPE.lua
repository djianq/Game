
return function (Data)
	local Map = {
		["试炼"] = 1,
		["街霸"] = 2,
		["探索"] = 3,
		["公会副本"] = 4 ,
		["极限挑战"] = 5,
		["周末降临"] = 6,
		["关卡"] = 7,
		
	}
	local DataTbl = Split(Data, ",")
	local Tbl = {}
	for _, Str in pairs(DataTbl) do 
		assert(Map[Str], "没有这个功能" .. Str)
		Tbl[Map[Str]] = true
	end
	return Tbl
end