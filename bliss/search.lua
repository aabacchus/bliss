local cwd = (...):gsub('%.[^%.]+$', '')
local utils = require(cwd .. '.utils')

local function search(env, arg)

    -- prepend pkg_db to search path
    local path = utils.shallowcopy(env.PATH)
    table.insert(path, 1, env.pkg_db)

    for _, repo in ipairs(path) do
        print(repo)
    end
end

local M = {
    search = search,
}
return M
