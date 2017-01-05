local AttachTbl = {
	["头"] = "head",
	["肩"] = "clavicle_left",
	["身"] = "body",
	--["背"] = "back",
	["飘带"] = "ribbon",
	["左手"] = "left_hand",
	["左臂"] = "left_hand",
	["右手"] = "right_hand",
	["右臂"] = "right_hand",
	["右腰"] = "waist_right",
	["左腰"] = "waist_left",
	["肩背"] = "back_shoulder",
	["腰背"] = "back_at",
	["右盾"] = "right_shield",
	["左盾"] = "left_shield",
}
return function(Data)
	local RetTbl = {}
	local AttachList = Split(Data, ";")
	for Idx, Value in pairs(AttachList) do
		local AttachName = AttachTbl[Value]
		assert(AttachName, "找不到"..Value.."对应的挂接点名")
		table.insert(RetTbl, AttachName)
	end
	return RetTbl
end
