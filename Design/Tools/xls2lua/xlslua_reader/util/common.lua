local table = table

require("extra")
require("unicode")

dofile("language_cfg.lua")

G_FileCfgMap = {}  -- 全局配置文件，可以在一次执行过程中多个执行点获取相同配置实例
G_CurFileName = nil  -- 全局当前表名
G_CurColName = nil	 -- 当前列名字
G_IsRunChecker = false -- 当前在运行checker

__U8T = extra.ansi_to_utf8
__AT = extra.utf8_to_ansi

-- UTF8 版本的string.find
__U8Find = unicode.utf8.find 
function Utf8Find(SourceStr, TargetStr)
	return __U8Find(SourceStr, TargetStr)
end

-- UTF8 版本的string.gsub
__U8Gsub = unicode.utf8.gsub
function Utf8Gsub(SourceStr, Pattern, Repl, N)
	local U8Result, _ = __U8Gsub(SourceStr, Pattern, Repl, N)
	return U8Result, _
end

-- UTF8 版本的string.gmatch
__U8Gmatch = unicode.utf8.gmatch
function Utf8Gmatch(SourceStr, Pattern)
	return __U8Gmatch(SourceStr, Pattern)
end

__OrgDofile = dofile
function dofile(FilePath)
	return __OrgDofile(__AT(FilePath))
end

function Log(FormatStr, ...)
	print(string.format(FormatStr, ...))
end

----------------------------------------------------------------------
-- 加载文件相关接口
----------------------------------------------------------------------
function FileExist(FilePath)
	local File, Err = io.open(FilePath)
	if File then File:close() end
	return File ~= nil
end

function GetFileDir(FilePath)
	return string.match(FilePath, "(.+)\/.*$")
end

function Mkdir(FilePath)
	print("mkdir ----------------",FilePath)
	os.execute("mkdir "..string.gsub(GetFileDir(FilePath),"\/","\\"))
end

-- 以setting为关键字，多语言输出到 setting/<lang> 目录下
function GetMultiLangPath(FilePath)
	if TARGET_LANG then
		return string.gsub(FilePath,"/setting/","/setting/language/"..TARGET_LANG.."/")
	end
	return FilePath
end

function LoadFunctionFromFile(FilePath)
	local fh = io.open(FilePath)
	assert(fh, "模块文件["..FilePath.. "]打开错误")
	local Data = fh:read("*a")
	local Chunk, ErrMsg = loadstring(Data)
	if not Chunk then
		error("从文件[" .. FilePath .. "]加载函数出错：" .. ErrMsg)
	end

	local Func = Chunk()
	
	fh:close()
	assert(Func)
	return Func
end

function LoadTableGroupFromFile(FilePath)
	local fh = io.open(FilePath)
	assert(fh, "模块文件打开错误："..FilePath)
	local Data = fh:read("*a")
	local Chunk, ErrMsg = loadstring(Data)
	if not Chunk then
		error("从文件[" .. FilePath .. "]加载文档TableGroup出错：" .. ErrMsg)
	end
	local Group = Chunk()

	fh:close()

	-- 获取当前文件表名字
	G_CurFileName = string.match(__U8T(FilePath),".*/(.-)%.xls%.lua$")

	return Group
end

function GetFileConfig(Path)
	local _Path = GetMultiLangPath(Path)
	local f = io.open(_Path,"r")
	if not f then
		return nil
	end
	local BStr = f:read("*a")
	f:close()
	local Func, Error = loadstring(BStr)
	assert(Func, string.format("lua 语法错误：\n文件路径：%s\n错误原因：%s",_Path,tostring(Error)))
	return Func()
end

function GetGlobalFileConfig(Path)
	if not G_FileCfgMap[Path] then
		G_FileCfgMap[Path] = GetFileConfig(Path)	
	end
	return G_FileCfgMap[Path]	
end

function SetGlobalFileConfig(Path, Cfg)
	G_FileCfgMap[Path] = Cfg
end

-- 检查并构造多语言配置
local MultiLangFile = OUTPUTBASE.."language/multi_language.lua"
local LangSrcFile = OUTPUTBASE.."language/need_trans.lua"
local TargetLangCfg = {}
function CheckMultiLanguage(Str)
	if not Str then return end
	if type(Str) ~= "string" then return Str end
	local TmpStr = string.gsub(Str, " ", "")
	if TmpStr == "" then return Str end
	local PattenStr = Str
--	local PattenStr, Pm = FilterStr2Patten(Str)
--	-- 检查是否有中文存在，不存在中文的，直接返回
--	TmpStr = string.gsub(PattenStr,"(@%d-@)","")
--	if TmpStr == "" then return Str end
	local MultiLangCfg = GetGlobalFileConfig(MultiLangFile)
	if not MultiLangCfg then
		MultiLangCfg = {}
		SetGlobalFileConfig(MultiLangFile, MultiLangCfg)
	end
	local LangSrcCfg = GetGlobalFileConfig(LangSrcFile)
	if not LangSrcCfg then
		LangSrcCfg = {}
		SetGlobalFileConfig(LangSrcFile, LangSrcCfg)
		print("init need trans------------------")
	end
	local CatStr = G_CurFileName or ""
	if G_IsRunChecker then
		CatStr = CatStr.."."..(G_CurColName or "")
	end
	-- 记录字符串
	LangSrcCfg[PattenStr] = CatStr
	local TargetStr = Str
	if TARGET_LANG then
		TargetLangCfg = MultiLangCfg[TARGET_LANG]				
		if TargetLangCfg then
			-- 进行转换
			local Patten = TargetLangCfg[PattenStr]
			if Patten then
				--TargetStr = FilterPatten2Str(Patten, Pm)
				TargetStr = Patten
			end
		end
	end
	return TargetStr
end

-- 生成需翻译语言包,xls文件
local ExlHeader = "string@ukey\tstring\tstring\nSrcStr\tCategory\tDestStr\n"
function MakeMultiLangFile(NoAuto)
	print("save need trans------------------")
	local LangSrcCfg = GetGlobalFileConfig(LangSrcFile)
	if not LangSrcCfg then return end
	-- 先保存所有语言数据
	TableSerialize(LangSrcCfg, LangSrcFile)
	local MultiLangCfg = GetGlobalFileConfig(MultiLangFile)
	for _, TargetLang in ipairs(ALL_LANGS) do
		local NeedTransList = {}
		local TargetLangInfo = MultiLangCfg and MultiLangCfg[TargetLang]
		for Src, Cat in pairs(LangSrcCfg) do
			if not TargetLangInfo or not TargetLangInfo[Src] then
				table.insert(NeedTransList,{string.format("%q",Src),Cat})
			end
		end
		-- 排序
		table.sort(NeedTransList, function(A,B) 
			if A[2] < B[2] then
				return true
			end
			if A[2] == B[2] then
				return A[1] < B[1]
			end
			return false
		end)
		local FileName = OUTPUTBASE.."language/nt_lang_"..TargetLang
		if not NoAuto and AutoConvertCfg[TargetLang] then
			AutoConvertMultiLang(TargetLang, NeedTransList, FileName)
		else
			local OutFile = io.open(FileName..".csv","w")
			OutFile:write(ExlHeader)	
			for _, Line in ipairs(NeedTransList) do
				OutFile:write(table.concat(Line,"\t").."\n")
			end
			OutFile:close()
		end
		-- 生成对应的xls文件
		os.execute("dist\\csv2xls.exe "..FileName..".csv "..FileName..".xls lang_"..TargetLang)	
		os.execute("del "..string.gsub(FileName,"/","\\")..".csv")
	end
end

-- 自动转换
function AutoConvertMultiLang(TargetLang, TransData, FileName)
	print("开始自动转换......",TargetLang)
	local TmpFile = io.open(FileName..".txt","w")
	for _, Line in ipairs(TransData) do
		TmpFile:write(Line[1].."\n")
	end
	TmpFile:close()
	os.execute("lua s2t.lua "..TargetLang.." "..FileName..".txt "..FileName.."_"..TargetLang..".txt")
	local List = {}
	local OutFile = io.open(FileName.."_"..TargetLang..".txt","r")
	for Line in OutFile:lines() do
		table.insert(List, Line)
	end
	OutFile:close()
	local FinalFile = io.open(FileName..".csv", "w")
	FinalFile:write(ExlHeader)
	for Idx, Line in ipairs(TransData) do
		FinalFile:write(Line[1].."\t"..Line[2].."\t"..List[Idx].."\n")
		--FinalFile:write(table.concat(Line,"\t").."\n")
	end
	FinalFile:close()
	os.execute("del "..string.gsub(FileName,"/","\\")..".txt")
	os.execute("del "..string.gsub(FileName,"/","\\").."_"..TargetLang..".txt")
	print("自动转换结束......",TargetLang)
end

local KeyChars = {"^","$","(",")",".","[","]","*","+","-","?"}
function ChangeKeyChars(Str)
	Str = string.gsub(Str, "%%","%%%%")
	for _, Char in ipairs(KeyChars) do
		Str = string.gsub(Str,("%"..Char),("%%"..Char))	
	end
	return Str
end

-- 识别和替换文本中需要多语言的关键字
function MultiFilter(Data)
	if not Data then return end
	local GetMsgList = {}
	local MsgList = {}
	for Msg in string.gmatch(Data,"GetMsg%(.-%)") do
--		local Key = string.gsub(Msg, "%%","%%%%")
--		Key = string.gsub(string.gsub(Key,"%(","%%("),"%)","%%)")
--		Key = string.gsub(Key, "%-","%%-")
		local Key = ChangeKeyChars(Msg)
		GetMsgList[Key] = CheckMultiLanguage(string.match(Msg,"GetMsg%(.(.+).%)"))
	end
	for Key, Msg in pairs(GetMsgList) do
		Data = string.gsub(Data, Key, string.format("%q",Msg))
	end
	for Msg in string.gmatch(Data,"Msg%(.-%)") do
		local Key = ChangeKeyChars(Msg)
		MsgList[Key] = CheckMultiLanguage(string.match(Msg,"Msg%(.(.+).%)"))
	end
	for Key, Msg in pairs(MsgList) do
		local TMsg = ChangeKeyChars(Msg)
		Data = string.gsub(Data, Key, TMsg)
	end
	return Data
end

-- 过滤提取中文
local ResCharTbl = {
	["，"] = true,
	["。"] = true,
	["“"] = true,
	["”"] = true,
	["！"] = true,
	["；"] = true,
	["："] = true,
}
function FilterStr2Patten(Str)
	if not Str then return end
	if Str == "" then return Str end
    local RetStr = ""
    local Len = string.len(Str)
    local i = 1
    local Rep
    local TempMap = {}
    local TmpStr = ""
    local RepCount = 1 
    while i <= Len do
        local Match = false
        local b = Str:byte(i)
        if b >= 224 and b <= 239 then
            local hb = Str:byte(i)*math.pow(2,16) + Str:byte(i+1)*math.pow(2,8) + Str:byte(i+2)
            local UChar = string.char(b, Str:byte(i+1),Str:byte(i+2))
            if (hb >= 0xE4B880 and hb <= 0xE9BEA0) or ResCharTbl[UChar] then
                RetStr = RetStr .. UChar
                i=i+2
                if Rep then
                    TempMap[Rep] = TmpStr
                    TmpStr = ""
                    Rep = nil 
                    RepCount = RepCount + 1 
                end 
                Match = true
            end 
        end 
        if not Match then
            if not Rep then
                Rep = "@"..RepCount.."@"
                RetStr = RetStr .. Rep 
            end 
            TmpStr = TmpStr..string.char(b)
        end 
        i=i+1
    end 
    if Rep then
        TempMap[Rep] = TmpStr
    end 
    return RetStr, TempMap
end

-- 模板转换目标字符串
function FilterPatten2Str(Patten, StrMap)
	return string.gsub(Patten, "(@%d-@)", StrMap or {})
end

-- 对每次出现的'简单'函数参数格式进行检查。
-- 所谓'简单'是指形如 Func(a, b, c) 的调用，而不支持括号中再包含括号：Func(a, (a or b), (2-1))
function ValidAllArgs(Maker, Str, FuncName, DataTypeList)
	assert(type(Maker) == "table" and type(Maker.MakeTable) == "function")
	assert(type(Str) == "string")
	assert(type(FuncName) == "string")
	assert(type(DataTypeList) == "table")
	MinArgsAmount = #DataTypeList -- 最少需要的参数数量
	
	for ArgsText in Utf8Gmatch(Str, "%#"..FuncName.."%(([^%(%)]+)%)") do
		-- 匹配每一个函数调用，并正则抽取参数列表到Args表
		ArgsText = string.gsub(ArgsText, " ", "")
		local Args = Split(ArgsText)
		if #Args < MinArgsAmount then
			return false, string.format("函数 [%s(%s)] 的参数个数必须不少于[%d]。",
				FuncName, ArgsText, MinArgsAmount)
		end
		
		-- 逐个Args参数调用对应的Validator函数进行判断
		for ArgIdx, DataType in ipairs(DataTypeList) do
			local IsOK, ErrMsg = Maker:CheckData(Args[ArgIdx], DataType)
			if IsOK == nil then
				return false, string.format("函数 [%s(%s)] 的第[%d]个参数不符合[%s]的要求。",
					FuncName, ArgsText, ArgIdx, DataType)
			end
		end

	end
	return true
end


-- 根据一个格式为
-- T = {
-- ["有BUFF"] = {"checker_name_1", "checker_name_2"},
-- ["减BUFF"] = {"checker_name_3", "checker_name_4"},
-- }
-- 的CheckConfig表来对API进行参数检查
function ValidScriptAPIByChecker(Maker, ScriptString, CheckerConfig)
	for FuncName, CheckerNameList in pairs(CheckerConfig) do
		local IsOK, ErrMsg = ValidAllArgs(Maker, ScriptString, FuncName, CheckerNameList)
		if not IsOK then
			return false, ErrMsg
		end
	end
	
	return true
end


----------------------------------------------------------------------
-- 不包含"/'符号的字符串持久化支持(这个持久特性在自动生成函数时候比较有用)
--
-- 比如：
-- 希望
--    local Str = "function (A, B) return A> B end"
-- 这个字符串在TableSeriazlie时不包含 " 符号地写入文件，
-- 可以使用 
--    Str = R(Str)
-- 执行上面一行代码后，TableSerialize将自动删除 " 符号，
-- 只写入：function (A, B) return A > B end
-- 
----------------------------------------------------------------------
local R_TAG = extra.reservedtag() --"@RESERVED"
function R(Str) -- R 表示 Reserved
	assert(type(Str) == "string")
	assert(not Str:find(R_TAG), "该字符串已经含有："..R_TAG)
	return R_TAG .. Str
end

-- 使用C语言版的serialize
Table2Str = extra.serialize

function TableSerialize(T, FilePath)
	FilePath = GetMultiLangPath(FilePath)
	if not FileExist(FilePath) then
		Mkdir(FilePath)
	end
	print(FilePath)
	local fh = io.open(FilePath, "w")
	assert(fh, FilePath)
	fh:write( "return \n" .. Table2Str(T) )
	fh:close()
end

---------------------------------------------------------------------------
-- 序列化为 as 文件
---------------------------------------------------------------------------

local MAX_LAYER = 20	-- 最大嵌套层数

local __LuaTable2AsString = nil

local function __ToString(v, Layer)
	local t = type(v)
	if(t == "table") then
		return __LuaTable2AsString(v, Layer + 1)
	elseif(t == "string") then
		if(string.sub(v, 1, string.len(R_TAG)) == R_TAG) then
			return string.sub(v, string.len(R_TAG) + 1)
		end
		return string.format('"%s"', v)
	elseif(t == "number") then
		return string.format('%s', v)
	elseif(t == "nil") then
		return 'nil'
	elseif(t == "boolean") then
		return v and 'true' or 'false'
	end
	error("错误的数据类型，不能转换为 as ！！！")
end

__LuaTable2AsString = function (Tbl, Layer)
	Layer = Layer or 1
	local SpaceList = {}
	for i = 1, Layer do
		table.insert(SpaceList, "")
	end
	local SpaceStr = table.concat(SpaceList, "\t")
	
	assert(type(Tbl) == "table")
	local StrList = {}
	for k, v in pairs(Tbl) do
		table.insert( StrList, string.format("%s%s:%s",SpaceStr,__ToString(k),__ToString(v, Layer)) )
	end
	return "{\n"..table.concat(StrList,",\n").."}"
end

local AS_TEMPLATE = [[
package <%PACKAGE_NAME%>
{
	public class <%CLASS_NAME%> extends Object
	{
<%CONST_VAR%>
<%GET_FUNCS%>
<%CUSTOM_FUNC%>
		public static function getData():Object
		{
			return <%CLASS_NAME%>.Data;
		}

		public static var Data:Object = <%CONTENT%>;
	}
}
]]
local AS_GET_FUNC_TEMPLATE = [[
		public static function get<%FUNC_NAME%>(Key:<%TYPE%>):<%RET_TYPE%>
		{
			return <%CLASS_NAME%>.Data.<%FUNC_NAME%>[Key];
		}
]]
local AS_CONST_VAR_TEMPLATE = [[
		public static const <%CONST_NAME%>:<%TYPE%>=<%CONST_VAL%>;
]]
local AS_CUSTOM_FUNCTION = [[
]]
local TYPE2AS_TYPE = {
	["string"] = "String",
	["table"] = "Object",
	["number"] = "int",
	["boolean"] = "Boolean",
}
function LuaTable2AsSerialize(T, FilePath, NeedGetFunc, CustomFuncs)
	-- 拆分路径，获取 package 路径
	local FilePath = string.gsub(FilePath, "\\", "/")
--	local PackageList = Split(FilePath, "/")
--	local ClassName = PackageList[#PackageList]
--	PackageList[#PackageList] = nil
--	--------------------------------
--	-- 【hard code】：去掉第一个路径
--	table.remove(PackageList, 1)
	--------------------------------
	local PackageName = string.gsub(string.gsub(FilePath,".*/asclient/(.+)/.-%..*$","%1"),"/",".") 
	PackageName = string.gsub(PackageName,"^setting","config")
	-- 去掉语言相关头
	if TARGET_LANG then
		PackageName = string.gsub(PackageName,"%."..TARGET_LANG.."$","")
	end
	--table.concat(PackageList, ".")
	--assert(string.find(ClassName, ".as"), ClassName)
	local ClassName = string.gsub(FilePath,".*/asclient/.+/(.-)%..*$","%1")
	
	local Output = AS_TEMPLATE
	Output = string.gsub(Output, "%<%%".."PACKAGE_NAME".."%%%>", PackageName)
	Output = string.gsub(Output, "%<%%".."CLASS_NAME".."%%%>", ClassName)
	
	if T.CONST_VAR then
		local ConstStr = AS_CONST_VAR_TEMPLATE
		local ConstTbl = {}
		for ConstName, ConstVal in pairs(T.CONST_VAR) do
			local Const = string.gsub(ConstStr, "%<%%[%w_]+%%%>", {
				["<%CONST_NAME%>"] = ConstName,
				["<%TYPE%>"] = TYPE2AS_TYPE[type(ConstVal)],
				["<%CONST_VAL%>"] = __ToString(ConstVal,4),
			})
			table.insert(ConstTbl, Const)
		end
		Output = string.gsub(Output,"%<%%CONST_VAR%%%>",table.concat(ConstTbl,"\n"))
	else
		Output = string.gsub(Output, "%<%%".."CONST_VAR".."%%%>","")
	end

	T.CONST_VAR = nil

	if NeedGetFunc then
		local FuncStr = AS_GET_FUNC_TEMPLATE
		local FuncTbl = {}
		for Key, Val in pairs(T) do
			local SubKey,SubVal = next(Val)
			if SubKey then
				local GetFunc = string.gsub(FuncStr,"%<%%".."FUNC_NAME".."%%%>",Key)
				assert(type(Val)=="table")
				GetFunc = string.gsub(GetFunc,"%<%%".."TYPE".."%%%>", TYPE2AS_TYPE[type(SubKey)])
				GetFunc = string.gsub(GetFunc,"%<%%".."RET_TYPE".."%%%>", TYPE2AS_TYPE[type(SubVal)])
				GetFunc = string.gsub(GetFunc,"%<%%".."CLASS_NAME".."%%%>", ClassName)
				table.insert(FuncTbl,GetFunc)
			end
		end
		Output = string.gsub(Output,"%<%%".."GET_FUNCS".."%%%>",table.concat(FuncTbl,"\n"))
	else
		Output = string.gsub(Output,"%<%%".."GET_FUNCS".."%%%>", "")
	end
	if CustomFuncs then
		if type(CustomFuncs) == "table" then
			Output = string.gsub(Output,"%<%%".."CUSTOM_FUNC".."%%%>", table.concat(CustomFuncs, "\n"))
		else
			Output = string.gsub(Output,"%<%%".."CUSTOM_FUNC".."%%%>", CustomFuncs)
		end
	else
		Output = string.gsub(Output,"%<%%".."CUSTOM_FUNC".."%%%>", "")
	end
	Output = string.gsub(Output, "%<%%".."CONTENT".."%%%>", __LuaTable2AsString(T, 4))

	FilePath = GetMultiLangPath(FilePath)
	if not FileExist(FilePath) then
		Mkdir(FilePath)
	end
	print(FilePath)
	local fh = io.open(FilePath, "w")
	assert(fh, FilePath)
	fh:write( Output )	-- 统一用 utf8 编码输出
	fh:close()
end

---------------------------------------------------------------------------
-- 序列化为 json 文件
---------------------------------------------------------------------------
local __LuaTable2JsonString = nil
local function __ToJsonString(v, Layer)
	local t = type(v)
	if(t == "table") then
		return __LuaTable2JsonString(v, Layer + 1)
	elseif(t == "string") then
		if(string.sub(v, 1, string.len(R_TAG)) == R_TAG) then
			return string.sub(v, string.len(R_TAG) + 1)
		end
		return string.format('"%s"', v)
	elseif(t == "number") then
		return string.format('"%s"', v)
	elseif(t == "nil") then
		return 'nil'
	elseif(t == "boolean") then
		return t and 'true' or 'false'
	end
	error("错误的数据类型，不能转换为 as ！！！")
end

__LuaTable2JsonString = function (Tbl, Layer)
	Layer = Layer or 1
	local SpaceList = {}
	for i = 1, Layer do
		table.insert(SpaceList, "")
	end
	local SpaceStr = table.concat(SpaceList, "\t")
	
	assert(type(Tbl) == "table")
	local StrList = {}
	for k, v in pairs(Tbl) do
		table.insert( StrList, string.format("%s%s:%s",SpaceStr,__ToJsonString(k),__ToJsonString(v, Layer)) )
	end
	return "{\n"..table.concat(StrList,",\n").."}"
end

function LuaTable2JsonSerialize(T, FilePath)
	-- json配置不在多语言中输出
	if TARGET_LANG then return end
	local FilePath = string.gsub(FilePath, "\\", "/")
	local Output = __LuaTable2JsonString(T,1)
	print(FilePath)
	local fh = io.open(FilePath, "w")
	assert(fh, FilePath)
	fh:write(Output)	-- 统一用 utf8 编码输出
	fh:close()
end

---------------------------------------------------------------------------
--将一个str以sep分割为若干个table中的元素,默认分隔符为','。
--n为分割次数
--默认地,table中的元素将被自动删除所有空白符号。
---------------------------------------------------------------------------
function SafeSplit(line)
	-- 全角字符检查
	if Utf8Find(line, '，') then
		return nil, "Split错误：["..line.."]出现全角字符[，]"
	end
	
	return Split(line, ",")
end

function Split( line, sep, delblanks, maxsplit) 
	if string.len(line) == 0 then
		return {}
	end
	
	sep = sep or ','
	if delblanks == nil then
		delblanks = true -- default
	else
		assert(type(delblanks) == "boolean")
	end

	maxsplit = maxsplit or 0
	local retval = {}
	local pos = 1   
	local step = 0
	while true do   
		local from, to = string.find(line, sep, pos, true)
		step = step + 1
		if (maxsplit ~= 0 and step > maxsplit) or from == nil then
			local item = string.sub(line, pos)
			if delblanks then
				item = item:gsub("%s", "")
			end
			table.insert( retval, item )
			break
		else
			local item = string.sub(line, pos, from-1)
			if delblanks then
				item = item:gsub("%s", "")
			end
			table.insert( retval, item )
			pos = to + 1
		end
	end     
	return retval  
end

function SplitHasBlank( line, sep, delblanks, maxsplit) 
	if string.len(line) == 0 then
		return {}
	end
	
	sep = sep or ','
	if delblanks == nil then
		delblanks = true -- default
	else
		assert(type(delblanks) == "boolean")
	end

	maxsplit = maxsplit or 0
	local retval = {}
	local pos = 1   
	local step = 0
	while true do   
		local from, to = string.find(line, sep, pos, true)
		step = step + 1
		if (maxsplit ~= 0 and step > maxsplit) or from == nil then
			local item = string.sub(line, pos)
			table.insert( retval, item )
			break
		else
			local item = string.sub(line, pos, from-1)
			table.insert( retval, item )
			pos = to + 1
		end
	end     
	return retval  
end



----------------------------------------------------------------------
-- 将一个数组转换成一个集合
----------------------------------------------------------------------
function ListToSet(List)
	assert(type(List) == "table")
	local Set = {}
	for _, V in ipairs(List) do
		if Set[V] then
			print("错误：集合中出现了重复的元素值["..V.."]")
			return nil
		end
		
		Set[V] = true
	end
	
	return Set
end

----------------------------------------------------------------------
-- 尝试获取Maker头部所有的连续注释行
----------------------------------------------------------------------
function GetMakerDesc(MakerFile)
	local Ofh, ErrMsg = io.open(MakerFile, "r")
	if not Ofh then
		return
	end
	
	local DescTable = {}
	for line in Ofh:lines() do
		if string.find(line, "%-%-") == 1 then
			table.insert(DescTable, line)
		else
			break
		end
	end
	
	Ofh:close()
	return table.concat(DescTable, "\n")
end

----------------------------------------------------------------------
-- 帮助生成整个函数代码的类
----------------------------------------------------------------------
clsFunctionFormatter = clsObject:Inherit()

--init
function clsFunctionFormatter:__init__()
	self.__Name = ""
	self.__ParamList = {}
	self.__LineList = {}
	self.__ReturnType = "void"
end

function clsFunctionFormatter:SetName(Name)
	assert(type(Name) == "string", 
		"SetName函数的参数类型必须是字符串，你传入了:"..type(Name))
	self.__Name = Name
end

function clsFunctionFormatter:SetReturnType(Rt)
	self.__ReturnType = Rt
end

function clsFunctionFormatter:AddParam(Param)
	assert(type(Param) == "string",
		"AddParam函数的参数类型必须是字符串，你传入了:"..type(Line))
	table.insert(self.__ParamList, Param)
end


function clsFunctionFormatter:AddLine(Line)
	assert(type(Line) == "string", 
		"AddLine函数的参数类型必须是字符串，你传入了:"..type(Line))
	
	Line = Line:gsub("\r", "")
	local Lines = Split(Line, "\n", false)
	for _, RealLine in ipairs(Lines) do
		table.insert(self.__LineList, RealLine)
	end
end


function clsFunctionFormatter:Dump(NeedReserved)
	if NeedReserved == nil then
		NeedReserved = true
	end

	local BlockParam = table.concat(self.__ParamList, ", ")
	local BlockHeader = "function "..self.__Name.."("..BlockParam..")"
	local BlockBody = "\t"..table.concat(self.__LineList, "\n\t")
	local BlockEnd = "end"
	
	local StrTable = {
		BlockHeader,
		BlockBody,
		BlockEnd,
	}
	
	if NeedReserved then
		return R( table.concat(StrTable, "\n") )
	else
		return table.concat(StrTable, "\n")
	end
end

function clsFunctionFormatter:DumpAs(NeedReserved)
	if NeedReserved == nil then
		NeedReserved = true
	end

	local BlockParam = table.concat(self.__ParamList, ", ")
	local BlockHeader = string.format("function %s(%s):%s{",
		self.__Name, BlockParam, self.__ReturnType)
	--local BlockBody = "\t"..table.concat(self.__LineList, "\n\t")
	local BlockBody = ""
	local BlockEnd = "}"
	local StrTable = { BlockHeader, BlockBody, BlockEnd, }
	
	if NeedReserved then
		return R( table.concat(StrTable, "\n") )
	else
		return table.concat(StrTable, "\n")
	end
end

function F()
	return clsFunctionFormatter:New()
end

-- 所有全角的符号
local FullChars = {
	["＋"]="+",
	["－"]="-",
	["×"]="*",
	["／"]="/",
	["％"]="%",

	
	["～"]="~",
	["＝"]="=",
	["："]=":",
	["》"]=">",
	["《"]="<",
	
	["（"]="(",
	["）"]=")",
	["【"]="[",
	["】"]="]",
	["｛"]="{",
	["｝"]="}",
	
	["＃"]="#",
	["＠"]="@",
	["——"]="_",
	["！"]="!",
	["？"]="?",
	["｜"]="|",
	
	["“"]='"',
	["‘"]="'",
	["’"]="'",
	["；"]=";",
	["，"]=",",
	["。"]=".",
	["＆"]="&",
}

---------------------------------------------------------------------------
-- 检查文档字符串Data内容是否符合Lua语法
-- 参数：
-- (1) Data：文档字符串
-- (2) NeedAddReturn：是否需要额外return Data字符串
--
-- 实现：
-- 本实现是做了四种简单的替换，暂能保证现有约定下的语法正确性：
-- (1)替换对象名 为 统一对象名：Obj
-- (2)替换算子名 为 统一算子名：Call
-- (3)替换属性名 为 统一取属性函数名：GetValue
-- (4)替换集合名的展开 为 统一的硬编码：((GetValue() and GetValue()) and 1 or 0)
-- (5)经过以上处理后，还不存在的变量定义将由FuncEnv.mt.__index控制统计返回数值 1
---------------------------------------------------------------------------
-- 预定义函数执行环境
_ValidLuaFuncEnv = {
	-- self
	Self = {Dmg=1},
	Ext = {Dmg=1},

	-- 定义GetValue
	GetValue = function () return 1 end,
	
	-- 定义Obj和Obj:GetValue()
	Obj = { GetValue = function () return 1 end,
		GetPid = function() return 1 end,
	},
	
	-- 定义空的Call函数
	--之前只是返回一个数值性值1,这里为了实现部分放回table型的，而加了返回第二个参数，自然API编写，真正的返回值也只能写在第2个返回值了,第一个返回值为table的长度
	Call = function () return 1,{} end,
	
	-- 所有不存在的变量返回1
	mt = {__index = function (Table, Key)
			local From, To, Matched = string.find(Key, "arg", 1, true)
			if From == 1 then
				return
			end
--				print("语法检查信息：测试类型时，需要的变量名[" .. Key .. "]不存在，返回 1 代替")
			return 1
		end						
		},
	math = math,
}
setmetatable(_ValidLuaFuncEnv, _ValidLuaFuncEnv.mt)


function ValidLua(Data, NeedAddReturn)
	local NeedAddReturn = NeedAddReturn or false

	local Str = tostring(Data)
	if Str:find("return") then
		NeedAddReturn = false
	end
	
	-- 查找所有全角字符
	for fullchar, halfchar in pairs(FullChars) do
		local Found = Utf8Find(Str, fullchar)
		if Found then
			return nil, "出现了全角字符：["..fullchar.."]"
		end
	end
	
	Data = Str -- 覆盖原Data

	-- 预填充前空格，方便替换对象
	-- 替换对象：将所有"xx:" 替换成 "Obj:"
	local LuaIgnoresStr = table.concat(LuaIgnores, "%")
	local LuaIgnoresPattern = "([^%s" .. LuaIgnoresStr .. "]+)"
	local Pattern = LuaIgnoresPattern.."%:"
	Str = string.gsub(Str, Pattern, "Obj:")

	-- 替换函数
	Str = ReplaceAllToOne(Str, TagCall, "Call")
	-- 替换属性接口
	Str = ReplaceAllToOne(Str, TagAttr, "GetValue()")
	-- 替换集合
	Str = ReplaceAllToOne(Str, TagSet, "((GetValue() and GetValue()) and 1 or 0)")

	local FinalStr = Str
	if NeedAddReturn then
		FinalStr = " return " .. FinalStr
	end

	-- 粘连PreCode构成完整的测试代码
	local Func, ErrMsg = loadstring(FinalStr)
	if not Func then
		print("原语句：["..Data.."]")
		print("格式化尝试：["..Str.."]")
		print("错误信息：" .. ErrMsg)
		return nil
	end

	-- 开始测试执行过程
	-- 设置环境
	setfenv(Func, _ValidLuaFuncEnv)
	local function _ValidLuaErr(ErrorObj)
		print("原语句：["..Data.."]")
		print("格式化尝试：["..Str.."]")
		print("错误信息：" .. tostring(ErrorObj))
	end
	local Result = xpcall(Func, _ValidLuaErr)
	if Result then -- 通过语法检查，返回原字符串
		return Data
	else
		return nil
	end
end

---------------------------------------------------------------------------
-- Tag不可以是任何的Lua符号
-- 如 # @ ! ? ; | { } _ 等
---------------------------------------------------------------------------
TagAttr = "%_" --宠物属性前缀 -- non-alphanumeric need %
TagSet = "%$" --公式集合前缀
TagCall = "%#" --函数调用前缀

---------------------------------------------------------------------------
-- 供具体的maker在完成所有Replace操作后的assert
---------------------------------------------------------------------------
function AssertScript(S, FuncAssert)
	FuncAssert = FuncAssert or assert

	FuncAssert(type(S) == "string", 
		"本函数只接受字符串类型的参数，当前参数类型为:"..type(S))

	-- 首先，不允许有 TagAttr, TagSet, TagCall 的出现
	local Idx, EndIdx = S:find(TagAttr)
	FuncAssert(Idx == nil, 
		"脚本字符串["..S.."]的第["..tostring(Idx).."]个字符处发现未能转换的 属性！")
	
	Idx, EndIdx = S:find(TagCall)
	FuncAssert(Idx == nil, 
		"脚本字符串["..S.."]的第["..tostring(Idx).."]个字符处发现未能转换的 函数调用！")	

	Idx, EndIdx = S:find(TagSet)
	FuncAssert(Idx == nil, 
		"脚本字符串["..S.."]的第["..tostring(Idx).."]个字符处发现未能转换的 $标志未展开！")	
	
	return S
end

---------------------------------------------------------------------------
-- 替换属性
---------------------------------------------------------------------------
function ReplaceAttr(Str, Map)
	return Replace(Str, TagAttr, Map)
end


---------------------------------------------------------------------------
-- 替换集合
---------------------------------------------------------------------------
function ReplaceSet(Str, Map)
	return Replace(Str, TagSet, Map)
end


---------------------------------------------------------------------------
-- 替换函数
---------------------------------------------------------------------------
function ReplaceCall(Str, Map)
	return Replace(Str, TagCall, Map)
end

---------------------------------------------------------------------------
-- 替换所有匹配子字符串为 固定字符串
---------------------------------------------------------------------------
function ReplaceAllToOne(Str, Tag, TheString)
	local Map = {
		mt = {__index = function (Table, Key) return TheString end},
	}
	setmetatable(Map, Map.mt)
	return Replace(Str, Tag, Map)
end

---------------------------------------------------------------------------
-- 本函数提供的功能很简单：
-- 将某个字符串里面所有符合如下规则：
-- (1)以指定【开始字符】（如'_'）开始
-- (2)从【开始字符】后最长匹配Lua命名规则
-- 的【子字符串】进行替换。
--
-- 为了进行替换，
-- 必须提供一个以SrcStr（源字符串）为Key，DstStr（目标字符串）为Value的Table。
--
-- 例如：
-- local Str = "#算子名(OP:_生命 * 100 + TP:_攻击 * 40)"
-- local Prefix = "%_"
-- local Map = {["生命"]="GetHp()", ["攻击"]="GetAk()"}
-- Str = Replace(Str, Prefix, Map)
--
-- 上述代码执行后，Str为："#算子名(OP:GetHp() * 100 + TP:GetAk() * 40)"
-- 
---------------------------------------------------------------------------

LuaIgnores = {
	"+", "-", "*", "/", "%",
	"~", "=", ":", ">", "<", "^",
	"(", ")", "[", "]", "{", "}",
	"#", "@", "!", "?", "|", "$",
	'"', "'", ";", ",", ".", "&",
	"_", -- 特殊地，我们不允许文档中出现包含 '_', '-' 的命名 -_-|
}

function Replace(Str, Prefix, Map)
	local LuaIgnoresStr = table.concat(LuaIgnores, "%")
	local LuaIgnoresPattern = "([^%s" .. LuaIgnoresStr .. "]+)" --%s忽略所有空符
	local Pattern = Prefix .. LuaIgnoresPattern

--	local function TestPrint(S) print("gsub [" .. S .. "]") end
--	string.gsub(Str, Pattern, TestPrint) -- 日志打印

	local Rstr, Matchs = string.gsub(Str, Pattern, Map)
	return Rstr
end

function GetMatchNames(Str, Prefix)
	local RetNames = {}
	local LuaIgnoresStr = table.concat(LuaIgnores, "%")
	local LuaIgnoresPattern = "([^%s" .. LuaIgnoresStr .. "]+)" --%s忽略所有空符
	local Pattern = Prefix .. LuaIgnoresPattern

	for Name in string.gmatch(Str, Pattern) do
		table.insert(RetNames,Name)
	end
	return RetNames
end


function ReplacePair(Str, Prefix, Map)
	local Rstr, Matchs = string.gsub(Str, Prefix.."(.-)"..Prefix, Map)
	return Rstr
end

output_value = function(value)
	if not value and not type(value) == "boolean" then return nil end
	local str, value_type
	value_type = type(value)
	if value_type == "number" then
		str = string.format("[ %s ]n", value)
	elseif value_type == "string" then
		str = string.format("[ \"%s\" ]s", value)
	elseif value_type == "table" then
		str = string.format("[ 0x%s ]t", string.sub(tostring(value), 8))
	elseif value_type == "function" then
		str = string.format("[ 0x%s ]f", string.sub(tostring(value), 11))
	elseif value_type == "userdata" then
		str = string.format("[ 0x%s ]u", string.sub(tostring(value), 11))
	else
		str = string.format("[ S\"%s\" ]%s", tostring(value), type(value))
	end
	return str
end

table.print = function(t, tname, print_one_level)
	if type(t) ~= "table" then
		return
	end

	local _deep_count = 0
	local print_one_table
	local max_deep = deep or 10
	local printed_tables = {}
	local t_path = {}
	tname = tname or "root_table"
	print_one_table = function(tb, tb_name, print_one_level)
		tb_name = tb_name or "table"
		table.insert(t_path, tb_name)
		local tpath, i, tname = ""
		for i, pname in pairs(t_path) do
			tpath = tpath .. "." .. pname
		end
		printed_tables[tb] = tpath
		_deep_count = _deep_count + 1
		local k, v, str
		local tab = string.rep(" ", _deep_count*4)
		print(string.format("%s {", tab))
		for k,v in pairs(tb) do
			if type(v) == "table" then
				if printed_tables[v] then
					str = string.format("%s    %s = [ %s ]t", tab, output_value(k), printed_tables[v])
					print(str)
				elseif not print_one_level then
					str = string.format("%s    %s = ", tab, output_value(k))
					print(str)
					print_one_table(v, tostring(k))
				else
					str = string.format("%s    %s = %s", tab, output_value(k), output_value(v))
					print(str)
				end
			else
				str = string.format("%s    %s = %s", tab, output_value(k), output_value(v))
				print(str)
			end
		end
		print(tab.."  }")
		table.remove(t_path)
		_deep_count = _deep_count - 1
	end
	print_one_table(t, tname, print_one_level)
	printed_tables = nil
end

table.deep_clone = function(src)
	if type(src) ~= "table" then return src end

	local copy_table
	local level = 0
	local function clone_table(t)
		level = level + 1
		if level>20 then
			error("table clone failed, source table is too deep!")
		end
		local k,v
		local ret = {}
		for k,v in pairs(t) do
			if type(v) == "table" then
				ret[k] = clone_table(v)
			else
				ret[k] = v
			end
			level = level -1			
		end
		return ret
	end
	return clone_table(src)
end

table.clone = function(src)
	local rel = {}
	if type(src) ~= "table" then
		return rel
	end
	
	for k,v in pairs(src) do
		rel[k] = v
	end
	return rel
end

table.size = function(Tbl)
	local Cnt = 0
	for _,_ in pairs(Tbl) do
		Cnt = Cnt + 1
	end
	return Cnt
end

table.member_key = function(Table, Value)
	for k,v in pairs(Table) do
		if v == Value then
			return k
		end
	end

	return nil
end


function ParseAtr(Sheet)    
    local Table = {}
	local ToClient = {}
    for RowIdx = 1, Sheet:GetRowCount() do    
        local Row = Sheet:Row(RowIdx)
        local CnName = Sheet:ColDesc(1)         
        assert(CnName, string.format("错误的表格格式，#%s 缺少名称定义", CnName))
        local EnName = Sheet:ColDesc(2)
        assert(EnName, "错误的列名称"..CnName.."，必须为定义好的属性名")
		local ToClientName = Sheet:ColDesc(3)
        Table[Row[CnName]] = Row[EnName]
		ToClient[Row[CnName]] = Row[ToClientName]
    end
    
    return Table, ToClient
end
