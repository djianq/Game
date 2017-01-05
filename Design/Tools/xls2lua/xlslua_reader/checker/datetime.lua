return function (Data)
	if type(Data) ~= "string" then
		return nil
	end
	
	-- 必须符合格式'2008-08-08 00:00:00'
	if not string.match(Data, "^%d%d%d%d%-%d%d%-%d%d %d%d%:%d%d%:%d%d$") then
		return nil
	end
	
	-- 提取各项
	local MatchTable = {}
	for item in string.gmatch(Data, "%d+") do
		table.insert(MatchTable, tonumber(item))
	end
	
	local TimeInfo = {
		year = MatchTable[1],
		month = MatchTable[2],
		day = MatchTable[3],
		hour = MatchTable[4],
		min = MatchTable[5],
		sec = MatchTable[6]
	}
	-- 年、月、日、时、分、秒要符合取值范围
	-- year (four digits)
	-- month (1--12)
	-- day (1--31)
	-- hour (0--23)
	-- min (0--59)
	-- sec (0--60)
	local Time = os.time(TimeInfo)
	local StandardTimeInfo = {
		year = tonumber(os.date("%Y", Time)),
		month = tonumber(os.date("%m", Time)),
		day = tonumber(os.date("%d", Time)),
		hour = tonumber(os.date("%H", Time)),
		min = tonumber(os.date("%M", Time)),
		sec = tonumber(os.date("%S", Time)),
	}

	for Key, Value in pairs(TimeInfo) do
		if Value ~= StandardTimeInfo[Key] then
			print(
				string.format("文档中的时间：[%s]和检测转换后的时间[%04d-%02d-%02d %02d:%02d:%02d]不同",
				Data, 
				StandardTimeInfo.year,
				StandardTimeInfo.month,
				StandardTimeInfo.day,
				StandardTimeInfo.hour,
				StandardTimeInfo.min,
				StandardTimeInfo.sec)
			)
			return nil
		end
	end

	return Data
end