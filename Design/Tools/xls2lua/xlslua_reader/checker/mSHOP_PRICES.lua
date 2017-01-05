local TypeCfg = 
{
	["金币"] = 0,
	["元宝"] = 1,
}

return function(Data)
	table.print(Data)
	local Types = Split(Data)
	local RetTypes = {}
	table.print(Data)
	for _, Type in ipairs(Types) do
		if not TypeCfg[Type] then
			assert(false, Type .. "没有该物品类型，请确认")
			table.insert(RetTypes, ItemName2Type[Type])
		else
			table.insert(RetTypes, TypeCfg[Type])
		end
	end
	return RetTypes
end
