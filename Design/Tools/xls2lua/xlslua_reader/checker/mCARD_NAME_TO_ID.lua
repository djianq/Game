local CardCfg = GetFileConfig("server/setting/card_const_info.lua").Name2Type
return function (Data)
	local TableString, ErrMsg = SafeSplit(tostring(Data))
	if not TableString then return nil, ErrMsg end
	local CardIds
	for _, NameStr in ipairs(TableString) do
		assert(CardCfg[NameStr],"没找到卡片【"..NameStr.."】，请查看卡片属性表")
		return CardCfg[NameStr] --只导一张卡
	end
end
