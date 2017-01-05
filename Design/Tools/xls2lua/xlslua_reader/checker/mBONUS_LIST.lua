local BonusItem = GetFileConfig("server/setting/bonus/bonus_item_config.lua").RuleData
-- local BonusGold = GetFileConfig("server/setting/bonus/bonus_gold_config.lua").RuleData
-- local BonusExp = GetFileConfig("server/setting/bonus/bonus_exp_config.lua").BonusRule
return function(Data)
	local DataTbl = Split(Data, ",")
	for _, data in pairs(DataTbl) do
		assert(BonusItem[data], "在奖励表中找不到".. Data .. "这个奖励模板")
	end
	return DataTbl
end