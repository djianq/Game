-- 模块初始化只执行一次
function SystemStartup(self)
end

-- 每次加载模块均会执行
function __init__(self)
	-- 配置 setting 文件路径
	self.FileCfg = 
	{
		-- 测试配置
		actionCfg = "setting/attrchange_cfg.lua",
	}

	self:LoadSetting()
end


-- 每次update模块均会执行
function __update__(self)
	self:LoadSetting()
end

-- 每次释放模块均会执行
function __destroy__(self)

end

function LoadSetting(self, Names)
	if Names then
		for _, n in ipairs(Names) do
			self[n] = safe_dofile(self.FileCfg[n])
		end
		return
	end

	for k, v in pairs(self.FileCfg) do
		self[k] = safe_dofile(v)
		assert(self[k], string.format("Error : Read (%s) File Error !!! ", v))
	end
end
