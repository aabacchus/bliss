--- Downloading routines.
-- @module bliss.download
local utils = require "bliss.utils"
local pkg = require "bliss.pkg"
local sys_stat = require "posix.sys.stat"
local libgen = require "posix.libgen"

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
            aria2c = {"-d", "/", "-o"},
            axel = {"-o"},
            curl = {"-fLo"},
            wget = {"-O"},
            wget2 = {"-O"},
        }
        local args = args_map[libgen.basename(env.GET)] or utils.die("'"..env.GET.."' is unsupported as KISS_GET")

        sys_stat.mkdir(libgen.dirname(dest))
        utils.log(p, "Downloading " .. source)

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

--- Download each source to dest.
-- Currently handles http, git, and local files.
-- @tparam env env
-- @tparam string p package name (just used as a label for log messages)
-- @tparam table sources list of sources
-- @tparam table dests list of destinations
local function download_sources(env, p, sources, dests)
    assert(#dests == #sources)

    local map = {["git+"] = git, ["http"] = http}

    for k,v in ipairs(sources) do
        local f = map[string.sub(v[1], 1, 4)] or file
        f(env, p, v[1], dests[k])
    end
end

--- The download action.
-- @tparam env env
-- @tparam table arg list of packages to download sources for
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

--- @export
local M = {
    download = download,
    download_sources = download_sources,
}
return M
