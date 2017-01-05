local SRC_PATH = "..\\..\\SÊýÖµ±í\\xlsdict\\"
local DST_PATH = "l:\\running\\logic\\setting\\ai\\"

local xml = require"xml"
local pretty = require"pl.pretty"
local utils = require"pl.utils"
local dir = require"pl.dir"
local path = require"pl.path"

function xml2lua(file_name)
	local d = xml.parse(file_name, true, true)
	utils.writefile(DST_PATH .. path.splitext(path.basename(file_name))..".lua","return\n"..pretty.write(d))
end

local files = dir.getallfiles(SRC_PATH, "*.xml" )

for _, f in pairs(files) do
	if not f:find("library") then
		print(f)
		xml2lua(f)
	end
end

--local a = dofile("22000.lua")
--print(a.tag, a.attr, #a)
--print(a[1].tag, a[1].attr.Name, #a[1])
