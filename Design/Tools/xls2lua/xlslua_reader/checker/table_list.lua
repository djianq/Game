
return function (Data)
	local Tbl = Split(Data, ";")
	local Ret = {}
	for k,v in ipairs(Tbl) do
		if v~="" then
			local T = loadstring("return " .. v)()
			table.insert(Ret, T)		
		end
	end
	return Ret
end