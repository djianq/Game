local EffectCfgs = dofile("client/setting/effect_info.lua")	
return function (Data)
	local EffIds = SafeSplit(Data)
	if not EffIds then return nil end
	local Ids = {}
	for _, EffId in ipairs(EffIds) do
		if tonumber(EffId) ~= -1 then
			local EffectId = EffectCfgs[tonumber(EffId)]
			assert(EffectId,"找不到对应"..EffId.."的EffectId,请查看【通用特效表】")
		end
		table.insert(Ids, tonumber(EffId))
	end
	return Ids
end
