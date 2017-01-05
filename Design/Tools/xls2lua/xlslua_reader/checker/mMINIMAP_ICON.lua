local MiniMapIconCfg = GetFileConfig(OUTPUTBASE.."client/setting/res_cfg.lua").ImageResConfig
local CheckSuffix={"_正常"}
return function (Data)
	local Icon = {}
	for k,val in pairs(CheckSuffix) do
		local Str = MiniMapIconCfg[Data..val]
		assert(Str, "找不到对于"..Data..val.."的配置，请查看【Z资源配置表】")
		table.insert(Icon, Data..val)
	end
	return Icon
end
