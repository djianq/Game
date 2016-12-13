local function search(k, plist)
	for i = 1, #plist do
		local v = plist[i][k]
		if v then return v end
	end
end

function inherit(c, ...)
	local arg = {...}
	setmetatable(c, 
		{
			__index	= function(t, k)
				return search(k, arg)
			end
		}
	)
end

function new(class, o)	
	o = o or {}
	setmetatable(o, {__index = class})
	return o
end

function super(class)
	return getmetatable(class)
end

function import(path)
	env = getfenv(2)
end