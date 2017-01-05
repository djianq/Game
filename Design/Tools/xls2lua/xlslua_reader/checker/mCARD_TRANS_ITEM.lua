local ItemName2Type=  GetFileConfig(OUTPUTBASE.."server/setting/item/Type2OutFile.lua")

return function (Data)
	local Tbl = Split(Data,",")
	local ItemType = tonumber(Tbl[1])
	local Item = ItemName2Type[ItemType]
	assert(Item,"ItemType =【"..ItemType.."】的物品不存在")
	Tbl[1] = tonumber(Tbl[1])
	assert(Tbl[2], "没有填写数量")
	Tbl[2] = tonumber(Tbl[2])
	return Tbl
end