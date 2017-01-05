local SubType = {
				[0] = true,
				[1] = true,
			}
			
return function (Data)
	assert(SubType[Data],"计时点【"..Data.."】错误,必须为0，1其中之一")
	return Data
end