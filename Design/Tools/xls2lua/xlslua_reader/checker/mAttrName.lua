
local AttrNameToEn = {
	["火"] = "FireAtk",
	["冰"] = "IceAtk",
	["雷"] = "ThunderAtk",
	["风"] = "WindAtk",

}

return function (Data)
	
	local EnName = nil

	assert(#AttrNameToEn[Data],"参数错误,应该为[火,冰,雷,风或者不填]")
	return AttrNameToEn[Data]
end