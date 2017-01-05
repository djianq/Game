local CONST_CFG = GetFileConfig(OUTPUTBASE.."server/setting/common_const.lua")

return function (Data)
	local JOB_NAME2ID = CONST_CFG.JOB_NAME2ID

	local Tbl = {}
	local TmpJob = Split(Data, ";")	--分开不同职业
	for _, Tmp1 in pairs(TmpJob)do
		local Set = {}
		local Tmp2 = Split(Tmp1, "-")
		assert(JOB_NAME2ID[Tmp2[1]],"类型【"..Tmp2[1].."】不存在")
		Set.JobId = JOB_NAME2ID[Tmp2[1]]
		Set.Args = {}

		local Tmp3 = Split(Tmp2[2], ",")
		for _, Tmp4 in pairs(Tmp3) do
			local Tmp5 = Split(Tmp4, "|")
			local Ret = {}
			Ret.GroupId = tonumber(Tmp5[1])
			Ret.Weight = tonumber(Tmp5[2])
			table.insert(Set.Args, Ret)
		end
		Tbl[Set.JobId] = Set
	end
	return Tbl
end 

