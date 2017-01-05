local EquipType = {
		["武器"] = 1,
		["胸甲"] = 2,
		["腰带"] = 3,
		["护腿"] = 4,
		["鞋子"] = 5,
		["神器"] = 6,
		["守护"] = 7,
		["头部"] = 8,
		["躯干"] = 9,
		["手部"] = 10,
		["腿部"] = 11,
}
return function (Data)
	local RetTbl = {}
	local Types = Split(Data,";")
	for _, Type in pairs(Types) do
		assert(EquipType[Type],"类型【"..Type.."】不存在，请联系程序员,正确格式：左手;右手")
		-- if Type == "戒指" or Type == "手镯" or Type == "耳环" then
		-- 	table.insert(RetTbl,EquipType[Type][1])
		-- 	table.insert(RetTbl,EquipType[Type][2])
		-- else 
		-- 	table.insert(RetTbl,EquipType[Type])
		-- end
		table.insert(RetTbl,EquipType[Type])
	end
	return RetTbl
end
--1:头饰、2：耳环、3：项链、4：戒指、5：衣服、6：手镯、7：下摆、8：玉佩、9：主手、10：副手、11：时装、12：肩膀、13：耳环、14：护腕、15、戒指、16：手套、17：手镯、18：腰带、19：鞋子

--[[	["时装"] = 1,
				["头饰"] = 2,
				["衣服"] = 3,
				["背饰"] = 4,
				["肩部"] = 5,
				["左手"] = 6,
				["右手"] = 7,
				["双手"] = 7, -- 双手武器放在右手装备栏
				["左臂"] = 8,
				["右臂"] = 9,
				["腰部"] = 10,
				["腿部"] = 11,
				["鞋"] = 12,--]]