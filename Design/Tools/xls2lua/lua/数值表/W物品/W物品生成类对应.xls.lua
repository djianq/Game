-- xls md5:1d5fdf072b5519d2ffdce0b5862eb21f
return {
["虚拟货币子类对应"] = {
		["A"] = {"string@ukey", "类型", "钻石", "金币", "将魂", "商店代币", "远征币", "竞技币", "功勋", "装备抽积分", "技能点", "零能", "经验", "佣兵经验", },
		["B"] = {"int", "使用类编号", 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, },
		["C"] = {"int@ukey", "小类索引编号", 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, 1012, },
		["D"] = {"string@ukey", "小类索引变量名", "GOLD", "MONEY", "SOUL", "TOKEN", "YZ_MONEY", "SPORTS", "EXPLOIT", "ARMS_POINT", "SKILL_POINT", "ZERO_POWER", "USER_EXP", "MERCENARY_EXP", },
	},
["物品使用配置"] = {
		["A"] = {"int", "使用类型值", },
		["B"] = {"string@default", "鼠标样式", },
		["C"] = {"string@default", "回调函数", },
		["D"] = {"string@default", "说明", },
	},
["佣兵道具子类对应"] = {
		["A"] = {"string@ukey", "类型", "佣兵进阶", "佣兵升级", "佣兵技能", "佣兵属性", },
		["B"] = {"int", "使用类编号", 13, 13, 13, 13, },
		["C"] = {"int@ukey", "小类索引编号", 13001, 13002, 13003, 13004, },
		["D"] = {"string@ukey", "小类索引变量名", "MERCENARY_ADVANCED", "MERCENARY_UPGRADE", "MERCENARY_SKILL", "MERCENARY_ATTR", },
	},
["材料子类对应"] = {
		["A"] = {"string@ukey", "类型", "神机进阶", "子弹", "神机强化", "战甲", "精炼石", "黑血技材料", "普通材料", "其它", "原力解锁", },
		["B"] = {"int", "使用类编号", 9, 9, 9, 9, 9, 9, 9, 9, 9, },
		["C"] = {"int@ukey", "小类索引编号", 9001, 9002, 9003, 9004, 9005, 9006, 9007, 9008, 9009, },
		["D"] = {"string@ukey", "小类索引变量名", "WEAPON_ADVANCED", "MATERIAL_BULLET", "WEAPON_ENHANCE", "MATERIAL_EQUIP", "REFINE_STONE", "MATERIAL_SKILL", "MATERIAL_NORMAL", "MATERIAL_OTHER", "MATERIAL_FORCE", },
	},
["__SheetOrder"] = {
		["A"] = {"string", "类型对应", "使用类型对应", "虚拟货币子类对应", "武器子类对应", "子弹子类对应", "神机子类对应", "防具子类对应", "饰品子类对应", "时装子类对应", "材料子类对应", "消耗品子类对应", "雕纹子类对应", "碎片子类对应", "宝石子类对应", "佣兵道具子类对应", "物品使用配置", },
	},
["宝石子类对应"] = {
		["A"] = {"string@ukey", "类型", "攻击", "辅助", "防御", },
		["B"] = {"int", "使用类编号", 12, 12, 12, },
		["C"] = {"int@ukey", "小类索引编号", 12001, 12002, 12003, },
		["D"] = {"string@ukey", "小类索引变量名", "JEWEL_ATTACK", "JEWEL_AUXILIARY", "JEWEL_DEFENSE", },
	},
["防具子类对应"] = {
		["A"] = {"string@ukey", "类型", "胸甲", "护腿", "腰带", "鞋子", "神器", "守护", "神器强化", "守护强化", },
		["B"] = {"int", "使用类编号", 5, 5, 5, 5, 5, 5, 5, 5, },
		["C"] = {"int@ukey", "小类索引编号", 5001, 5002, 5003, 5004, 5005, 5006, 5007, 5008, },
		["D"] = {"string@ukey", "小类索引变量名", "CUIRASS", "LEG_GUARD", "BELT", "SHOES", "RELIC", "DEFEND", "RELIC_FEED", "DEFEND_FEED", },
	},
["消耗品子类对应"] = {
		["A"] = {"string@ukey", "类型", "恢复类药品", "宝箱", "血技技能书", "商城消耗品", "代金物", "战斗道具", "限时道具", "经验金钱道具", },
		["B"] = {"int", "使用类编号", 10, 10, 10, 10, 10, 10, 10, 10, },
		["C"] = {"int@ukey", "小类索引编号", 10001, 10002, 10003, 10004, 10005, 10006, 10007, 10008, },
		["D"] = {"string@ukey", "小类索引变量名", "RECOVER", "CHETS", "SKILL_BOOK", "SHOP_COST_ITEM", "PROPERTY_TOKEN", "PROPERTY__FIGHTING", "PROPERTY_TIME", "PROPERTY_EXP_CURRENCY", },
	},
["类型对应"] = {
		["A"] = {"string@ukey", "类型", "虚拟货币", "武器", "子弹", "神机", "防具", "饰品", "时装", "材料", "消耗品", "碎片", "宝石", "佣兵道具", "雕纹", },
		["B"] = {"int", "使用类编号", 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, "12", "13", "14", },
		["C"] = {"string@default", "说明", "普通类", "属性加减类", "属性加减类", "属性加减类", "属性加减类", "属性加减类", "属性加减类", "普通类", "普通类", "普通类", "属性加减类", "普通类", "属性加减类", },
		["D"] = {"string", "ID范围", "1000,1999", "2000,11999", "12000,12999", "15000,19999", "20000,24999", "25000,29999", "30000,34999", "40000,44999", "45000,49999", "50000,54999", "55000,59999", "60000,64999", "13000,14999", },
	},
["使用类型对应"] = {
		["A"] = {"int@ukey", "类编号", 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, },
		["B"] = {"string@ukey", "类路径", "obj/item/currency.lua", "obj/item/weapon.lua", "obj/item/bullet.lua", "obj/item/shenji.lua", "obj/item/userequip.lua", "obj/item/ornament.lua", "obj/item/fashion.lua", "obj/item/common_item.lua", "obj/item/property_item.lua", "obj/item/chip.lua", "obj/item/jewel.lua", "obj/item/mercenary_item.lua", "obj/item/diaowen.lua", },
		["C"] = {"string", "类名", "clsCurrencyItemObj", "clsWeaponItemObj", "clsBulletItemObj", "clsShenJiItemObj", "clsUserEquip", "clsUserOrnament", "clsUserFashion", "clsCommonItemObj", "clsPropertyItemObj", "clsChipItemObj", "clsJewelItemObj", "clsMercenaryItemObj", "clsDiaoWenItemObj", },
		["D"] = {"string@default", "说明", "虚拟货币", "武器类", "子弹类", "神机类", "人物装备（防具）", "饰品类", "时装类", "材料类", "消耗品类", "碎片类", "宝石类", "佣兵道具", "雕纹", },
	},
["子弹子类对应"] = {
		["A"] = {"string@ukey", "类型", "冲锋枪", "重炮", "散弹", "狙击", "狗粮", },
		["B"] = {"int", "使用类编号", 3, 3, 3, 3, 3, },
		["C"] = {"int@ukey", "小类索引编号", 3001, 3002, 3003, 3004, 3005, },
		["D"] = {"string@ukey", "小类索引变量名", "SUB_MACHINE_GUN", "GUNNERY", "SHOTGUN", "SNIPE", "BULLET_FEED", },
	},
["雕纹子类对应"] = {
		["A"] = {"string@ukey", "类型", "雕纹", },
		["B"] = {"int", "使用类编号", 14, },
		["C"] = {"int@ukey", "小类索引编号", 13001, },
		["D"] = {"string@ukey", "小类索引变量名", "DIAOWEN", },
	},
["神机子类对应"] = {
		["A"] = {"string@ukey", "类型", "狗粮", "攻击", "防御", "辅助", },
		["B"] = {"int", "使用类编号", 4, 4, 4, 4, },
		["C"] = {"int@ukey", "小类索引编号", 4001, 4002, 4003, 4004, },
		["D"] = {"string@ukey", "小类索引变量名", "SHEN_JI_FEED", "SHEN_JI_ATTACK", "SHEN_JI_DEFENSE", "SHEN_JI_AUXILIARY", },
	},
["碎片子类对应"] = {
		["A"] = {"string@ukey", "类型", "防具碎片", "时装碎片", "佣兵碎片", },
		["B"] = {"int", "使用类编号", 11, 11, 11, },
		["C"] = {"int@ukey", "小类索引编号", 11001, 11002, 11003, },
		["D"] = {"string@ukey", "小类索引变量名", "CHIP_EQUIP", "CHIP_FASHION", "CHIP_MERCENARY", },
	},
["武器子类对应"] = {
		["A"] = {"string@ukey", "类型", "近战武器", },
		["B"] = {"int", "使用类编号", 2, },
		["C"] = {"int@ukey", "小类索引编号", 2001, },
		["D"] = {"string@ukey", "小类索引变量名", "MELEE", },
	},
["时装子类对应"] = {
		["A"] = {"string@ukey", "类型", "时装", },
		["B"] = {"int", "使用类编号", 7, },
		["C"] = {"int@ukey", "小类索引编号", 7001, },
		["D"] = {"string@ukey", "小类索引变量名", "FASHION", },
	},
["饰品子类对应"] = {
		["A"] = {"string@ukey", "类型", "头部", "躯干", "手部", "腿部", },
		["B"] = {"int", "使用类编号", 6, 6, 6, 6, },
		["C"] = {"int@ukey", "小类索引编号", 6001, 6002, 6003, 6004, },
		["D"] = {"string@ukey", "小类索引变量名", "HEAD", "BODY", "HAND", "LEG", },
	},
}