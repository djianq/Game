return function (Data)
	assert((Data >= 0 and Data <= 150),"角色等级【"..Data.."】错误,必须为0~150")
	return Data
end