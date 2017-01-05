local Info = {
				["攻击"] = 1,
				["防御"] = 2,
				["平衡"] = 3,
				["其他"] = 4,
			}
return function (Data)
	assert(Info[tostring(Data)],"神符类型【"..Data.."】不存在，请联系程序员")
	return Info[tostring(Data)]
end