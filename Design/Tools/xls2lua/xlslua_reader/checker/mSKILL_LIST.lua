local SkillCfg = GetFileConfig("client/setting/combat/skill_cfg4.lua")
return function (Data)
	local TableString, ErrMsg = SafeSplit(tostring(Data))
	if not TableString then return nil, ErrMsg end
	local SkillIds = {}
	for _, SkIdStr in ipairs(TableString) do
		local SkId = tonumber(SkIdStr)
		assert(SkillCfg.SkillInfo[SkId],"没找到技能【"..SkId.."】，请查看技能表")
		table.insert(SkillIds,SkId)
	end
	return SkillIds
end
