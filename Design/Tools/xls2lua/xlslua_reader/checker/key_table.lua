return function (Data)
	local Rec = Split(Data,";")
	local Ret = {}
	for _, Val in pairs(Rec) do
		local Vals = Split(Val,"=")
		assert(Vals and (#Vals==2),"数值【"..Data.."】不符合key_table格式：key=val;key2=val2")
		local RetVal = Vals[2]
		if string.match(RetVal,"^%d+$") then
			RetVal = tonumber(RetVal)
		else
			RetVal = MultiFilter(RetVal)
		end
		Ret[Vals[1]]=RetVal
	end

	return Ret
end
