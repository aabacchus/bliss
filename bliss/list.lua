--- List packages.
-- @module bliss.list
local pkg = require "bliss.pkg"
local dirent = require "posix.dirent"
local sys_stat = require "posix.sys.stat"

--- The list action.
-- @tparam env env
-- @tparam table arg list of packages to search. If none, list all packages.
local function list(env, arg)
    if #arg == 0 and sys_stat.stat(env.sys_db) then
        for file in dirent.files(env.sys_db) do
            if string.sub(file, 1, 1) ~= "." then
                table.insert(arg, file)
            end
        end
        table.sort(arg)
    end
    for _,a in ipairs(arg) do
        local repo_dir = env.sys_db .. "/" .. a
        local ver = pkg.find_version(a, repo_dir)

        io.write(string.format("%s %s-%s\n", a, ver[1], ver[2]))
    end
end

--- @export
local M = {
    list = list,
}
return M
