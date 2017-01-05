return function (Data)
	local Result = tonumber(Data)
	
	if not Result then
		return nil
	end
	
	if math.floor(Result) == Result then
		return Result
	end
	
	return nil
end