
local ShowType = dofile("server/setting/item/showtype.lua")

return function(Data)
	local RetTbl = {}
	local ShowTypeList = Split(Data, ",")
	for Idx, Value in pairs(ShowTypeList) do
		assert(ShowType[Value], "没有类型为"..Value.."的相关物品配置")
		table.insert(RetTbl, Value)
	end
	return RetTbl
end
