
local BUFF_CFG = GetFileConfig(OUTPUTBASE.."server/setting/buff.lua")

return function(Data)
	local BuffCfg = BUFF_CFG.BuffInfo

	local BuffTips = "应该为[BuffId:持续类型(1为整个系统,2为下一关)]"
	local SpecialTips = "[加成血量百分比:3,或者佣兵复活次数:4["


	local Table = {} 
	local TmpData = Split(Data, "|")
	for i,Value in pairs(TmpData) do
		local TempTable = Split(Value, ":")
		assert(#TempTable==2,"参数错误,"..BuffTips.." 或 "..SpecialTips)
		assert(tonumber(TempTable[2]) >=1 and tonumber(TempTable[2]) <=4 ,"第二参数错误,应该为[1为整个系统,2为下一关,3为加成血量百分比,4佣兵复活次数]")
	
		if tonumber(TempTable[2]) >=1 and tonumber(TempTable[2]) <=2 then
			local BuffId = tonumber(TempTable[1])
			assert( BuffCfg[BuffId],"找不到对应"..TempTable[1].."的Buff")
			table.insert(Table,{BuffId,tonumber(TempTable[2])})
		else
			table.insert(Table,{tonumber(TempTable[1]),tonumber(TempTable[2])})
		end
	end

	return Table
end
