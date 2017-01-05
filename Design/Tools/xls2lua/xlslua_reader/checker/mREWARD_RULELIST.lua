-- local RewardItemCfg = GetFileConfig(OUTPUTBASE.."server/setting/reward/reward_item_cfg.lua").RuleData
-- local RewardGoldCfg = GetFileConfig(OUTPUTBASE.."server/setting/reward/reward_gold_cfg.lua").RuleData
-- local RewardExpCfg = GetFileConfig(OUTPUTBASE.."server/setting/reward/reward_exp_cfg.lua").BonusRule
return function(Data)
	local TotalTbl = {}
	-- local Tbl = Split(Data, ",")
	-- local CheckRewardCfg = function (Name) 
	-- 	local RuleCfg = RewardItemCfg[Name]
	-- 	if not RuleCfg then
	-- 		RuleCfg = RewardGoldCfg[Name]
	-- 	end
	-- 	if not RuleCfg then
	-- 		RuleCfg = RewardExpCfg[Name]
	-- 	end
	-- 	assert(RuleCfg,"找不到【"..Name.."】对应奖励规则配置,"..Data.."End")
	-- end
	-- for _,Name in ipairs(Tbl) do
	-- 	-- 判断一下是不是里面有分号需要分割
	-- 	if string.find(Name,";") then
	-- 		local NTbl = {}
	-- 		local Names = Split(Name, ";")
	-- 		for _, ChildName in ipairs(Names) do
	-- 			CheckRewardCfg(ChildName)
	-- 			table.insert(NTbl,ChildName)
	-- 		end
	-- 		table.insert(TotalTbl,NTbl)
	-- 	else
	-- 		CheckRewardCfg(Name)
	-- 		table.insert(TotalTbl,Name)
	-- 	end
	-- end
	return TotalTbl
end
