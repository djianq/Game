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
print("\n InputFile", __U8T(InputFile))

InputFile = InputFile:gsub("\\", "/")

os.execute(string.format("cd dist & xls2lua.exe \"%s\" > output.txt", InputFile))
os.execute("cd ..")

local File = assert(io.open("dist/output.txt"))
local OutKey = nil
for Line in File:lines() do
	if string.find(Line, "OutKey:") then
		OutKey = string.sub(Line, 7, string.len(Line))
		break
	end
end
File:close()
os.execute("del dist\\output.txt")

assert(OutKey)

-- 读取转换配置文件
local sdata = assert(assert(loadstring(io.open("setting_server.lua", "rt"):read("*a")))())
local cdata = assert(assert(loadstring(io.open("setting_client.lua", "rt"):read("*a")))())
local ascdata = assert(assert(loadstring(io.open("setting_asclient.lua", "rt"):read("*a")))())

-- 过滤所有已配置的文件
function Filter(tbl, makerpath,dest)
	local IsOK = false
	for i, config in ipairs(tbl) do
		if string.find(__U8T(OutKey), config[2]) then
			print("----Make-----", config[1], config[2], config[3])
			local LuaFile = makerpath.."/maker/"..config[1]
			local Chunk, ErrMsg = loadfile(__AT(LuaFile))
			if not Chunk then
				error("模块["..LuaFile.."]语法错误："..tostring(ErrMsg))
			end
			local Desc = GetMakerDesc(LuaFile) -- 这个函数在util/common.lua中定义的
			if Desc then
				print("\n"..Desc.."\n")
			end
			Chunk():New(__AT(config[2]), __AT(dest.."/setting/"..(config[3] or "")), config[4], config[5],"单导"):Make()
			IsOK = true
		end
	end	
	
	return IsOK
end

local IsServerOK = Filter(sdata, "server",OUTPUTBASE.."server")
local IsClientOK = Filter(cdata, "client",OUTPUTBASE.."client")
--local IsClientOK = true 
local IsAsClientOK = Filter(ascdata, "asclient",OUTPUTBASE.."asclient")
if not IsServerOK and not IsClientOK and not IsAsClientOK then
	error("找不到["..__U8T(InputFile).."]对应的maker。请联系程序员添加。")
end

-- 生成多语言包
MakeMultiLangFile(true)



