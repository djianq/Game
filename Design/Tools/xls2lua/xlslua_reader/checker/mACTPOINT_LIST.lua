local ALLOW_ACTPOINT = {
	ST = "St",
	OP = "Op",
	HP = "Hp",
	CH = "Ch",  -- 空中计数点
	SH = "Sh",  -- 影子使用点
	AP = "Ap",  -- 佣兵怒气
	SP = "Sp",	-- 技能使用点
}
local ALLOW_NAMES = ""
for K, _ in pairs(ALLOW_ACTPOINT) do
	ALLOW_NAMES = ALLOW_NAMES ..K..","
end
return function(Data)	
	local RetTbl = {}
	local PointList = Split(Data, ",")
	for _, Info in ipairs(PointList) do
		local T = Split(Info, ":")
		assert(#T==2,"行动点格式错误，必须为Key:Value形式"..tostring(Info))
		local Attr = ALLOW_ACTPOINT[T[1]]
		assert(Attr,"允许的行动点为："..ALLOW_NAMES)
		T[1] = Attr
		T[2] = tonumber(T[2])
		table.insert(RetTbl, T)
	end
	return #RetTbl > 0 and RetTbl or nil
end