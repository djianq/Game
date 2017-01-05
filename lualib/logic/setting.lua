local SETTING = {}

SETTING.FileCfg = 
{
	-- 测试配置
	actionCfg = "setting/attrchange_cfg.lua",
	itemCfg = "setting/item_cfg.lua",
}

function SETTING.LoadSetting(Names)
	if Names then
		for _, n in ipairs(Names) do
			SETTING[n] = safe_dofile(SETTING.FileCfg[n])
		end
		return
	end

	for k, v in pairs(SETTING.FileCfg) do
		SETTING[k] = safe_dofile(v)
		assert(SETTING[k], string.format("Error : Read (%s) File Error !!! ", v))
	end
end

SETTING.LoadSetting()

return SETTING
