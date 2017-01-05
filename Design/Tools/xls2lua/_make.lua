---------------------------------------------------------------------------
-- $Id: _make.lua 10708 2009-05-15 08:38:39Z akara $
-- 生成所需的数据配置文件
---------------------------------------------------------------------------
OUTPUTBASE = ""
-- 初始化xls解析库
dofile("xlslua_reader/util/class.lua")
dofile("xlslua_reader/util/common.lua")
dofile("xlslua_reader/util/sheet.lua")
dofile("xlslua_reader/util/colrule.lua")
dofile("xlslua_reader/util/sheetx.lua")
dofile("xlslua_reader/util/maker.lua")
dofile("xlslua_reader/util/asmaker.lua")

-- 检查命令行参数
local SETTING_FILE = arg[1] -- eg. "setting_server.lua"
assert(SETTING_FILE, "第一个参数必须是maker的配置文件名，才能运行"..__U8T(arg[0]))
local MAKER_DIR = arg[2] -- eg. "server/setting/"
assert(MAKER_DIR, "第二个参数必须是所有maker_*.lua所在的目录，才能运行"..__U8T(arg[0]))
local OUTPUT_DIR = OUTPUTBASE..arg[3] -- eg. "server/setting/"
assert(OUTPUT_DIR, "第三个参数必须是结果数据文件输出目录，才能运行"..__U8T(arg[0]))


local data = assert(assert(loadstring(io.open(SETTING_FILE, "rt"):read("*a")))())
local SumTimes = {Load=0, Convert=0, Save=0, Total=0}

for i, config in ipairs(data) do
	-- 转换程序代码， 原始数据文件， 输出数据文件， 保留， 转换过滤表
	local MakerFile = MAKER_DIR..config[1]
	local Chunk = assert(loadfile(__AT(MakerFile)))
	local Desc = GetMakerDesc(MakerFile) -- 这个函数在util/common.lua中定义的
	if Desc then
		print("\n"..Desc.."\n")
	end
	local Times = Chunk():New(__AT(config[2]), __AT(OUTPUT_DIR..config[3]), config[4], config[5]):Make()
	
	-- 累计时间消耗
	for Key, _ in pairs(SumTimes) do
		SumTimes[Key] = SumTimes[Key] + Times[Key]
	end
end

-- 生成多语言包
MakeMultiLangFile(true)

local MakerAmount = #data
local TimeMsg = string.format("\n总耗时(%.02f秒/%d个)平均(%.02f秒/个)](加载/转换/存盘: %.02f/%.02f/%.02f)",
	SumTimes.Total, MakerAmount, 
	SumTimes.Total / MakerAmount,
	SumTimes.Load, SumTimes.Convert, SumTimes.Save)
print(TimeMsg)
