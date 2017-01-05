
local CONST_CFG = GetFileConfig(OUTPUTBASE.."server/setting/common_const.lua")

return function(Data)
	local JOB_NAME2ID = CONST_CFG.JOB_NAME2ID

	local Table = {}
	local TmpData = Split(Data, "|")	
	for _, JobName in pairs(TmpData)do
		assert(JOB_NAME2ID[JobName],"类型【"..JobName.."】不存在")
		table.insert(Table,JOB_NAME2ID[JobName])
	end

	return Table
end
