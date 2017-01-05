local ShapeIdCfg = GetFileConfig(OUTPUTBASE.."client/setting/shape_info.lua").ShapeConfig	
return function (Data)
	local ShapeId = tonumber(Data)
	local ShapeCfg = ShapeIdCfg[tonumber(ShapeId)]
	assert(ShapeCfg,"找不到对应"..Data.."的配置,请查看【换装配置表】")
	return ShapeId
end
