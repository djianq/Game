
local CONST_CFG = GetFileConfig(OUTPUTBASE.."server/setting/common_const.lua")

return function(Data)
	local JOB_NAME2ID = CONST_CFG.JOB_NAME2ID

	assert(JOB_NAME2ID[Data],"类型【"..Data.."】不存在")

	return JOB_NAME2ID[Data]
end
