local AllowSceneType = {
	["城镇场景"]=true,
	["关卡场景"]=true,
	["同步竞技场"] = true,
	["异步竞技场"] = true,
}
local AllowTypesName = {}
for TypeName, _ in pairs(AllowSceneType) do
	table.insert(AllowTypesName, TypeName)
end
return function(Data)
	assert(AllowSceneType[Data],"没有对应的场景类型:"..Data.."，可用场景类型为："..table.concat(AllowTypesName," "))
	return Data
end
