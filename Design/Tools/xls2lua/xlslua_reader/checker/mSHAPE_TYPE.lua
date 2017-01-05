local ShapeMap = 
{
	["小"] = 1,
	["中"] = 2,
	["大"] = 3,
}

return function (Data)
	assert(ShapeMap[Data], Data.."没有该体形类型")
	Data = ShapeMap[Data]
	return Data
end
