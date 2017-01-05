local EffectCfgs = dofile("client/setting/effect_info.lua")	
return function (Data)
	local TableString, ErrMsg = Split(tostring(Data), "|")
	if not TableString then
		return nil, ErrMsg
	end
	
	for i, Str in ipairs(TableString) do
		local EffId = tonumber(Str)
		local EffectId = EffectCfgs[EffId]
		if not EffectId then
			return nil, "找不到对应"..EffId.."的EffectId,请查看【通用特效表】"
		end
		
		TableString[i] = EffId
	end
	
	return TableString
end
