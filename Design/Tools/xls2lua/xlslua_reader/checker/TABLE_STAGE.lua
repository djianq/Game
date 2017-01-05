local StageCfg =  GetFileConfig("server/setting/stage_cfg.lua")

return function (Data)
	local DataTbl = Split(Data, ",") 
	--table.print(DataTbl)
	local NewData = {}
	for Idx, Stage in pairs(DataTbl) do 
		local Flag = false 
		for id, StageInfo in pairs(StageCfg.StageCfg) do 
			if StageInfo.Name == Stage then 
				Flag = true 
				NewData[Idx] = id 
				break
			end
		end
		
		for id, StageInfo in pairs(StageCfg.ActStageCfg) do 
			if StageInfo.Name == Stage then 
				Flag = true 
				NewData[Idx] = id
				break
			end
		end
		assert(Flag, "没有这个关卡  " .. Stage)
	end
	
	return NewData
end