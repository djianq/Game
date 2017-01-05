return function (Data)
	local Table = {} 
	Table["SpecialFuncIds"] = {}
	Table["BuffIds"] = {}
	local TmpList = Split(Data, ";")
	for i,TmpData in ipairs(TmpList) do
		local Info = Split(TmpData, "|")
		assert(#Info == 2 or #Info == 3 ,"参数错误,应该为[飞行道具id|特殊功能id] 或者 [BUFF|飞行道具id|BUFFid]")

		if #Info == 3 then
			assert(Info[1] == "BUFF","参数错误,应该为[BUFF|飞行道具id|BUFFid]")
			table.insert(Table["BuffIds"], {Id = tonumber(Info[2]),BuffId = tonumber(Info[3])} )
		else
			table.insert(Table["SpecialFuncIds"], {Id = tonumber(Info[1]),SpecialFuncId = tonumber(Info[2])} )
		end
	end

	return Table 
end 