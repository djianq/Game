--local ItemName2Type=  GetFileConfig(OUTPUTBASE.."server/setting/item/name2type.lua")

return function (Data)
	local ItemCfg = {} 
	local TmpItem = Split(Data, "|")
	ItemCfg.Id = tonumber(TmpItem[1])
	ItemCfg.Count = tonumber(TmpItem[2])
	return ItemCfg
end