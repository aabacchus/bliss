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

local function find_sources(pkg, repo_dir)
    local p = repo_dir .. "/sources"

    local s = read_lines(p)
    if #s == 0 then utils.log(pkg, "no sources found") end
    return s
end

local function resolve_git(pkg, source, env)
    local fp = string.match(source[1], '/([^/]+)$')
    if not fp then  utils.die(pkg, "can't parse source '"..source[1].."'") end
    fp = string.match(fp, '(.*)[@#]') or fp -- this follows kiss, but should it be (.-) (ie. shortest match)?
    return env.src_dir .. '/' .. pkg .. '/' .. (source[2] and source[2] .. '/' or '') .. fp .. '/'
end

local function resolve_http(pkg, source, env)
    -- get file part of URL
    local fp = string.match(source[1], '/([^/]+)$')
    if not fp then utils.die(pkg, "can't parse source '" .. source[1] .. "'") end
    return env.src_dir .. '/' .. pkg .. '/' .. (source[2] and source[2] .. '/' or '') .. fp
end

local function resolve_file(pkg, source, env, repo_dir)
    local f = repo_dir .. '/' .. source[1]
    if not sys_stat.stat(f) then utils.die(pkg, "source '"..source[1].."' not found") end
    return f
end

-- returns an array of the cache locations corresponding to each source
local function resolve(pkg, sources, env, repo_dir)
    local map = {
        ["git+"] = resolve_git,
        ["http"] = resolve_http,
    }
    local caches = {}

    for _, v in ipairs(sources) do
        local f = map[v[1]:sub(1, 4)] or resolve_file
        local c = f(pkg, v, env, repo_dir)
        if c then table.insert(caches, c) end
    end
    return caches
end

local M = {
    find = find,
    find_version = find_version,
    find_sources = find_sources,
    resolve = resolve,
}
return M
