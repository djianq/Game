return 
{
	["AttrCfg"] = {
		["AllDamageAdd"] = {
			["Priority"] = 30,
			["ShowName"] = "全系伤害",
		},
		["AllDamageReduce"] = {
			["Priority"] = 31,
			["ShowName"] = "受伤减免",
		},
		["BlockFactor"] = {
			["Priority"] = 22,
			["ShowName"] = "招架减伤",
		},
		["Crit"] = {
			["Priority"] = 19,
			["ShowName"] = "暴击",
		},
		["CritFactor"] = {
			["Priority"] = 20,
			["ShowName"] = "暴击伤害",
		},
		["CurativeEff"] = {
			["Priority"] = 33,
			["ShowName"] = "被治疗效果",
		},
		["Dodge"] = {
			["Priority"] = 18,
			["ShowName"] = "闪避",
		},
		["Fighting"] = {
			["Priority"] = 1,
			["ShowName"] = "战斗力",
		},
		["FireAtk"] = {
			["Priority"] = 9,
			["ShowName"] = "火元素攻击",
		},
		["FireDef"] = {
			["Priority"] = 13,
			["ShowName"] = "火元素防御",
		},
		["Hit"] = {
			["Priority"] = 17,
			["ShowName"] = "命中",
		},
		["IceAtk"] = {
			["Priority"] = 10,
			["ShowName"] = "冰元素攻击",
		},
		["IceDef"] = {
			["Priority"] = 14,
			["ShowName"] = "冰元素防御",
		},
		["IgnFireDefRate"] = {
			["Priority"] = 37,
			["ShowName"] = "忽视火抗",
		},
		["IgnIceDefRate"] = {
			["Priority"] = 38,
			["ShowName"] = "忽视冰抗",
		},
		["IgnMeleeDefRate"] = {
			["Priority"] = 35,
			["ShowName"] = "忽视近战防御",
		},
		["IgnRangeDefRate"] = {
			["Priority"] = 36,
			["ShowName"] = "忽视远程防御",
		},
		["IgnThunderDefRate"] = {
			["Priority"] = 39,
			["ShowName"] = "忽视雷抗",
		},
		["IgnWindDefRate"] = {
			["Priority"] = 40,
			["ShowName"] = "忽视风抗",
		},
		["Level"] = {
			["Priority"] = 2,
			["ShowName"] = "等级",
		},
		["MaxHp"] = {
			["Priority"] = 3,
			["ShowName"] = "最大生命",
		},
		["MaxOp"] = {
			["Priority"] = 4,
			["ShowName"] = "OP上限",
		},
		["MeleeAtk"] = {
			["Priority"] = 5,
			["ShowName"] = "近战攻击",
		},
		["MeleeDef"] = {
			["Priority"] = 7,
			["ShowName"] = "近战防御",
		},
		["MonsterDamage"] = {
			["Priority"] = 29,
			["ShowName"] = "怪物伤害",
		},
		["ParryFactor"] = {
			["Priority"] = 21,
			["ShowName"] = "格挡减伤",
		},
		["RangeAtk"] = {
			["Priority"] = 6,
			["ShowName"] = "远程攻击",
		},
		["RangeDef"] = {
			["Priority"] = 8,
			["ShowName"] = "远程防御",
		},
		["SuckBlood"] = {
			["Priority"] = 32,
			["ShowName"] = "吸血",
		},
		["ThunderAtk"] = {
			["Priority"] = 11,
			["ShowName"] = "雷元素攻击",
		},
		["ThunderDef"] = {
			["Priority"] = 15,
			["ShowName"] = "雷元素防御",
		},
		["TreatEff"] = {
			["Priority"] = 34,
			["ShowName"] = "治疗效果",
		},
		["WindAtk"] = {
			["Priority"] = 12,
			["ShowName"] = "风元素攻击",
		},
		["WindDef"] = {
			["Priority"] = 16,
			["ShowName"] = "风元素防御",
		},
	},
	["TypeAttrCfg"] = {
		["EQUIP_DRESS"] = {
			"Fighting",
			["PList"] = {
				1,
				3,
				4,
				5,
				6,
				7,
				8,
				9,
				10,
				11,
				12,
				13,
				14,
				15,
				16,
				17,
				18,
				19,
				20,
				21,
				22,
				29,
				30,
				31,
				32,
				33,
				34,
				35,
				36,
				37,
				38,
				39,
				40,
			},
			[10] = "IceAtk",
			[11] = "ThunderAtk",
			[12] = "WindAtk",
			[13] = "FireDef",
			[14] = "IceDef",
			[15] = "ThunderDef",
			[16] = "WindDef",
			[17] = "Hit",
			[18] = "Dodge",
			[19] = "Crit",
			[20] = "CritFactor",
			[21] = "ParryFactor",
			[22] = "BlockFactor",
			[29] = "MonsterDamage",
			[3] = "MaxHp",
			[30] = "AllDamageAdd",
			[31] = "AllDamageReduce",
			[32] = "SuckBlood",
			[33] = "CurativeEff",
			[34] = "TreatEff",
			[35] = "IgnMeleeDefRate",
			[36] = "IgnRangeDefRate",
			[37] = "IgnFireDefRate",
			[38] = "IgnIceDefRate",
			[39] = "IgnThunderDefRate",
			[4] = "MaxOp",
			[40] = "IgnWindDefRate",
			[5] = "MeleeAtk",
			[6] = "RangeAtk",
			[7] = "MeleeDef",
			[8] = "RangeDef",
			[9] = "FireAtk",
		},
		["LEVEL_UP"] = {
			"Fighting",
			"Level",
			"MaxHp",
			["PList"] = {
				1,
				2,
				3,
				5,
				6,
				7,
				8,
			},
			[5] = "MeleeAtk",
			[6] = "RangeAtk",
			[7] = "MeleeDef",
			[8] = "RangeDef",
		},
	},
	["TypeCfg"] = {
		["装备穿戴"] = "EQUIP_DRESS",
		["角色升级"] = "LEVEL_UP",
	},
}