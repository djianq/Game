local ShapeIdCfg = GetFileConfig(OUTPUTBASE .. "server/setting/shape_info.lua").ShapeConfig
return function(Data)
	local RetTbl = {}
	local AttachList = Split(Data, "|")
	for Idx, Value in pairs(AttachList) do
		local AttachName = ShapeIdCfg[tonumber(Value)]
		assert(AttachName, "找不到" .. Value .. "对应的ShapeId")
		table.insert(RetTbl, tonumber(Value))
	end
	return RetTbl
end
