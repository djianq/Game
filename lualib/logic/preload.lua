-- This file will execute before every lua service start
-- See config

CONST_PATH = "lualib/logic/"
-- local util = require "util"

-- 加载所有需要用 dofile 执行的模块
DOFILELIST = 
{
	"base/extend.lua",
	"base/import.lua",
	"base/core.lua",
	"base/class.lua",
}

for _, file in ipairs(DOFILELIST) do
	assert(not dofile(file), file)
end
