local HeroAttribute = GetFileConfig(OUTPUTBASE.."server/setting/hero_attribute.lua")	


return function (Data)
	local Table = {} 
	local TmpData = Split(Data, ":")

	assert(#TmpData == 2,Data..",参数不对")
	local Index = tonumber(TmpData[1])


	assert(Index >=0 and Index<=9,Data..",第一参数有误,因为0-9")

	if Index == 0 then
		Table.AttrName = "AddAllBSLv"
	else
		Table.AttrName = "AddBSLv"..Index
	end

	Table.Type = Index
	Table.RangeInfo = {}
	local TmpInfo = Split(TmpData[2], ",")
	for i,v in ipairs(TmpInfo) do
		local TmpValue = Split(v, "|")
		assert(#TmpValue == 3,Data..",参数不对")		

		table.insert(Table.RangeInfo,{
			MinLevel = tonumber(TmpValue[1]),
			MaxLevel = tonumber(TmpValue[2]),
			AddLevel = tonumber(TmpValue[3]),
			})
	end

	return Table
end