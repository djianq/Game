----------------------------------------------------------
--作者：zork
--功能描述：负责转换物品配置
--目标表: S数值表/物品 下所有物品配置表 
--依赖表：无
--------------------------------------

clsItemMaker = dofile("server/maker/maker_buildclass.lua"):Inherit()

function clsItemMaker:GetFunctionFilter()
	local Map = {}
	Map["_NameColor1"] = "\"#cffc4d3d7\""
	Map["_NameColor2"] = "\"#cff5ea8db\""
	Map["_NameColor3"] = "\"#cff4bdc3c\""
	Map["_NameColor4"] = "\"#cffdd9017\""
	Map["_NameColor5"] = "\"#cffdb300e\""
	Map["_NameColor6"] = "\"#cffa53cdc\""
	return Map
end

function clsItemMaker:MakeTable()

	self.FinalTable = Super(clsItemMaker).MakeTable(self)
	
	return self.FinalTable
end

return clsItemMaker
