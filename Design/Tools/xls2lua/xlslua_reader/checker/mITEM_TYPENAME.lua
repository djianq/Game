local ItemName2Type=  GetFileConfig(OUTPUTBASE.."server/setting/item/name2type.lua")

return function (Data)
	local Tbl = Split(Data, ",")
	local Ret = {}
	for _, Name in ipairs(Tbl) do
		assert(ItemName2Type[Name],Name.."没有该物品类型，请确认相关物品表")
		table.insert(Ret, ItemName2Type[Name])
	end
	return Ret
end