local utils = require 'bliss.utils'
local pkg = require 'bliss.pkg'
local sys_stat = require 'posix.sys.stat'
local libgen = require 'posix.libgen'

local function git(env, p, source, dest)
    utils.die("git is not yet supported")
end

local function http(env, p, source, dest)
    local sb = sys_stat.stat(dest)
    if sb then
        print("found " .. dest)
    else
        -- TODO: use a library?
        if not env.GET then utils.die("No http download utility available") end
        local args_map = {
            aria2c = {'-d', '/', '-o'},
            axel = {'-o'},
            curl = {'-fLo'},
            wget = {'-O'},
            wget2 = {'-O'},
        }
        local args = args_map[libgen.basename(env.GET)] or utils.die("'"..env.GET.."' is unsupported as KISS_GET")

        --TODO: tmp file
        table.insert(args, dest)
        table.insert(args, source)
        if not utils.run(env.GET, args) then
            utils.die(p, "Failed to download " .. source)
        end
    end
end

local function file(env, p, source, dest)
    local sb = sys_stat.stat(dest)
    if sb then
        print("found " .. dest)
    else
        utils.die(p, "No local file '"..dest.."'")
    end
end

-- download each source to dest.
local function download_sources(env, p, sources, dests)
    assert(#dests == #sources)

    local map = {['git+'] = git, ['http'] = http}

    for k,v in ipairs(sources) do
        local f = map[string.sub(v[1], 1, 4)] or file
        f(env, p, v[1], dests[k])
    end
end

-- this is the download action (ie. kiss d)
local function download(env, arg)
    if #arg == 0 then return end -- TODO

    -- append sys_db to search path
    local path = utils.shallowcopy(env.PATH)
    table.insert(path, env.sys_db)

    for _,p in ipairs(arg) do
        local repo_dir = pkg.find(p, path)
        local sources = pkg.find_sources(p, repo_dir)
        local dests = pkg.resolve(p, sources, env, repo_dir)

        download_sources(env, p, sources, dests)
    end
end

local M = {
    download = download,
    download_sources = download_sources,
}
return M
