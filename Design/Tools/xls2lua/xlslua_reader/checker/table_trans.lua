
local Name2Id = dofile("server/setting/hero_trans.lua").Name2Id

return function(Data)
	local Names = Split(Data, ",") 

	local Tbl = {}
	for _,Name in pairs(Names) do
		assert(Name2Id[Name], "在变身表中找不到【".. Name .. "】这个变身配置")
		table.insert(Tbl, Name2Id[Name])
	end
	return #Tbl==0 and nil or Tbl
end