return function (Data)
	if Data == "[空]" then
		Data = ""
	end
	Data = MultiFilter(Data)
	return tostring(Data)
end
