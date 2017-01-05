local BonusItem = GetFileConfig("server/setting/reward/reward_item_cfg.lua").RuleData
-- local BonusGold = GetFileConfig("server/setting/reward/reward_gold_cfg.lua").RuleData
-- local BonusExp = GetFileConfig("server/setting/reward/reward_exp_cfg.lua").BonusRule
return function(Data)
	local Reward = {}
	local DataTbl = Split(Data, ",")
	for _, data in pairs(DataTbl) do
		local Tmpdate = Split(data, "|")
		local RewardId = tonumber(Tmpdate[1])
		assert(BonusItem[RewardId], "在奖励表中找不到".. Data .. "这个奖励模板")
		local Count = tonumber(Tmpdate[2]) or 1
		table.insert(Reward, {RewardId, Count})
	end
	return Reward
end