
return function (Data)
	local Table = {} 
	local TmpItem = Split(Data, ",")
	for i,Data in ipairs(TmpItem) do
		local Item = Split(Data, "|")
		assert(#Item == 2,"参数错误,应该为[物品id|概率]")
		table.insert(Table, {ItemId = tonumber(Item[1]),Random = tonumber(Item[2])} )
	end

	return Table
end