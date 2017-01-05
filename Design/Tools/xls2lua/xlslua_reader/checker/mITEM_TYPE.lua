return function (Data)
	assert(ItemName2Type[Data], Data.."没有该物品类型，请确认相关物品表")
	Data = ItemName2Type[Data]
	return Data
end