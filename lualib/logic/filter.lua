local string = string
local pairs = pairs

--检测、过滤文字的模块
local WordCfg = safe_dofile("setting/filter_cfg.lua")

--简单文字匹配
--聊天中也限制这些字
local Forbidden = WordCfg.Forbidden

-- 取名字限制，不允许有这些字
-- 低于10级也限制说话内容
local ForBiddenCharInName = WordCfg.ForBiddenCharInName

--用于m * n的组合匹配，比如GM会有4*4种之多  
local Forbidden2 = WordCfg.Forbidden2
local Forbidden3 = WordCfg.Forbidden3

-- 获得UTF-8字符串的长度
local function LengthOfUTF8(Str)
	local _, Length = string.gsub(Str, "[^\128-\193]", "")
	return Length
end

--过滤玩家输入的非法字符
local function FilterInput(Str)
	Str = string.gsub(Str, " ", "") 
	Str = string.gsub(Str, "　", "") -- 全角
	return Str
end

-- 内容，长度，长度，严格与否
function ValidGameMsg(Name, MinLen, MaxLen, IfGrimly)
	if string.find(Name, "[%c%z]+") then 
		return false, Name
	end	

	local Len = LengthOfUTF8(Name) 
	if MinLen and Len < MinLen then 
		return false, MinLen .. "," .. MaxLen
	end

	if MaxLen and Len > MaxLen then
		return false, MinLen .. "," .. MaxLen
	end
 
 	Name = FilterInput(string.lower(Name))
 	for _, s in pairs(Forbidden) do
		if string.find(Name, s, 1, true) then
			return false, "CHAT_ILLEGALITY_WORD"
		end
	end

	if IfGrimly then
		for _, s in pairs(ForBiddenCharInName) do
			if string.find(Name, s, 1, true) then
				return false, "CHAT_ILLEGALITY_WORD"
			end	
		end	
		
		for _, v in pairs(Forbidden3) do
			local Comb = Comb(v)
			for _, s in pairs(Comb) do
				if string.find(Name, s, 1, true) then 
					return false, "CHAT_ILLEGALITY_WORD"
				end
			end	
		end
	end

	for _, v in pairs(Forbidden2) do
		local Comb = Comb(v)
		for _, s in pairs(Comb) do
			if string.find(Name, s, 1, true) then
				return false, "CHAT_ILLEGALITY_WORD"
			end
		end
	end

	return true, ""
end
