local CALSSSET = {}
CALSSSET.Classes = 
{
	COREOBJ = "obj/coreobj.lua",
}

function CALSSSET.LoadAllClass()
	for k, v in pairs(CALSSSET.Classes) do
		CALSSSET[k] = Import(CONST_PATH .. v)
		assert(CALSSSET[k], string.format("Error : Read (%s) File Error !!! ", v))
	end
end

CALSSSET.LoadAllClass()

return CALSSSET
