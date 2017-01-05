local ShapeInfo = GetFileConfig(OUTPUTBASE.."server/setting/shape_info.lua")
local AttachTbl = ShapeInfo.Name2AttachId
local ShapeConf = ShapeInfo.ShapeConfig
return function(Data)
	local AttachId = AttachTbl[Data]
	assert(AttachId, "配置部位或挂接点[" .. Data .. "]不存在")
	return AttachId
end
