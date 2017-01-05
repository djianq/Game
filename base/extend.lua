local table = table
local string = string

if not setfenv then -- Lua 5.2+
  	local function findenv(f)
    	local level = 1
    	repeat
      		local name, value = debug.getupvalue(f, level)
      		if name == '_ENV' then return level, value end
      		level = level + 1
    		until name == nil
    	return nil end

  	getfenv = function (f) return(select(2, findenv(f)) or _G) end
  	setfenv = function (f, t)
   		local level = findenv(f)
    	if level then debug.setupvalue(f, level, t) end
    	return f 
    end
end

function output_value(value)
	if not value then return "nil" end
	local str, value_type
	value_type = type(value)
	if value_type == "number" then
		str = string.format("[ %s ]n", value)
	elseif value_type == "string" then
		str = string.format("[ \"%s\" ]s", value)
	elseif value_type == "table" then
		str = string.format("[ 0x%s ]t", string.sub(tostring(value), 8))
	elseif value_type == "function" then
		str = string.format("[ 0x%s ]f", string.sub(tostring(value), 11))
	elseif value_type == "userdata" then
		str = string.format("[ 0x%s ]u", string.sub(tostring(value), 11))
	else
		str = string.format("[ S\"%s\" ]%s", tostring(value), type(value))
	end
	return str
end

function table.print(t, tname, print_one_level)
	if type(t) ~= "table" then
		return
	end
	local _deep_count = 0
	local print_one_table
	local max_deep = deep or 10
	local printed_tables = {}
	local t_path = {}
	tname = tname or "root_table"
	print_one_table = function(tb, tb_name, print_one_level)
		tb_name = tb_name or "table"			
		table.insert(t_path, tb_name)
		local tpath, i, tname = ""
		for i, pname in pairs(t_path) do
			tpath = tpath .. "." .. pname
		end
		printed_tables[tb] = tpath
		_deep_count = _deep_count + 1
		local k, v, str
		local tab = string.rep(" ", _deep_count * 4)
		print(string.format("%s  {", tab))
		for k, v in pairs(tb) do
			if type(v) == "table" then
				if printed_tables[v] then
					str = string.format("%s    %s = [ %s ]t", tab, output_value(k), printed_tables[v])
					print(str)
				elseif not print_one_level then
					str = string.format("%s    %s = ", tab, output_value(k))
					print(str)
					print_one_table(v, tostring(k))
				else
					str = string.format("%s    %s = %s", tab, output_value(k), output_value(v))
					print(str)
				end
			else
				str = string.format("%s    %s = %s", tab, output_value(k), output_value(v))
				print(str)
			end
		end
		print(tab .. "  }")
		table.remove(t_path)
		_deep_count = _deep_count - 1
	end	
	print_one_table(t, tname, print_one_level)
	printed_tables = nil
end

-- 拆分字符串
function string.split(Txt, Char)
	local step = string.len(Char)
	local S = 1
	local E
	local Ret = {}
	if string.len(Txt) > 0 then
		while true do
			E = string.find(Txt, Char, S)
			Ret[#Ret + 1] = string.sub(Txt, S, E and E - 1)
			if not E then break end
			S = E + step
		end
	end
	return Ret
end

-- 用于安全的加载数据文件，即在空的全局环境中执行指定的脚本文件
function safe_dofile(fname)
	if type(fname) ~= "string" then
		return
	end
	local function loader(path)
		path = CONST_PATH .. path
		local succed, func, err = pcall(loadfile, path)
		if succed and type(func) == "function" then
			return func()
		else
			print("error : loadfile " .. path .. " failed with " .. err)
		end
	end

	local env = {}
	setmetatable(env, {__index = _G})
	return setfenv(loader, env)(fname)
end

function Comb(src)
	local function concat(a, b)
		local tbl = {}
		for _, v1 in pairs(a) do
			for _, v2 in pairs(b) do
				table.insert(tbl, string.format("%s%s", v1, v2))
			end
		end
		return tbl
	end
	local tbl = src[1]
	for k = 2, #src do
		tbl = concat(tbl, src[k])
	end
	return tbl
end