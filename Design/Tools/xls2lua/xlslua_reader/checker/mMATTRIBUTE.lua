return function (Data)
	local AttributeList = Split(Data, "|")
	local RtTbl = {}
	for _, Attribute in pairs(AttributeList) do
		if Attribute ~= "" then	
			local Value = Split(Attribute, ",")
			assert(#Value == 2, "参数有误, 应为属性名, 增加值")
			table.insert(RtTbl, {Value[1], tonumber(Value[2])})
			end
	end
	return RtTbl
end
