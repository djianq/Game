
local CampName2Type = dofile("server/setting/camp_name2type.lua")
local IsUserCamps = dofile("server/setting/camp_baseinfo.lua").IsUserCamp	

return function(Data)
	print(Data)
	local RetTbl = {}
	local CampNames = Split(Data, ";")
	for _,CampName in ipairs(CampNames) do
		print(CampName)
		local CampId = CampName2Type[CampName]
		assert(CampId, "阵营关系表中找不到"..CampName.."对应的阵营Id")
		local IsUserCamp = IsUserCamps[CampId]
		assert(IsUserCamp, CampName .. "阵营不属于玩家")
		table.insert(RetTbl, CampId)
	end
	return RetTbl
end
