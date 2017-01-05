return function (Data)
	local SEX = {
		["男"] = true,
		["女"] = true,
	}
	local TableString, ErrMsg = SafeSplit(tostring(Data))
	if not TableString then
		return nil, ErrMsg
	end
	for _, Sex in pairs(TableString) do 
		assert(SEX[Sex],"性别:【"..Sex.."】错误，必须为男或者女")
	end
	return TableString
end