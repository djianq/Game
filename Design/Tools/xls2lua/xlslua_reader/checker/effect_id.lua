local EffectCfgs = dofile("client/setting/effect_info.lua")	
return function (Data)
	local EffId = tonumber(Data)
	local EffectId = EffectCfgs[EffId]
	assert(EffectId,"找不到对应"..EffId.."的EffectId,请查看【通用特效表】")
	return EffId
end
