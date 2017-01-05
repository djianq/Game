local xml = require"xml"
local pretty = require"pl.pretty"
local utils = require"pl.utils"
local dir = require"pl.dir"
local path = require"pl.path"
local stringx = require"pl.stringx"

function xml2lua(file_name)
	local d = xml.parse(file_name, true, true)
	--pretty.dump(d)

	local outTab = {}

	for k, v in pairs(d) do
		if v.tag and v.tag == "path" then
			local attr = v.attr
			local d = attr.d
			local t = string.sub(d, 1, 1)
			d = string.sub(d, 3, string.len(d) - 2)
			local x = 0 --tonumber(attr.x)
			local y = 0 --tonumber(attr.y)
			local w = 0 --tonumber(attr.width)
			local h = 0 --tonumber(attr.height)

			local label = tonumber(attr["inkscape:label"])
			local rect ={label = label}
			for i, pos in pairs(stringx.split(d, " ")) do
				local p = stringx.split(pos, ",")
				local thepos = {}
				for k, coord in pairs(p) do
					thepos[k] = tonumber(coord)
				end
				rect[i] = thepos
				if t == "m" and rect[i - 1] then
					rect[i][1] = rect[i][1] + rect[i - 1][1]
					rect[i][2] = rect[i][2] + rect[i - 1][2]
				end
			end
			pretty.dump(rect)
			table.insert(outTab, rect)
		end
	end
	--pretty.dump(outTab)
	utils.writefile(path.splitext(path.basename(file_name))..".lua","return\n"..pretty.write(outTab))
	return d ~= nil
end

local files = {"env_audio_1211.svg"}

for _, f in pairs(files) do
	if not f:find("library") then
		print(f)
		if not xml2lua(f) then
			print("ERROR!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		end
	end
end


