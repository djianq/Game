local ShapeIdCfg = GetFileConfig(OUTPUTBASE .. "server/setting/shape_info.lua").Name2ShapeId
return function(Data)
	local RetTbl = {}
	local AttachList = Split(Data, ";")
	for Idx, Value in pairs(AttachList) do
		local AttachName = ShapeIdCfg[Value]
		assert(AttachName, "找不到" .. Value .. "对应的ShapeId")
		table.insert(RetTbl, AttachName)
	end
	return RetTbl
end
