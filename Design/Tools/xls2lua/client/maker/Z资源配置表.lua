-----------------------------------------------
--$Id$
--资源配置表
--关联：
-----------------------------------------------

local clsMaker = clsMakerBase:Inherit()

local Name2Atr = 
{
	["名称"]		= "Name",
	["图片文件"]	= "Image",
}

function clsMaker:ParseImg(SheetTbl)
	local Tbl = {}
	for _, Sheet in pairs(SheetTbl) do
		for RowIdx = 1, Sheet:GetRowCount() do
			local Row = Sheet:Row(RowIdx)
			local Key = Row["名称"]
			Tbl[Key] = {}
			for CnName, EnName in pairs(Name2Atr) do
				if Row[CnName] and CnName ~= "名称" then 
					if CnName == "图片文件" or CnName == "选中图片" or CnName == "常规图片" or CnName == "不可点图片" then
						if Row[CnName] == "res/null.png" then
							Row[CnName] = "" 
						end
					end
					if CnName == "场景_主页背景" then 
						assert("场景_主页背景")
					end
					Tbl[Key][EnName] = Row[CnName]
				end 
			end
		end
	end
	
	return Tbl 
end


function clsMaker:MakeTable()
	local FinalTable = 
	{
		ImageResConfig = self:ParseImg({self.SheetGroup["图标资源"]}),
	}
	
	return FinalTable
end

return clsMaker