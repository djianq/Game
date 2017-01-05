local SEX = {
	["男"] = 1,
	["女"] = 2,
}

return function (Sex)
	assert(SEX[Sex],"性别:【"..Sex.."】错误，必须为男或者女")
	return SEX[Sex]
end
