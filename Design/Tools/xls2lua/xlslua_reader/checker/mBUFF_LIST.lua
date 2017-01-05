local BuffCfg = GetFileConfig(OUTPUTBASE.."server/setting/buff.lua")
return function (Data)
	local TableString, ErrMsg = SafeSplit(tostring(Data))
	if not TableString then return nil, ErrMsg end
	local BuffIds = {}
	for _, BName in ipairs(TableString) do
		assert(BuffCfg.Name2Id[BName],"没找到Buff【"..BName.."】，请查看B_Buff配置表")
		table.insert(BuffIds, BuffCfg.Name2Id[BName])
	end
	return BuffIds
end
