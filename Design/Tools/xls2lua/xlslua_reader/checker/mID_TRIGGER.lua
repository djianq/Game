local Range=GetFileConfig(OUTPUTBASE.."server/setting/common_const.lua").RANGE_ID.TRIGGER_ID
return function(Data)
	Data = tonumber(Data)
	assert(Range[1] <= Data and Range[2] >= Data,"触发器ID必须在"..Range[1].."-"..Range[2].."之间")
	return Data
end
