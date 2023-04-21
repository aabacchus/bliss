local utils = require "utils"

local env = utils.setup()
for k,v in pairs(env) do print(k,v) end
