local SubType = {
				[0] = true,
				[1] = true,
				[2] = true,
				[3] = true,
			}
			
return function (Data)
	assert(SubType[Data],"丢弃类型【"..Data.."】错误,必须为0，1，2，3其中之一")
	return Data
end