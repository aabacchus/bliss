local utils = require "bliss.utils"
local tsort = require "bliss.tsort"
local glob = require "posix.glob"
local sys_stat = require "posix.sys.stat"

local function read_lines(file)
    local t = {}
    local f = io.open(file)
    if not f then return {} end
    for line in f:lines() do
        if #line ~= 0 and string.sub(line, 1, 1) ~= "#" then
            table.insert(t, utils.split(line, " "))
        end
    end
    f:close()
    return t
end

local function find(name, path)
    for _, repo in ipairs(path) do
        local g = repo .. "/" .. name
        local sb = sys_stat.stat(g)
        if sb and sys_stat.S_ISDIR(sb.st_mode) ~= 0 then
            return g
        end
    end
    utils.die("'"..name.."' not found")
end

local function isinstalled(env, name)
    local sb = sys_stat.stat(env.sys_db .. "/" .. name)
    return not not sb
end

local function iscached(env, pkg, version)
    local f = env.bin_dir .. "/" .. pkg .. "@" .. version[1] .. "-" .. version[2] .. ".tar."
    local myglob = f .. "*"
    local f = f .. env.COMPRESS

    local sb = sys_stat.stat(f)
    if sb then
        return true
    else
        local g = glob.glob(myglob, 0)
        return not not g
    end
end

local function find_version(pkg, repo_dir)
    local v = repo_dir .. "/version"

    local ver = read_lines(v)
    if #ver == 0 then utils.die(pkg, "error reading version") end

    return ver[1]
end

local function find_checksums(pkg, repo_dir)
    local p = repo_dir .. "/checksums"
    return read_lines(p)
end

local function find_depends(pkg, repo_dir)
    local p = repo_dir .. "/depends"
    return read_lines(p)
end

local function find_sources(pkg, repo_dir)
    utils.log(pkg, "Reading sources")

    local p = repo_dir .. "/sources"

    local s = read_lines(p)
    if #s == 0 then utils.log(pkg, "no sources found") end
    return s
end

local function resolve_git(pkg, source, env)
    local fp = string.match(source[1], "/([^/]+)$")
    if not fp then  utils.die(pkg, "can't parse source '"..source[1].."'") end
    fp = string.match(fp, "(.*)[@#]") or fp -- this follows kiss, but should it be (.-) (ie. shortest match)?
    return env.src_dir .. "/" .. pkg .. "/" .. (source[2] and source[2] .. "/" or "") .. fp .. "/"
end

local function resolve_http(pkg, source, env)
    -- get file part of URL
    local fp = string.match(source[1], "/([^/]+)$")
    if not fp then utils.die(pkg, "can't parse source '" .. source[1] .. "'") end
    return env.src_dir .. "/" .. pkg .. "/" .. (source[2] and source[2] .. "/" or "") .. fp
end

local function resolve_file(pkg, source, env, repo_dir)
    local f = repo_dir .. "/" .. source[1]
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

local function recurse_all_deps(env, pkgs, deps)
    for _, p in ipairs(pkgs) do
        if not deps[p] then
            local d = find_depends(p, find(p, env.PATH))
            -- ignore make, just get pkg names
            local d_ = {}
            for _,v in ipairs(d) do
                table.insert(d_, v[1])
            end

            -- recurse
            deps = recurse_all_deps(env, d_, deps)

            deps[p] = d_
        end
    end
    return deps
end

local function order(env, pkgs)
    local t = tsort.new()

    local deps = recurse_all_deps(env, pkgs, {})
    for k,v in pairs(deps) do
        t:add(k, v)
    end

    local s, x,y = t:sort()
    if not s then
        utils.die("Circular dependency detected: " .. x .. " <> " .. y)
    end

    -- return s reversed (in order to be built)
    local r = {}
    for i = #s, 1, -1 do
        table.insert(r, s[i])
    end
    return r
end

local M = {
    find = find,
    isinstalled = isinstalled,
    iscached = iscached,
    find_version = find_version,
    find_checksums = find_checksums,
    find_depends = find_depends,
    find_sources = find_sources,
    resolve = resolve,
    order = order,
}
return M
