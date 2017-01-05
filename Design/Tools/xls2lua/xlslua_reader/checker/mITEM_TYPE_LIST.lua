local ItemName2Type=  GetFileConfig("server/setting/item/name2type.lua")

return function (Data)
	local Tbl = Split(Data, ",")
	for i, data in ipairs(Tbl) do
		assert(ItemName2Type[data],data.."没有该物品类型，请确认相关物品表")
		Tbl[i] = ItemName2Type[data]
	end
	return Tbl
end