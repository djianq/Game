
return function (Data)
	local Table = {} 
	local TmpItem = Split(Data, ";")
	for i,TmpData in ipairs(TmpItem) do
		local Item = Split(TmpData, "|")
		assert(#Item == 2,"参数错误,应该为[物品id|数量]")
		table.insert(Table, {ItemId = tonumber(Item[1]),Count = tonumber(Item[2])} )
	end

	return Table
end