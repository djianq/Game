local BuffCfg = GetFileConfig(OUTPUTBASE.."server/setting/buff.lua")
return function (Data)
	local Tmp = Split(Data, "|")
	for _, Id in pairs(Tmp)do
		assert(BuffCfg.BuffInfo[tonumber(Td)],"没找到Buff【"..Id.."】，请查看B_Buff配置表")
	end
	return Tmp 
end 