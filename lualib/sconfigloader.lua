local serialize = require "serialize.core"

local loader = {}

function loader.save(name, config)
	local s = serialize.pack(config)
	serialize.savepack(s, name)
end

function loader.load(name)
	local p = serialize.loadpack(name)
	local s = serialize.unpack(p)

	return s
end

return loader

