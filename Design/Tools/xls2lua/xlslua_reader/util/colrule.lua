-------------------------------------------------------
-- 本模块用于检查列规则
-- 现在可用的列规则有：
-- * ukey     相当于数据库中的Unique KEY，表示该列值需两两不同
-- * default  该列的单元格允许为空，程序分析时将使用缺省值
--
-------------------------------------------------------

local HEADER_COUNT = 2

-- 相当于数据库中的Unique KEY，表示该列值需两两不同
local function ukey(ColTable, ValidRowCount)
	local UniqueMap = {}
	
	-- 一定要求支持列类型
	assert(#ColTable >= HEADER_COUNT, "该列不能没有列类型和列标题定义")
	
	for i=1, ValidRowCount + HEADER_COUNT do
		if i <= HEADER_COUNT then
			--skip
		else
			local Data = ColTable[i]
			if UniqueMap[Data] then
				return false, i - HEADER_COUNT, "已经存在该值："..tostring(Data)
			end
			if not Data then
				return false, i - HEADER_COUNT, "出现空值!"
			end
			UniqueMap[Data] = true
		end
	end
	
	return true
end


-- 允许nil值
local function default(ColTable, ValidRowCount)
	return true
end


-- 表示该列每单元格必须有内容（即不为lua中的nil）
local function not_default(ColTable, ValidRowCount)
	for i=1, ValidRowCount + HEADER_COUNT do
		if i <= HEADER_COUNT then
			--skip
		else
			local Data = ColTable[i]
			if Data == nil then
				return false, i - HEADER_COUNT, "出现空值！"
			end
		end
	end	
	
	return true
end

local RuleMap = {
["ukey"] = {Func = ukey, Doc = "该列值需两两不同；且每单元格不能为空"},
["default"] = {Func= default, Doc = "该列的单元格允许为空，程序分析时将使用缺省值"},

-- 外部不应该直接使用
["not_default"] = {Func = not_default, Doc = "该列单元格必须全部不为空"} 
}

-------------------------------------------------------
-- 自动处理默认的规则关系
-- 如果调整成功，则返回调整后的RuleList对象。
-- 否则，返回nil, Errmsg
-------------------------------------------------------
function GetAdjustedRuleList(RuleList)
	local DefaultRules = {["not_default"] = true}

	-- 检查是否需要插入删除默认的__notnil
	for _, RuleName in ipairs(RuleList) do
		if RuleName == "ukey" then
			DefaultRules["not_default"] = nil
		elseif RuleName == "default" then
			DefaultRules["not_default"] = nil
		end
	end
	
	-- 将没有被排除的默认规则放到规则的前面
	for RuleName, _  in pairs(DefaultRules) do
		table.insert(RuleList, 1, RuleName)
	end
	
	-- 最后检查是否规则集合有重复
	local UniqueSet = {}
	for _, RuleName in ipairs(RuleList) do
		if UniqueSet[RuleName] then
			return nil, "列规则重复："..RuleName
		end
		UniqueSet[RuleName] = true
	end
	
	return RuleList
end


function GetRuleDoc(RuleName)
	local Cfg = RuleMap[RuleName]
	if not Cfg then return "无规则说明" end
	
	return Cfg.Doc or "无规则说明"
end

-------------------------------------------------------
-- 列规则的检查函数需要返回三个值：
-- 是否检查通过，出错的行号，出错信息
-------------------------------------------------------
function CheckColRule(ColTable, ValidRowCount, RuleName)
	local Info = RuleMap[RuleName]
	if not Info then
		return false, -1, "存在未定义的列规则名:"..tostring(RuleName)
	end

	return Info.Func(ColTable, ValidRowCount)
end