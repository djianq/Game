local ShapeIdCfg = GetFileConfig(OUTPUTBASE.."server/setting/shape_info.lua").Name2ShapeId	
return function (Data)
	local DataTmp = Split(Data,",")
	local Tmp = {}
	for key, Data1 in pairs(DataTmp) do 
		local ShapeId = ShapeIdCfg[Data1]
		assert(ShapeId,"找不到对应"..Data1.."的ShapeId,请查看【换装配置表】")
		Tmp[key] = ShapeId
	end
	return Tmp
end
