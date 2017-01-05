
----------------------------------------------------------
--作者：jj
--功能描述：负责属性表相关的数据提取及转换
--目标表：任意对象相关
--依赖表：无
--------------------------------------
local CONST_CFG = GetFileConfig(OUTPUTBASE.."server/setting/common_const.lua")
local clsMaker = clsMakerBase:Inherit()

function clsMaker:SetFilterKey(Key)
	self.FilterKey = Key
end

function clsMaker:MakeAttrFilter(Sheet)
	if not Sheet then return end
	if not self.FilterKey then return end
	if not self.AttrFilter then
		self.AttrFilter = {}
	end
	for RowIdx = 1, Sheet:GetRowCount() do
		local Row = Sheet:Row(RowIdx)
		if not Row["专属端"] or Row["专属端"] == self.FilterKey then
			self.AttrFilter[Row["属性名"]] = true
		end
	end
end

function clsMaker:GetFunctionFilter()
	local FuncFilter = {}
	if CONST_CFG.Formula then
		for FName, _ in pairs(CONST_CFG.Formula) do
			FuncFilter[FName] = "SETTING.CONST.Formula['"..FName.."']"
		end
	end
	return FuncFilter
end

function clsMaker:GetFunction(Formula)
	-- 数学库
	if not self.MapMath then
		self.MapMath = {}
		for Name, _ in pairs(math) do
			self.MapMath[Name] = "math."..Name
		end
	end
	-- 属性
	if not self.MapAttr then
		self.MapAttr = {}
		for CnName, EnName in pairs(self.AllAttributeByCn) do
			self.MapAttr[CnName] = "self:Get"..EnName.."()"
		end
	end
	-- 自定义
	if not self.MapFilter then
		self.MapFilter = self:GetFunctionFilter()
		assert(type(self.MapFilter) == "table", "GetFunctionFilter() 必须返回table")
	end

	-- 将argN 转换成 Args[N]
	Formula = string.gsub(Formula, "([aA][rR][gG])(%d+)", "Args[%2]")
	Formula = Replace(Formula, "%#", self.MapMath) -- 替换数学函数
	Formula = Replace(Formula, "%_", self.MapAttr) -- 替换属性Getter
	Formula = Replace(Formula, "%#", self.MapFilter) -- 替换自定义
	Formula = Replace(Formula, "", self.MapAttr) -- 替换属性Getter

	local Func = loadstring(Formula)
	assert(Func, "语法错误："..Formula)
	assert(type(Func()) == "function", "语法错误："..Formula)
	return Formula
end

-- Sheet : 属性表相关
function clsMaker:ParseAttributeSheet(SheetName, Sheet)
	if not Sheet then return end

	self.AllAttributeByCn = self.AllAttributeByCn or {} -- 记录所有的属性
	self.AllAttributeByEn = self.AllAttributeByEn or {} -- 记录所有的属性

	local RetTbl = {}
	for RowIdx = 1, Sheet:GetRowCount() do
		local ErrHead = string.format("[%s]第%d行错误，",SheetName, RowIdx + 2)
		local Row = Sheet:Row(RowIdx)
		local CnName = assert(Row["属性名"], ErrHead.."缺少 属性名称")
		local EnName = assert(Row["变量名"], ErrHead.."缺少 属性名称")
		local Info = {CnName = CnName,}
		local HasValue = false

		if Row["固定值"] then
			assert(not HasValue, ErrHead.."重复设定“值”，只能存在一种初始化模式！")
			Info.Const = Row["固定值"]
			HasValue = true
		end

		if Row["查表值"] then
			assert(not HasValue, ErrHead.."重复设定“值”，只能存在一种初始化模式！")
			local SheetName = Row["查表值"]
			assert(SheetName, ErrHead.."查表值必须填写 表格名称")
			local SubSheet = self.SheetGroup[SheetName]
			assert(SubSheet, ErrHead..string.format("表格[%s]不存在",SheetName))

			-- 导表
			-- 注意：这里只做记录，查表数据的生成需要把所有属性都导入后再进行
			Info.SheetName = SheetName
			HasValue = true
		end

		if Row["公式值"] then
			assert(not HasValue, ErrHead.."重复设定“值”，只能存在一种初始化模式(固定值 or 查表值 or 公式值)！")
			local Fmt = "return function (self) %s end"
			local Formula = Row["公式值"]
			Info.Formula = string.format(Fmt, string.find(Formula, "return") and Formula or "return "..Formula)
			HasValue = true
		end
		
		assert(not self.AllAttributeByCn[CnName], ErrHead..string.format("重复定义属性名 %s", CnName))
		assert(not self.AllAttributeByEn[EnName], ErrHead..string.format("重复定义变量名 %s", EnName))

		local IsPer = Row["是否百分比显示"]
		Info.IsPer = IsPer

		local Desc = Row["描述"]
		Info.Desc = Desc
		
		Info.PutClient = Row["客户端导出"]
		if not self.FilterKey or self.AttrFilter[CnName] then 
			RetTbl[EnName] = Info
			self.AllAttributeByCn[CnName] = EnName
			self.AllAttributeByEn[EnName] = CnName
		end

		if not HasValue then
			print(string.format("Warnning : %s 没有指定默认值",CnName))
		end
	end
	return RetTbl
end

-- Sheet : 查表导出
function clsMaker:ParseConstSheet(AttributeMap)
	local RetTbl = {}
	self.RelationAttr = self.RelationAttr or {} 
	self.RelaResetAttr = self.RelaResetAttr or {}
	for Type, Map in pairs(AttributeMap) do
		for Attr, Info in pairs(Map) do
			if Info.SheetName then
				local Sheet = self.SheetGroup[Info.SheetName]
				local KeyCnName = Sheet:ColDesc(1) -- 固定以第一列作为 Key
				assert(KeyCnName, string.format("[%s]错误的表格格式，#1 缺少名称定义",Info.SheetName))
				local KeyEnName = self.AllAttributeByCn[KeyCnName]
				assert(KeyEnName, string.format("[%s]错误的列名称%s，必须为定义好的属性名",Info.SheetName,KeyCnName))
				Info.KeyName = KeyEnName

				if (not RetTbl[Info.SheetName]) then
					local Table = {}
					for RowIdx = 1, Sheet:GetRowCount() do
						local ErrHead = string.format("[%s]第%d行错误，",Info.SheetName, RowIdx - 2)
						local Row = Sheet:Row(RowIdx)
						local Key = Row[KeyCnName]
						assert(Key, ErrHead..string.format("%s不能为空，并且是唯一的",KeyCnName))
						assert(not Table[Key], ErrHead..string.format("%s不能为空，并且是唯一的",KeyCnName))
                
						local Line = {}
						for ColIdx = 2, Sheet:GetColCount() do
							local CnName = Sheet:ColDesc(ColIdx)
							assert(CnName, string.format("错误的表格格式，#%d 缺少名称定义", ColIdx))
							if not self.FilterKey or self.AttrFilter[CnName] then
								local EnName = self.AllAttributeByCn[CnName]
								assert(EnName, "错误的列名称"..CnName.."，必须为定义好的属性名")
								Line[EnName] = Row[CnName]
							end
						end
						Table[Key] = Line
					end
					RetTbl[Info.SheetName] = Table
				end
				-- 确定属性关系
				if Type == "BuildAtr" and KeyEnName then
					self.RelationAttr[KeyEnName] = self.RelationAttr[KeyEnName] or {}
					self.RelationAttr[KeyEnName][Attr] = true
					self.RelaResetAttr[Attr] = true
				end
			end
		end
	end
	return RetTbl
end

-- Sheet : 处理 Formula 属性转换
function clsMaker:ParseFormualAttr(AttributeMap)
	self.RelationAttr = self.RelationAttr or {} 
	self.RelaResetAttr = self.RelaResetAttr or {}
	for Type, Map in pairs(AttributeMap) do
		for Attr, Info in pairs(Map) do
			local Formula = Info.Formula
			if Formula then
				if Type == "BuildAtr" then
					local AttrNames = GetMatchNames(Formula,"%_")
					for _, CnName in pairs(AttrNames) do
						local EnName = self.AllAttributeByCn[CnName]
						if EnName then
							self.RelationAttr[EnName] = self.RelationAttr[EnName] or {}
							self.RelationAttr[EnName][Attr] = true
							self.RelaResetAttr[Attr] = true
						end
					end
				end
				Info.Formula = self:GetFunction(Info.Formula)
			end
		end
	end
end

-- Sheet : 属性算子
function clsMaker:ParseCounterSheet(Sheet, BaseAtr)
	if not Sheet then return end
	local SheetName = "属性算子"
	local Tbl = {}
	for RowIdx = 1, Sheet:GetRowCount() do
		local ErrHead = string.format("[%s]第%d行错误，",SheetName, RowIdx + 2)
		local Row = Sheet:Row(RowIdx)
		local CnName = Row["算子名"]
		assert(CnName, ErrHead.."缺少 算子名")
		local EnName = Row["变量名"]
		assert(EnName, ErrHead.."缺少 变量名")
		local CnAttr = Row["属性名"]
		assert(CnAttr, ErrHead.."缺少 属性名")
		local EnAttr = self.AllAttributeByCn[CnAttr]
		assert(EnAttr, ErrHead.."错误的属性名："..CnAttr)
		local Fmt = "return function (self, Args) return %s end"
		local Formula = Row["计算公式"]
		assert(Formula, ErrHead.."缺少 计算公式")
		Formula = string.format(Fmt, Formula)
		local Pri = Row["优先级"]
		assert(Pri, ErrHead.."缺少 优先级")
		local Desc = Row["描述"]
		assert(Desc, ErrHead.."缺少 描述")
		local IsPer = Row["是否百分比显示"]

		assert(not BaseAtr[EnAttr],"算子计算对象不能是基础属性")
		--[[
		if BaseAtr[EnAttr] then
			BaseAtr[EnAttr].Prefix = "Save"
		end
		]]
		
		assert(not self.AllAttributeByCn[CnName], ErrHead.."重复定义算子名："..tostring(CnName))
		self.AllAttributeByCn[CnName] = EnName
		Tbl[EnName] = {
			CnName = CnName,
			Desc = Desc,
			Target = EnAttr,
			Pri = Pri,
			Formula = self:GetFunction(Formula),
			IsPer = IsPer,
		}
	end
	return Tbl
end

function clsMaker:ParseClientAttr(Attribute)
	local Ret = {}
	for _,AttrCfg in pairs(Attribute) do
		for Attr, Info in pairs(AttrCfg) do
			if Info.PutClient then
				Ret[Attr] = true
			end
		end
	end
	return Ret
end

-- 输出 :
function clsMaker:MakeTable()
	if self.Key and self.Key.SpecSide then
		self:SetFilterKey(self.Key.SpecSide)
	end
	self:MakeAttrFilter(self.SheetGroup["基础属性"])
	self:MakeAttrFilter(self.SheetGroup["临时属性"])
	self:MakeAttrFilter(self.SheetGroup["生成属性"])
	local FinalTable = {}
	
	-- 记录所有的属性
	FinalTable.Attribute = {}
	FinalTable.Attribute.BaseAtr = self:ParseAttributeSheet("基础属性", self.SheetGroup["基础属性"])
	FinalTable.Attribute.TempAtr = self:ParseAttributeSheet("临时属性", self.SheetGroup["临时属性"])
	FinalTable.Attribute.BuildAtr = self:ParseAttributeSheet("生成属性", self.SheetGroup["生成属性"])
	
	-- 计算需要导出到客户端的属性
	self.PutClientAttr = self:ParseClientAttr(FinalTable.Attribute)

	-- 记录所有的表格信息
	FinalTable.ConstInfo = self:ParseConstSheet(FinalTable.Attribute)

	-- 处理属性中 Formula 的转换
	self:ParseFormualAttr(FinalTable.Attribute)
	
	-- 输出算子
	FinalTable.AttributeCounter = self:ParseCounterSheet(self.SheetGroup["属性算子"], FinalTable.Attribute.BaseAtr)
	
	FinalTable.Name2Atr = self.AllAttributeByCn

	-- 整理属性关系表
	local RelaAttrTbl = {}
	local function MergeRelaAttr(RelaTbl,AttrTbl)
		for RelAttr, _ in pairs(AttrTbl) do
			if self.RelationAttr[RelAttr] then
				MergeRelaAttr(RelaTbl, self.RelationAttr[RelAttr])
				RelaTbl[RelAttr] = true
			else
				RelaTbl[RelAttr] = true
			end
		end
	end
	for KeyAttr,AttrTbl in pairs(self.RelationAttr) do
		if not self.RelaResetAttr[KeyAttr] and not RelaAttrTbl[KeyAttr] then
			RelaAttrTbl[KeyAttr] = {}
			MergeRelaAttr(RelaAttrTbl[KeyAttr],AttrTbl)
		end
	end
	FinalTable.RelationAttr = RelaAttrTbl

	return FinalTable
end

return clsMaker
