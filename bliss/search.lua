--- Package searching.
-- @module bliss.search
local utils = require "bliss.utils"
local glob = require "posix.glob"
local sys_stat = require "posix.sys.stat"

--- The search action.
-- @tparam env env
-- @tparam table arg list of search queries
local function search(env, arg)

    -- append sys_db to search path
    local path = utils.shallowcopy(env.PATH)
    table.insert(path, env.sys_db)

    for _, a in ipairs(arg) do
        local res = {}
        for _, repo in ipairs(path) do
            local g = glob.glob(repo .. "/" .. a, 0)

            for _, i in pairs(g or {}) do
                local sb = sys_stat.stat(i)

                if sb and sys_stat.S_ISDIR(sb.st_mode) ~= 0 then
                    table.insert(res, i)
                end
            end
        end

        if #res == 0 then
            utils.die("'"..a.."' not found")
        end

        for _, v in ipairs(res) do print(v) end
    end
end

--- @export
local M = {
    search = search,
}
return M
