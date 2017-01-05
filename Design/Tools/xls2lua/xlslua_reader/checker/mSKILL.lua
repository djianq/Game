local SkillCfg = GetFileConfig("client/setting/combat/skill_cfg4.lua")
return function (SkIdStr)
	if SkIdStr then
		local SkId = tonumber(SkIdStr)
		assert(SkillCfg.SkillInfo[SkId],"没找到技能【"..SkIdStr.."】，请查看技能表")
		return SkId	
	end
end
