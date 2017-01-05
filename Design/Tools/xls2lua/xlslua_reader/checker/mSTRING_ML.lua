return function (Data)
	if Data == "[空]" then
		Data = ""
	end
	if Data ~= "" then
		Data = CheckMultiLanguage(Data)
	end
	return tostring(Data)
end
