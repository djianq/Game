---------------------------------------------------------------------------
-- $Id: proxy.lua 60664 2011-11-28 11:22:55Z liangyj@NETEASE.COM $
-- 生成服务器端所需的数据配置文件
---------------------------------------------------------------------------

OUTPUTBASE = ""
------------------
-- 初始化xls解析库
dofile("xlslua_reader/util/class.lua")
dofile("xlslua_reader/util/common.lua")
dofile("xlslua_reader/util/sheet.lua")
dofile("xlslua_reader/util/colrule.lua")
dofile("xlslua_reader/util/sheetx.lua")
dofile("xlslua_reader/util/maker.lua")
dofile("xlslua_reader/util/asmaker.lua")

----------------------------
-- 加载解析文件并解析指定xls
-------

local InputFile = arg[1] or "D:/pet/design/trunk/S数值表/技能与BUFF表/技能实现表.xls"
print("\n InputFile", InputFile)

InputFile = InputFile:gsub("\\", "/")

os.execute(string.format("lua proxy2.lua \"%s\" 1> tmpout.txt 2> tmperr.txt", InputFile))
os.exit()
