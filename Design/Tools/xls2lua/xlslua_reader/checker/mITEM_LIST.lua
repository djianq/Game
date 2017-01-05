local ItemIds = GetFileConfig(OUTPUTBASE .. "server/setting/item/Type2OutFile.lua")

return function (Data)
	table.print(ItemId)
	local ItemIdList, ErrMsg = SafeSplit(tostring(Data))
	if not ItemIdList then return nil, ErrMsg end
	local ItemTypeIds = {}
	for _, ItemId in ipairs(ItemIdList) do
		assert(ItemIds[tonumber(ItemId)], ItemId .. "没有该物品类型，请确认相关物品表")
		table.insert(ItemTypeIds, tonumber(ItemId))
	end
	return ItemTypeIds 
end
