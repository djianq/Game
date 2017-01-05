
local Attrs = dofile("server/setting/title/title_info.lua")

return function(Data)
	local RetTbl = {}
	local List = Split(Data, ",")
	for _,Value in ipairs(List) do
		for Id, Cfg in pairs(Attrs) do
			if Cfg.TitleName==Value then
				table.insert(RetTbl, Id)
				break
			end
		end
	end
	return RetTbl
end