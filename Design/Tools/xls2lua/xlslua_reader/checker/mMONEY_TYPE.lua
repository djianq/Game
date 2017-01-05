local Cfg = GetFileConfig(OUTPUTBASE .. "server/setting/item/currency_attribute.lua")["ConstInfo"]["配置表"]
return function(Data)
	local RetTbl = {}
	local AttachList = Split(Data, "|")
	local Currency = Cfg[tonumber(Type)]
	assert(Currency, "找不到" .. Type .. "对应的货币类型")
	return Data
end
