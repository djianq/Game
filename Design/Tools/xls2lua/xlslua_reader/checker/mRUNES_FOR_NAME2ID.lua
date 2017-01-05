local Name2Id=  GetFileConfig("server/setting/item/runes_formula.lua").Name2Id

return function (Data)
	local Tbl = Split(Data, ",")
	for i, data in ipairs(Tbl) do
		assert(Name2Id[data],data.."没有该物品类型，请确认相关物品表")
		Tbl[i] = Name2Id[data]
	end
	return Tbl
end