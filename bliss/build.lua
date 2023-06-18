local utils = require 'bliss.utils'
local archive = require 'bliss.archive'
local pkg = require 'bliss.pkg'
local download = require 'bliss.download'
local checksum = require 'bliss.checksum'

--[[
-- These functions use a table containing cached package variables:
-- p = {
--     pkg,
--     repo_dir,
--     sources,
--     caches
-- }
--]]

local function build_extract(env, p)
    if #p.caches == 0 then return end
    utils.log(p.pkg, "Extracting sources")

    for k,v in ipairs(p.caches) do
        utils.mkcd(env.mak_dir..'/'..p.pkg..'/'..(p.sources[k][2] or ''))
        local r = p.sources[k][1]
        if r:match("^git%+") then
            utils.run("cp -PRf '" .. v .. "/.' .")
        elseif r:match("%.tar$")
            or r:match("%.tar%...$")
            or r:match("%.tar%....$")
            or r:match("%.tar%.....$")
            or r:match("%.t.z") then
            archive.tar_extract(v)
        else
            utils.run("cp -PRf '" .. v .. "' .")
        end
    end
end

local function build_build(env, p)
    utils.mkcd(env.mak_dir..'/'..p.pkg, env.pkg_dir..'/'..p.pkg..'/'..env.pkg_db)
    utils.log(p.pkg, "Starting build")

    local f = p.repo_dir .. '/build'
    if not utils.run(f .. " " ..env.pkg_dir..'/'..p.pkg) then
        utils.die(p.pkg, "Build failed")
    end
end

local function build(env, arg)
    if #arg == 0 then end -- TODO

    local db = {}

    -- TODO: depends, order, check cache

    -- First, download and verify sources
    for _,p in ipairs(arg) do
        -- append sys_db
        local path = utils.shallowcopy(env.PATH)
        table.insert(path, env.sys_db)

        local repo_dir = pkg.find(p, path)
        local sources = pkg.find_sources(p, repo_dir)
        local caches = pkg.resolve(p, sources, env, repo_dir)

        download.download_sources(env, p, sources, caches)
        checksum.verify_checksums(p, repo_dir, caches)

        table.insert(db, {pkg = p, repo_dir = repo_dir, sources = sources, caches = caches})
    end

    -- Now build
    for _,p in ipairs(db) do
        build_extract(env, p)
        build_build(env, p)

        --local mani = manifest(env.pkg_dir, p)
    end
end

local M = {
    build = build,
}
return M
