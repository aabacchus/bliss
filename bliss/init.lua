local cwd = (...):gsub('%.init$', '')

local M = {}

local names = {'utils', 'search', 'list'}
for i = 1, #names do
    local name = names[i]
    local t = require(cwd .. '.' .. name)
    for k, v in pairs(t) do
        M[k] = v
    end
end

return M
