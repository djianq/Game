
--local Attrs = GetFileConfig(OUTPUTBASE.."server/setting/hero_attribute.lua").ConstInfo["人物职业"]

return function(Data)
	local RetTbl = {}
	local List = Split(Data, "|")
	for _,Value in ipairs(List) do
		--assert(Attrs[Value], "在人物属性表中找不到".. Value .. "这个职业")
		table.insert(RetTbl, Value)
	end
	return RetTbl
end
