local utils = require 'bliss.utils'
local search = require 'bliss.search'
local sys_stat = require 'posix.sys.stat'

local function read_lines(file)
    local t = {}
    local f = io.open(file)
    if not f then return {} end
    for line in f:lines() do
        table.insert(t, utils.split(line, ' '))
    end
    f:close()
    return t
end

local function find(name, path)
    for _, repo in ipairs(path) do
        local g = repo .. '/' .. name
        local sb = sys_stat.stat(g)
        if sb and sys_stat.S_ISDIR(sb.st_mode) ~= 0 then
            return g
        end
    end
    utils.die("'"..name.."' not found")
end

local function find_version(pkg, path)
    local pkgpath = find(pkg, path)
    local v = pkgpath .. "/version"

    local ver = read_lines(v)
    if #ver == 0 then utils.die(pkg, "error reading version") end

    return ver[1]
end

local function find_sources(pkg, path)
    local pkgpath = find(pkg, path)
    local p = pkgpath .. "/sources"

    local s = read_lines(p)
    if #s == 0 then utils.log(pkg, "no sources found") end
    return s
end

local M = {
    find = find,
    find_version = find_version,
    find_sources = find_sources,
}
return M
