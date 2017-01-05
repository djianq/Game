local ChangeSceneApi = GetFileConfig("client/setting/scene_api.lua").ApiList
local Cfg = GetFileConfig("client/setting/res_cfg.lua").ImageResConfig
return function(Data)
	local RetTbl = {}
	local List = Split(Data, ";")
	for i,Value in ipairs(List) do
		if Value and Value~="" then
			local t = loadstring("return " .. Value)()
			assert(type(t)=="table", "error table{iconName,SceneName,Param,Desc}" .. Value)
			assert(t[1] and (t[1] == "关卡头像" or Cfg[t[1]]) , t[1] .. "资源不存在")
			if t[2] then
				assert(t[2] and ChangeSceneApi[t[2]], "not found in scene_api")
			end
			table.insert(RetTbl, t)
			List[i] = t
		end
	end
	if #List == 1 and List[1][2] ~= "关卡" then
		local SmallImgName = List[1][1].."_小"
		assert(List[1] and Cfg[SmallImgName] , SmallImgName.."资源不存在")
	end
	return RetTbl
end