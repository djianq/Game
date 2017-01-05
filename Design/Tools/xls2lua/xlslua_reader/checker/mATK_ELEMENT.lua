local EleCfg=GetFileConfig(OUTPUTBASE.."server/setting/common_const.lua").ATK_ELEMENT
return function(Data)
	local EleNum = EleCfg[Data]
	assert(EleNum,"没有："..Data.."这个攻击属性设定")
	return EleNum
end
