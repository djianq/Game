local Type2Id = dofile("server/setting/npcattr/npc_factory.lua").Type2Id
return function (Data)
	local Tbl = {}
	local Types = Split(Data, ",") 	
	for _,Type in pairs(Types) do
		assert(Type2Id[Type],"没有这个NPC"..Type)
		table.insert(Tbl, Type2Id[Type])
	end
	return Tbl
end