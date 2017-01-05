local HeroAttribute = GetFileConfig(OUTPUTBASE.."server/setting/yongbing_cfg.lua")	
return function (Data)
	local Table = {} 
	local TempTable = Split(Data, "|")
	assert(#TempTable==2,"参数错误,应该为[算子名字|加成值]")	
	assert( HeroAttribute.AttributeCounter[TempTable[1]],"找不到对应"..TempTable[1].."的变量名")

	Table.AttrName = TempTable[1]
	Table.Value = tonumber(TempTable[2])

	return Table
end
