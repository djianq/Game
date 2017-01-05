return function (Data)
	if not Data then return end
	local Rewards = {}
	local TmpItems = Split(Data, ",")
	for _, v in pairs(TmpItems) do
		local Tmp = Split(v, "|")
		local Item = {}
		Item.Id = tonumber(Tmp[1])
		Item.Count = tonumber(Tmp[2])
		
		table.insert(Rewards, Item)
	end
	return Rewards
end
