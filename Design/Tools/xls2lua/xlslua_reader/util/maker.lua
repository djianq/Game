--class type init
clsMakerBase = clsObject:Inherit()

--init
function clsMakerBase:__init__(InputFile, OutputFile, Key)
	local PrevClock = os.clock()
	Super(clsMakerBase).__init__(self)
	Log("[开始转换][%s]", __U8T(InputFile))
	
	self.InputFile = InputFile
	self.OutputFile = OutputFile
	
	self.Key = Key
	self._TableGroup = LoadTableGroupFromFile(InputFile)
	if self._TableGroup.__SheetOrder then
		self.SheetOrder = self._TableGroup.__SheetOrder["A"]
		table.remove(self.SheetOrder, 1) -- del "string" type
	else
		self.SheetOrder = nil
	end
	
	-- 支持一个maker中共享同一个Checker池，绝对满足需求了，跨maker则不应该共享
	self.CheckerPool = {}
	self.SheetGroup = {}
	for SheetName, TableObj in pairs(self._TableGroup) do
		if SheetName ~= "__SheetOrder" then -- ignore sheetorder table
			-- 注意：TableObj用过一次后就不能再用了，因为数据类型被替换了
			local SheetX = clsSheetX:New(SheetName, TableObj, self)
			if SheetX.IsReady then -- 有可能需要丢弃
				self.SheetGroup[SheetName] = SheetX
			end
		end
	end

	self.TableSerialize = self:GetTableSerialzeFunc()

	self.Times = {Load=0, Convert=0, Save=0, Total=0}
	-- 计算加载InputFile的耗时
	self.Times.Load = os.clock() - PrevClock
end


function clsMakerBase:CheckData(Data, DataType)
	local Checker = self.CheckerPool[DataType]
	if not Checker then
		Checker = LoadFunctionFromFile("xlslua_reader/checker/"..DataType..".lua")
		self.CheckerPool[DataType] = Checker
	end
	G_IsRunChecker = true	
	local Ret, Msg = Checker(Data)
	G_IsRunChecker = false	
	return Ret, Msg
end

function clsMakerBase:GetTableSerialzeFunc()
	return TableSerialize
end

--[[
-- 统一使用common里面的GetFileConfigGBK
function clsMakerBase:GetFileConfig(Path)
	local f = io.open(Path, "r")
	if not f then
		return nil
	end
	f:close()
	return dofile(Path)
end

function clsMakerBase:GetFileConfigGBK(Path)
	local f = io.open(Path,"r")
	if not f then
		return nil
	end
	local FStr = __A(f:read("*a"))
	f:close()
	return loadstring(FStr)()
end
--]]

function clsMakerBase:GetSheetOrder()
	assert(self.SheetOrder, 
		"你指定的["..__U8T(self.InputFile).."]中没有表名顺序信息，请使用新版xls2lua.exe")
	return self.SheetOrder
end

--make output
function clsMakerBase:Make()
	-- 计算出转换后的最终table
	local PrevClock = os.clock()
	local FinalTable, Flag = self:MakeTable()
	self.Times.Convert = os.clock() - PrevClock
	
	-- 序列化这个table
	PrevClock = os.clock()
	self.TableSerialize(FinalTable, self.OutputFile, Flag)
	self.Times.Save = os.clock() - PrevClock
	
	-- 计算总耗时
	self.Times.Total = self.Times.Load + self.Times.Convert + self.Times.Save
	
	-- 打印日志返回
	Log("[完成转换(%.02f秒)](加载/转换/存盘: %.02f/%.02f/%.02f)[%s]---成功转换到<OUTPUTSUCCEED>--->[%s]\n\n", 
		self.Times.Total, self.Times.Load, self.Times.Convert, self.Times.Save, 
		__U8T(self.InputFile), __U8T(self.OutputFile))
		
	return self.Times
end

--make table
function clsMakerBase:MakeTable()
	error("派生类必须重写本函数")
end

-- 按指定格式提取指定sheet的内容并以table返回
function clsMakerBase:FetchSheetTable(SheetName, TblFormat, KeyName)
	local Sheet = self.SheetGroup[SheetName]
	assert(Sheet, "无法找到指定的Sheet，FetchSheetTable"..SheetName..KeyName) 
	local Rel = {}
	for RowIdx, Row in Sheet:Rows() do
		local SubTbl= {}
		local Key = Row[KeyName]
		Sheet:Assert(Key, "无法找到指定的Sheet，FetchSheetTable的KEY name:"..KeyName)
		Rel[Key] = SubTbl
		for AtrVar, AtrName in pairs(TblFormat) do
			SubTbl[AtrVar] = Row[AtrName]			
		end
	end
	return Rel
end

function clsMakerBase:TransMap(Idx)
	local NewMap = {}
	for _,Info in ipairs(self:GetMapAttrPredef(Idx)) do
		if Info and type(Info)=="table" then
			NewMap[Info[1]] = Info[2]
		end
	end
	return NewMap
end

function clsMakerBase:InitMapAttrPredef()
	--[[
	{[1] = 
		{
			{"人物等级", "UserLevel"},
		}
	}
	{[1] = 
		[0] = {"User"},
		{
			{"人物等级", "UserLevel"},
		}
	}
	--]]
	return {}
end

function clsMakerBase:GetMapAttrPredef(Idx)
	return self:InitMapAttrPredef()[Idx]
end

function clsMakerBase:ToScript_RuleSheet(Str, RowIdx, Idx)
	if not self.MathMap then
		self.MathMap = {}
		for Name, _ in pairs(math) do
			self.MathMap[Name] = "math."..Name
		end
	end

	Str = ReplaceAttr(Str, self:TransMap(Idx)) -- 预定义参数
	Str = Replace(Str,"%#", self.MathMap)	
	local FuncStr,RepCount = string.gsub(Str,";",",")
	assert(RepCount < 2,"公式计算以‘；’分割，最大只能支持两个公式，所在行："..RowIdx)
	-- 自动加上return
	if not string.find(FuncStr, "return") then
		FuncStr = "return " .. FuncStr
	end

	AssertScript(FuncStr)

	local Func = F()
	for _, Info in ipairs(self:GetMapAttrPredef(Idx)) do
		if Info and type(Info)=="table" then
			Func:AddParam(Info[2])
		end
	end

	Func:AddLine(FuncStr)
	return Func:Dump()
end

function clsMakerBase:ToScript_RuleSheet2(Str, RowIdx, Idx)
	if not self.MathMap then
		self.MathMap = {}
		for Name, _ in pairs(math) do
			self.MathMap[Name] = "math."..Name
		end
	end

	Str = ReplaceAttr(Str, self:TransMap(Idx)) -- 预定义参数
	Str = Replace(Str,"%#", self.MathMap)	
	local FuncStr,RepCount = string.gsub(Str,";",",")
	assert(RepCount < 2,"公式计算以‘；’分割，最大只能支持两个公式，所在行："..RowIdx)
	-- 自动加上return
	if not string.find(FuncStr, "return") then
		FuncStr = "return " .. FuncStr
	end

	AssertScript(FuncStr)

	local Func = F()
	for _, Param in ipairs(self:GetMapAttrPredef(Idx)[0]) do		
		Func:AddParam(Param)
	end

	Func:AddLine(FuncStr)
	return Func:Dump()
end

function clsMakerBase:ParseAPI(Sheet, SheetName, APIMap, ...)
	local Params = {...}
	-- 服务器API库
	local Output = {}
	local AfterOutPut = {}
	for RowIdx = 1, Sheet:GetRowCount() do
		local ErrHead = string.format("[%s]第%d行错误，",SheetName, RowIdx + 2)
		local Row = Sheet:Row(RowIdx)
		
		local Name = assert(Row["API名称"])
		local APIName = Name
		
		if not Row["嵌套API"] then
			assert(not APIMap[APIName], ErrHead.."重复API名称："..tostring(Name))
			Output[RowIdx], APIMap[APIName] = self:Func(Row["执行代码"], ...)
			APIMap[APIName] = string.format(APIMap[APIName], RowIdx)
		end
	end
	
	for RowIdx = 1, Sheet:GetRowCount() do
		local ErrHead = string.format("[%s]第%d行错误，",SheetName, RowIdx + 2)
		local Row = Sheet:Row(RowIdx)
		
		local Name = assert(Row["API名称"])
		local APIName = Name
		
		if Row["嵌套API"] then
			assert(not APIMap[APIName], ErrHead.."重复API名称："..tostring(Name))
			Output[RowIdx], APIMap[APIName] = self:GetAPIFunc(Row["执行代码"], APIMap, ...)
			APIMap[APIName] = string.format(APIMap[APIName], RowIdx)
		end
	end
	
	return Output
end

function clsMakerBase:Func(Code, ...)
	local Params = {...}
	local f = F()
	f:AddParam("API")
	local Str = ""
	for _,v in ipairs(Params) do
		f:AddParam(v)
		Str = Str .. v .. ","
	end		
	f:AddParam("...")
		
	local Formula = assert(Code)
	Formula = string.gsub(Formula, "([aA][rR][gG])(%d+)", "Args[%2]")

	assert(loadstring(Formula))
	f:AddLine("local Args = {...} "..Formula)
	Str = "API[%d](API," .. Str
	
	return f:Dump(), Str
end

function clsMakerBase:GetAPIFunc(Str, APIMap, ...)
	local Params = {...}
	Str = Replace(Str, "%#", APIMap) -- 替换API函数
	Str = string.gsub(Str, ",%(%)", ")") -- 注意：这里的替换与上面 ParseServerAPI 的 function 格式密切相关

	Str = string.gsub(Str, ",%(", ", ")
	Str = string.gsub(Str, "([aA][rR][gG])(%d+)", "Args[%2]")

	assert(not string.find(Str, "%$"), string.format("格式转换失败：%s",tostring(Str)))
	assert(not string.find(Str, "%#"), string.format("格式转换失败：%s",tostring(Str)))
	
	local f = F()
	f:AddParam("API")
	local RetStr = ""
	for _,v in ipairs(Params) do
		f:AddParam(v)	
		RetStr = RetStr .. v .. ","		
	end		
	f:AddParam("...")
	f:AddLine("local Args = {...} "..Str)

	return f:Dump(), "API[%d](API," .. RetStr
end

function clsMakerBase:MergeTable(TSheetName, SheetNameFmt, KeyName, KeyName2)
	-- 合并配置表
	local TableObj = {}
	local Counter = 2
	local TargetSheet
	for SN, _ in pairs(self.SheetGroup) do
		if string.match(SN, SheetNameFmt) then
			local Sheet = self.SheetGroup[SN]
			local RowCount = Sheet:GetRowCount()
			if not TargetSheet then TargetSheet = Sheet end
			for ColIdx, ColTable in pairs(Sheet.Table) do
				if not TableObj[ColIdx] then TableObj[ColIdx] = {} end
				-- ignore col head
				if not TableObj[ColIdx][1] then
					TableObj[ColIdx][1] = ColTable[1]
					TableObj[ColIdx][2] = ColTable[2]
				end
				assert(TableObj[ColIdx][1] == ColTable[1] and
					TableObj[ColIdx][2] == ColTable[2], SheetNameFmt.."必须有一样的表头 ，"..SN.." "..ColTable[2].." 和 "..TableObj[ColIdx][2].." 属性不一致")

				for RowIdx = 1, RowCount do
					TableObj[ColIdx][Counter + RowIdx] = ColTable[RowIdx+2]
				end
			end
			Counter = Counter + RowCount
		end
	end

	TargetSheet.Table = TableObj
	self.SheetGroup[TSheetName] = TargetSheet

	local UniqueMap = {}
	for Index, UniqueKey in ipairs(TargetSheet:Col(KeyName)) do
		assert(not UniqueMap[UniqueKey], KeyName..UniqueKey.."有重复的项")
		UniqueMap[UniqueKey] = true
	end
	
	if KeyName2 then
		local UniqueMap2 = {}
		for Index, UniqueKey in ipairs(TargetSheet:Col(KeyName2)) do
			assert(not UniqueMap2[UniqueKey], KeyName2..UniqueKey.."有重复的项")
			UniqueMap2[UniqueKey] = true
		end
	end
end



