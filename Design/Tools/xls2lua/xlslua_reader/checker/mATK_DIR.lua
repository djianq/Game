local DirCfg=GetFileConfig(OUTPUTBASE.."server/setting/common_const.lua").ATK_DIR
return function(Data)
	local DirNum = DirCfg[Data]
	assert(DirNum,"没有："..Data.."这个方向设定")
	return DirNum
end
