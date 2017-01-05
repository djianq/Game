local HeroAttribute = GetFileConfig(OUTPUTBASE.."server/setting/yongbing_cfg.lua")	
return function (Data)
	local AttributeList = Split(Data, ";")
	local RtTbl = {}
	for i,Attribute in pairs(AttributeList) do
		if Attribute ~= "" then	
			local Value = Split(Attribute, ",")		
			assert(#Value == 3,"["..Attribute.."]参数有误,应为属性名,初始值,成长值")
			assert(HeroAttribute.Name2Atr[Value[1]],"找不到对应"..Value[1].."的属性算子")
			table.insert(RtTbl,{HeroAttribute.Name2Atr[Value[1]],tonumber(Value[2]),tonumber(Value[3])})
			end
	end
	return RtTbl
end
