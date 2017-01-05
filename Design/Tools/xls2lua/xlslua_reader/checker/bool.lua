return function (Data)
	if type(Data) == "boolean" then
		return Data
	end
	if type(Data) == "number" then
		assert((Data>=0 and Data<=1),"使用数值表示bool的，请填0或1")
		if Data == 1 then
			return true
		else
			return false
		end
		return nil
	end

	if Data == "是" then
		return true
	elseif Data == "否" then
		return false
	else
		return nil
	end
end
