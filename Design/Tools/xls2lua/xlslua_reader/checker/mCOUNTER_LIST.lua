local HeroAttribute = GetFileConfig(OUTPUTBASE.."server/setting/yongbing_cfg.lua")	
return function (Data)
	local Table = {} 
	local TmpData = Split(Data, ";")
	for i,Value in pairs(TmpData) do
		local TempTable = Split(Value, "|")
		assert(#TempTable==2,Data.."参数错误,应该为[算子名字:加成值]")
		assert( HeroAttribute.AttributeCounter[TempTable[1]],"找不到对应"..TempTable[1].."的变量名")
		table.insert(Table,{TempTable[1],tonumber(TempTable[2])})
	end
	return Table
end
