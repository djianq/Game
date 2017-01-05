local Info = {
				["白"] = 1,
				["绿"] = 2,
				["蓝"] = 3,
				["紫"] = 4,
				["橙"] = 5,
				["红"] = 6,
			}
return function (Data)
	assert(Info[tostring(Data)],"品质【"..Data.."】不存在，请联系程序员")
	return Info[tostring(Data)]
end