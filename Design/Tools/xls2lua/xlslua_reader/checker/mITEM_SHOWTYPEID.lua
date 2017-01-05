local Name2Id =  GetFileConfig(OUTPUTBASE .. "server/setting/item/itemtype2class.lua").Name2Id

return function (Data)
	assert(Name2Id[Data], Data.."没有该类型，请确认相关物品表")
	local Id = Name2Id[Data]
	return Id
end