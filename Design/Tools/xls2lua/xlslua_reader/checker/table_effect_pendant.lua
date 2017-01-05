local AttachConfig = dofile("server/setting/shape_info.lua").AttachConfig
local ShapeIdCfg = dofile("server/setting/shape_info.lua").Name2ShapeId

return function(Data)
	local RetTbl = {}
	local AttachList = Split(Data, ";")
	for _, Value in pairs(AttachList) do
		local Attach = Split(Value, ":")
		assert(#Attach == 2 , "参数个数错误"..Value)	
	--	local AttachCfg = AttachConfig[tonumber(Attach[1])]	
	--	assert(AttachCfg, "找不到"..Attach[1].."对应的挂接点")
		--对Attach[2]进行校验

		RetTbl[Attach[1]] = tonumber(Attach[2])
	end
	return RetTbl
end
