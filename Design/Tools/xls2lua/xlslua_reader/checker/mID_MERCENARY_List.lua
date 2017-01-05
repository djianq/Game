local Range = GetFileConfig(OUTPUTBASE.."server/setting/common_const.lua").RANGE_ID.MERCENARY_ID
return function(Data)
	local tbl = Split(Data, "|")
	local ret = {}
	for _, Id in pairs(tbl or {}) do
		assert(Range[1] <= tonumber(Id) and Range[2] >= tonumber(Id), "佣兵ID必须在" .. Range[1] .. "-" .. Range[2] .. "之间")
		table.insert(ret, tonumber(Id))
	end
	
	return ret
end
