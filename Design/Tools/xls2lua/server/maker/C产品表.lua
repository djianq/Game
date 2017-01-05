clsDrugMaker = dofile("server/maker/maker_item.lua"):Inherit()

function clsDrugMaker:MakeTable()
	self.FinalTable = Super(clsDrugMaker).MakeTable(self)
	return self.FinalTable
end

return clsDrugMaker

