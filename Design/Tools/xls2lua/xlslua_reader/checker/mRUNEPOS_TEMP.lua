local RunePos=  GetFileConfig("server/setting/item/runepos_cfg.lua").RunePosTemplate

return function (Data)
	assert(RunePos[Data],Data.."没有该神符位模板，请确认相关表")
	return Data
end