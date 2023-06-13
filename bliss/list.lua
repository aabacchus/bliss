local cwd = (...):gsub('%.[^%.]+$', '')
local utils = require(cwd .. '.utils')
local dirent = require 'posix.dirent'

local function pkg_version(env, pkg)
    local v = env.pkg_db .. '/' .. pkg .. "/version"
    local f = io.open(v, 'r')
    if not f then utils.die("'"..pkg.."' not found") end
    local ver = f:read()
    f:close()
    if not ver then utils.die(pkg, "error reading version") end
    return utils.split(ver, ' ')
end

local function list(env, arg)
    if #arg == 0 then
        for file in dirent.files(env.pkg_db) do
            if string.sub(file, 1, 1) ~= '.' then
                table.insert(arg, file)
            end
        end
        table.sort(arg)
    end
    for _,pkg in ipairs(arg) do
        local ver = pkg_version(env, pkg)
        io.write(string.format("%s %s-%s\n", pkg, ver[1], ver[2]))
    end
end

local M = {
    list = list,
}
return M
