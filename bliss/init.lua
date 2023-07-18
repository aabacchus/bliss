local cwd = (...):gsub("%.init$", "")

local M = {}

-- merge these into the toplevel bliss module
local names = {"utils", "search", "list", "pkg", "download", "checksum", "build", "install"}
for _, name in ipairs(names) do
    local t = require(cwd .. "." .. name)
    for k, v in pairs(t) do
        M[k] = v
    end
end

-- add these into submodules
names = {"b3sum"}
for _, name in ipairs(names) do
    M[name] = require(cwd .. "." .. name)
end

return M
