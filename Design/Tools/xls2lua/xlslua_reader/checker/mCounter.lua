local HeroAttribute = GetFileConfig(OUTPUTBASE.."server/setting/yongbing_cfg.lua")	
return function (Data)
	local MyData = Split(Data)
	assert(#MyData%2 == 0,"不符合hero_effect的数据结构")
	local RtTbl = {}
	for Idx,Value in pairs(MyData) do
		if Idx%2 == 1 then
			local VarEnName = HeroAttribute.Name2Atr[Value]
			assert(VarEnName and HeroAttribute.AttributeCounter[VarEnName],"找不到对应"..Value.."的变量名")
			table.insert(RtTbl,{VarEnName,tonumber(MyData[Idx+1])})
		end
	end
	return RtTbl
end
