OUTPUTBASE = "../../../output/"
dofile("language_cfg.lua")
dofile("xlslua_reader/util/class.lua")
dofile("xlslua_reader/util/common.lua")

local CharMap = {}
local PhrasesList = {}
local SPhrasesList = {}

function InitDict(TargetLang)
	local CfgFiles = AutoConvertCfg[TargetLang]
	if not CfgFiles then return end
	local CharDictFiles = CfgFiles.CharFiles	
	local PhrasesFiles = CfgFiles.PhrasesFiles
	local SPhrasesFiles = CfgFiles.SPhrasesFiles
	for _, FileName in pairs(CharDictFiles or {}) do
		local File = io.open("dictionary/"..FileName..".txt","r")
		for Line in File:lines() do
			local Vals = Split(Line,"\t",false)	
			local _Vals = Split(Vals[2]," ")
			CharMap[Vals[1]] = _Vals[1]
		end
		File:close()
	end

	for _, FileName in pairs(SPhrasesFiles or {}) do
		local File = io.open("dictionary/"..FileName..".txt","r")
		for Line in File:lines() do
			local Vals = Split(Line, "\t",false)
			local _Vals = Split(Vals[2], " ")
			table.insert(SPhrasesList,{Vals[1],_Vals[1]})
		end
		File:close()
	end

	for _, FileName in pairs(PhrasesFiles or {}) do
		local File = io.open("dictionary/"..FileName..".txt","r")
		for Line in File:lines() do
			local Vals = Split(Line, "\t",false)
			local _Vals = Split(Vals[2], " ")
			table.insert(PhrasesList,{Vals[1],_Vals[1]})
		end
		File:close()
	end
	-- 排序
	table.sort(SPhrasesList, function(A,B) return string.len(A[1]) > string.len(B[1]) end)
	table.sort(PhrasesList, function(A,B) return string.len(A[1]) > string.len(B[1]) end)
--	for Key, Val in pairs(CharMap) do
--		print(Key,"----", Val)
--	end
end

function Convert(SrcStr)
	for _, Vals in ipairs(SPhrasesList) do
		SrcStr = string.gsub(SrcStr,Vals[1], Vals[2])
	end
	for Key, Val in pairs(CharMap) do
		SrcStr = string.gsub(SrcStr, Key, Val)	
	end
	for _, Vals in ipairs(PhrasesList) do
		SrcStr = string.gsub(SrcStr, Vals[1], Vals[2])
	end
	return SrcStr
end

local TargetLang = arg[1]
local SrcFile = arg[2]
local DestFile = arg[3]

InitDict(TargetLang)
local SrcFile = io.open(SrcFile,"r")
local _SrcStr = SrcFile:read("*a")
SrcFile:close()
local TargetStr = Convert(_SrcStr)
local DestFile = io.open(DestFile,"w")
DestFile:write(TargetStr)
DestFile:close()
