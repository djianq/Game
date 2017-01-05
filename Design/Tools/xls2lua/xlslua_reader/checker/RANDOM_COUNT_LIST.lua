
return function (Data)
	local Table = {} 
	local TmpCount = Split(Data, ",")
	for i,Data in ipairs(TmpCount) do
		local Count = Split(Data, "|")
		assert(#Count == 2,"参数错误,应该为[数量下限|数量上限]")
		table.insert(Table, {MinCount = tonumber(Count[1]),MaxCount = tonumber(Count[2])} )
	end

	return Table
end