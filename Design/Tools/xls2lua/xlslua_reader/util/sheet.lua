--class type init
clsSheet = clsObject:Inherit()

--init
function clsSheet:__init__(Name, Table)
	local Result = Super(clsSheet).__init__(self)
	self.Table = Table
	self.Name = Name
	self.IsReady = true
	return Result
end

function clsSheet:GetName()
	return self.Name
end

function clsSheet:GetRowCount()
	if self:GetColCount() == 0 then
		return 0 
	end
	
	--count row 'A' only
	return #self.Table["A"]
end

function clsSheet:Rows()
	self.__CurIterRowIdx = 0
	function _Iter(Sheet, RowIdx)
		self.__CurIterRowIdx = self.__CurIterRowIdx + 1
		if self.__CurIterRowIdx > Sheet:GetRowCount() then
			return nil
		end

		local Row = Sheet:Row(self.__CurIterRowIdx)
		assert(type(Row) == "table")
		return self.__CurIterRowIdx, Row
	end
	
	return _Iter, self
end

-- auto fetch log header(inlcude name & try include record num)
function clsSheet:_GetHeader()
	-- only iter by self:Rows() can fetch record num 
	if self.__CurIterRowIdx then
		return string.format("[%s][Record:%d]:", 
			self:GetName(), self.__CurIterRowIdx)
	else
		return string.format("[%s]:", self:GetName())
	end
end

function clsSheet:Assert(Result, Msg)
	assert(Result, self:_GetHeader()..(Msg or "error!"))
end

function clsSheet:GetColCount()
	local Count = 0
	for i, v in pairs(self.Table) do
		Count = Count + 1
	end
	
	return Count
end

--get row
function clsSheet:Row(RowIdx)
	local Row = {}
	for ColIdx, ColTable in pairs(self.Table) do
		Row[ColIdx] = ColTable[RowIdx]
	end
	
	return Row
end

--get col
function clsSheet:Col(ColIdx)
	return self.Table[ColIdx]
end

--get cell
function clsSheet:Cell(RowIdx, ColIdx)
	return self:Col(ColIdx)[RowIdx]
end

return clsSheet