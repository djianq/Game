return function (Data)
	Data = MultiFilter(Data)

	local Var
	local Res, ErrMsg = xpcall(function ()
		Var = loadstring("return "..Data)()
	end, function() end)
	if not Var then
		return nil, "lua 的基本类型，不明白可以找程序问问："
					.."\n例子："
					.."\n	形式1 - 数值型：123"
					.."\n	形式2 - 字符串：\"abc\""
					.."\n	形式3 - table ：{123, \"abc\"}"
					.."\n	形式4 - 布尔值：true/false"
	end
	return Var
end
