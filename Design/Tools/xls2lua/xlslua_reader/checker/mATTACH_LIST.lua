local ShapeInfo = GetFileConfig(OUTPUTBASE.."server/setting/shape_info.lua")
local AttachTbl = ShapeInfo.Name2AttachId
local ShapeConf = ShapeInfo.ShapeConfig
return function(Data)
	local RetTbl = {}
	local AttachList = Split(Data,",")
	for Idx, Info in ipairs(AttachList) do
		local T = Split(Info, ":")
		assert(#T == 2, "配件列表格式错误，必须为 Key:Value 的形式:"..tostring(Info))
		local AttachId = AttachTbl[T[1]]
		assert(AttachId, "配置部位或挂接点["..T[1].."]不存在")
		T[1] = AttachId
		T[2] = tonumber(T[2])
		assert(ShapeConf[T[2]], "造型Id["..T[2].."]不存在")
		table.insert(RetTbl, T)
	end
	return #RetTbl > 0 and RetTbl or nil
end
