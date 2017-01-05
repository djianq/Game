local AllowState = {
	["垫步A"] = true,
	["垫步B"] = true,
	["空中闪避"] = true,
	["地面A1"] = true,
	["地面A2"] = true,
	["地面A3"] = true,
	["地面A4"] = true,
	["地面B"] = true,
	["地面AB"] = true,
	["地面AAB"] = true,
	["地面AAAB"] = true,
	["空中A1"] = true,
	["空中A2"] = true,
	["空中A3"] = true,
	["空中B"] = true,
	["空中AB"] = true,
	["空中AAB"] = true,
	["影子"] = true,
	["地面A4追加"] = true,
	["空中A1附加"] = true,
	["空中B附加"] = true,
	["空中A3附加"] = true,
	["空中A4附加"] = true,
	["空中A5附加"] = true,
	["空中A6附加"] = true,
	["空中闪避附加"] = true,
	["格挡"] = true,
	["格挡反弹"] = true,
	["闪避"] = true,
	["地面AB追加1"] = true,
	["地面AB追加2"] = true,
	["地面AB追加3"] = true,
	["空中AB附加1"] = true,
	["空中AB附加2"] = true,
	["地面AB"] = true,
	["地面AAB"] = true,
	["地面AAAB"] = true,
	["咬刃开启"] = true,
	["咬刃攻击A1"] = true,
	["咬刃攻击A2"] = true,
	["咬刃攻击A3"] = true,
	["咬刃攻击A4"] = true,
}
return function(Data)
	local StateList = Split(Data,",")
	for _, State in pairs(StateList) do
		assert(AllowState[State], "状态["..State.."]不允许使用")
	end
	return StateList
end