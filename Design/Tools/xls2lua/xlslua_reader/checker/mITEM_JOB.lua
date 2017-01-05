--local ItemName2Type=  GetFileConfig(OUTPUTBASE.."server/setting/item/name2type.lua")

return function (Data)
	local ItemCfg = {} 
	local TmpItems = Split(Data, ",")

	if #TmpItems == 1 then
		ItemCfg.CommonItemId = tonumber(Data)
	else	
		for _,strData in ipairs(TmpItems) do
			local TmpData = Split(strData, "|")
			assert(#TmpData == 2,"参数错误,"..strData)

			local TmpInfo = {
				Job = tonumber(TmpData[1]),
				ItemId = tonumber(TmpData[2]),
			}
			if not ItemCfg.JobItems then
				ItemCfg.JobItems = {}
			end
			ItemCfg.JobItems[TmpInfo.Job] = TmpInfo
		end


	end


	
	return ItemCfg
end