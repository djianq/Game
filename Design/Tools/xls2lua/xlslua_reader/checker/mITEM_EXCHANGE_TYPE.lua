local SubType = {
				[0] = true,
				[1] = true,
				[9] = true,
			}
			
return function (Data)
	assert(SubType[Data],"交易限制【"..Data.."】错误,必须为0，1，9其中之一")
	return Data
end