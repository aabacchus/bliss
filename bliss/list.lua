local pkg = require 'bliss.pkg'
local dirent = require 'posix.dirent'

local function list(env, arg)
    if #arg == 0 then
        for file in dirent.files(env.sys_db) do
            if string.sub(file, 1, 1) ~= '.' then
                table.insert(arg, file)
            end
        end
        table.sort(arg)
    end
    for _,a in ipairs(arg) do
        local ver = pkg.find_version(a, {env.sys_db})
        io.write(string.format("%s %s-%s\n", a, ver[1], ver[2]))
    end
end

local M = {
    list = list,
}
return M
