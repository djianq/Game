local skynet = require "skynet"
local snax = require "snax"

skynet.start(function()
    local ps = snax.newservice("pingserver", "hello world")
end)