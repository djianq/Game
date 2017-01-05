
return function (Data)
	local Tbl = {}
	local TmpTips = Split(Data,",")

	if #TmpTips == 1 then
		Tbl.CommonTips = Data
	else
		for _,strData in ipairs(TmpTips) do
			local TmpData = Split(strData, "|")
			assert(#TmpData == 2,"参数错误,"..strData)

			local TmpInfo = {
				Job = TmpData[1],
				Tips = TmpData[2],
			}
			if not Tbl.JobTips then
				Tbl.JobTips = {}
			end
			Tbl.JobTips[TmpInfo.Job] = TmpInfo
		end

	end

	return Tbl
end
