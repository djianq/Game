local ShapeIdCfg = GetFileConfig(OUTPUTBASE.."server/setting/shape_info.lua").Name2ShapeId	
return function (Data)
	local ShapeId = ShapeIdCfg[Data]
	assert(ShapeId,"找不到对应"..Data.."的ShapeId,请查看【换装配置表】")
	return ShapeId
end
