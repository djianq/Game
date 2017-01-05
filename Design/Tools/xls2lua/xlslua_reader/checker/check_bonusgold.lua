
local Bonus = GetFileConfig("server/setting/bonus/bonus_gold_config.lua").RuleData
return function(Data)
	assert(Bonus[Data], "在金币奖励表中找不到".. Data .. "这个奖励模板")
	return Data
end