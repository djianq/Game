local Bonus = GetFileConfig("server/setting/bonus/bonus_exp_config.lua").BonusRule
return function(Data)
	assert(Bonus[Data], "在经验奖励表中找不到".. Data .. "这个奖励模板")
	return Data
end