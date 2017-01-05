return function (Data)
	Data = tonumber(Data)
	-- assert((Data >= 30000 and Data <= 49999),"服装的ID【"..Data.."】错误,范围必须为3000 ~ 19999")

	return Data
end