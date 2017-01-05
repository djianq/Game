local Camp=GetFileConfig(OUTPUTBASE.."server/setting/common_const.lua").CAMP
return function(Data)
	assert(Camp[Data],"阵营"..Data.."不存在，请查看《C常量表》的CAMP定义")
	return Camp[Data]
end
