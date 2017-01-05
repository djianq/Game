return function(Data)
	local Table = Split(Data, "|")

	assert(#Table == 2,"参数错误,应该为[名字|描述] ")

	return Table
end
