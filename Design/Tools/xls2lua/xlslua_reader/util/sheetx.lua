--load sheet module
clsSheetX = clsSheet:Inherit()

clsSheetX.COL_IDX_TYPE = 1
clsSheetX.COL_IDX_DESC = 2
clsSheetX.HEADER_COUNT = 2

-- 切分列类型和额外约束
-- 格式：int@key
local Rule_TAG = "@"
local function _SplitTypeAndRules(Str)
	local Result = Split(Str, Rule_TAG, true)
	assert(#Result >= 1, "列类型定义必须存在")
	return Result
end

local function _ToRealColIndex(ColIdx)
	-- Microsoft Excel的列命名规则是：
	-- ColIdx <= 26:      'A' --> 'B' ... -->'Z'
	-- 26 < ColIdx <= 52: 'AA'--> 'AB'... -->'AZ'
	-- 52 < ColIdx <= 78: 'BA'--> 'BB'... -->'BZ'
	-- ...
	
	if type(ColIdx) == "number" then
		if ColIdx <= 0 then
			error("当前访问列索引[" .. ColIdx .."]非法")
		end
	
		if ColIdx >= 500 then
			error("当前访问列索引[" .. ColIdx .. "]，文档需要这么多列？！")
		end
		
		local Prefix = ""
		local PrefixNumber = math.floor(ColIdx / 26)
		local RemainNumber = ColIdx % 26
		if RemainNumber == 0 then
			PrefixNumber = PrefixNumber - 1
			RemainNumber = 26
		end
		
		if PrefixNumber > 0 then
			Prefix = string.char( string.byte('A') + (PrefixNumber - 1))
		end
		
		return Prefix .. string.char( string.byte('A') + math.floor(RemainNumber - 1) )
	end
	
	return ColIdx
end

function clsSheetX:__init__(Name, Table, Maker)
	-- 出现非法的xls sheet页即跳过，可能是说明页（第一行为空内容的sheet）
	for ColIdx, ColTable in pairs(Table) do
		if #ColTable < clsSheetX.HEADER_COUNT then
			print("！！！忽略了无效的Sheet页导入["..Name.."]：第["..ColIdx.."]列数据错误！！！")
			return
		end
	end

	Super(clsSheetX).__init__(self, Name, Table)
	
	self.Maker = Maker

	self:_ColMapping()
	self:_RunChecker()
end

function clsSheetX:GetRowCount()
	local Result = Super(clsSheetX).GetRowCount(self)
	if Result > 0 then
		Result = Result - self.HEADER_COUNT
	end
	
	return Result
end

function clsSheetX:Col(ColIdx)
	ColIdx = _ToRealColIndex(ColIdx) -- support 1 -> 'A'; 2 ->'B'... etc
	local Result = Super(clsSheetX).Col(self, ColIdx)
	
	--can we use col mapping?
	if Result == nil then
		local RealColIdx = self:GetRealColIdxByDesc(ColIdx)
		if RealColIdx ~= nil then
			Result = Super(clsSheetX).Col(self, RealColIdx)
		end
	end
	
	return Result
end

function clsSheetX:ColType(ColIdx)
	local Result = self:Col(ColIdx)
	self:Assert( Result[clsSheetX.COL_IDX_TYPE], 
		string.format("第[%s]列不存在列类型定义！", ColIdx) )
	local SplitStrs = _SplitTypeAndRules( Result[clsSheetX.COL_IDX_TYPE] )
	return SplitStrs[1]
end

function clsSheetX:ColRuleList(ColIdx)
	local Result = self:Col(ColIdx)
	local SplitStrs = _SplitTypeAndRules( Result[clsSheetX.COL_IDX_TYPE] )
	table.remove(SplitStrs, 1)
	local RuleList, ErrMsg = GetAdjustedRuleList(SplitStrs)
	self:Assert(RuleList, string.format("第[%s]列的列规则提取出错：[%s]", ColIdx, tostring(ErrMsg)))
	return RuleList
end

function clsSheetX:ColDesc(ColIdx)
	local Result = self:Col(ColIdx)
	if Result then
		return Result[clsSheetX.COL_IDX_DESC]
	end
end

function clsSheetX:Row(RowIdx)
	--RowIdx skip datatype define & header define
	local __RowIdx = RowIdx + self.HEADER_COUNT
	local Row = {}
	for ColIdx, ColTable in pairs(self.Table) do
		local Desc = ColTable[clsSheetX.COL_IDX_DESC]
		local Cell = ColTable[__RowIdx]
		if Cell ~= nil then
			Row[Desc] =Cell
		end
	end
	
	return Row
end

function clsSheetX:Cell(RowIdx, ColIdx)
	local Col = self:Col(ColIdx)
	self:Assert(Col, string.format("列[%s]内容为空，请检查文档", _ToRealColIndex(ColIdx)))
	return Col[RowIdx + self.HEADER_COUNT]
end

function clsSheetX:_ColMapping()
	local _ColMapping = {}
	for ColIdx, ColTable in pairs(self.Table) do
		self:Assert(#ColTable >= clsSheetX.HEADER_COUNT, 
			string.format("列[%s]无列类型或列标题定义!请补充！", ColIdx))

		local Desc = ColTable[clsSheetX.COL_IDX_DESC]
		self:Assert(Desc, "数据表格式错误，没有定义列类型及列标题就填写了该列数据!!")
		self:Assert(_ColMapping[Desc] == nil, string.format("列类型[%s]重复！", Desc))

		_ColMapping[Desc] = ColIdx
	end
	
	self.ColMapping = _ColMapping
end

function clsSheetX:GetRealColIdxByDesc(Desc)
	return self.ColMapping[Desc]
end

function clsSheetX:_AddChecker()
	self.Checker = clsChecker:New()
end

function clsSheetX:_RunChecker()
	local RowCount = self:GetRowCount()
	if RowCount == 0 then
		return
	end
	
	-- 开始检查
	for ColIdx, ColTable in pairs(self.Table) do
		local ColType = self:ColType(ColIdx)
		G_CurColName = ColTable[self.HEADER_COUNT]	
		-- 检查列类型
		for i=1, RowCount + self.HEADER_COUNT do
			if i <= self.HEADER_COUNT then
				--skip
			else
				local Data = ColTable[i]
				if Data ~= nil then
					local Result, ErrMsg = self.Maker:CheckData(Data, ColType)
					
					self:Assert(Result ~= nil, 
						string.format("单元格[%d][%s]内容 [%s] 不符合类型[%s]定义。%s",
						i, ColIdx, Data, ColType, ErrMsg and tostring(ErrMsg) or "" )
						)
	
					--使用经过类型格式化的结果更新原来的表
					ColTable[i] = Result
				end -- end if
			end -- end if
		end -- end for
		
		
		-- 检查列规则
		local RuleList = self:ColRuleList(ColIdx)
		for _, RuleName in ipairs(RuleList) do
			local IsOK, ErrRowIdx, ErrMsg = CheckColRule(ColTable, RowCount, RuleName)
			self:Assert(IsOK, string.format("第[%s]列(%s)不符合列规则[%s]的定义！具体错误在第[%s]行：[%s]"..
				"\n列规则[%s]的定义如下：[%s]", 
				tostring(ColIdx), tostring(self:ColDesc(ColIdx)), tostring(RuleName), 
				tostring(ErrRowIdx), tostring(ErrMsg),
				tostring(RuleName), GetRuleDoc(RuleName))
				)
		end
	end
	-- 结束检查
end

return clsSheetX
