local utils = require "bliss.utils"
local archive = require "bliss.archive"
local pkg = require "bliss.pkg"
local download = require "bliss.download"
local checksum = require "bliss.checksum"
local glob = require "posix.glob"
local libgen = require "posix.libgen"
local unistd = require "posix.unistd"

--[[
-- These functions use a table containing cached package variables:
-- p = {
--     pkg,
--     repo_dir,
--     sources,
--     caches,
--     ver,
--     rel,
-- }
--]]

local function build_extract(env, p)
    if #p.caches == 0 then return end
    utils.log(p.pkg, "Extracting sources")

    for k,v in ipairs(p.caches) do
        utils.mkcd(env.mak_dir.."/"..p.pkg.."/"..(p.sources[k][2] or ""))
        local r = p.sources[k][1]
        if r:match("^git%+") then
            utils.run("cp", {"-PRf", v.."/.", "."})
        elseif r:match("%.tar$")
            or r:match("%.tar%...$")
            or r:match("%.tar%....$")
            or r:match("%.tar%.....$")
            or r:match("%.t.z") then
            archive.tar_extract(v)
        else
            utils.run("cp", {"-PRf", v, "."})
        end
    end
end

local function build_build(env, p)
    local destdir = env.pkg_dir .. "/" .. p.pkg
    utils.mkcd(env.mak_dir.."/"..p.pkg, destdir.."/"..env.pkg_db)
    utils.log(p.pkg, "Starting build")

    -- TODO: tee log

    local build_env = {
        AR = os.getenv("AR") or "ar",
        CC = os.getenv("CC") or "cc",
        CXX = os.getenv("CXX") or "c++",
        NM = os.getenv("NM") or "nm",
        RANLIB = os.getenv("RANLIB") or "ranlib",
        RUSTFLAGS = "--remap-path-prefix="..unistd.getcwd().."=. "..(os.getenv("RUSTFLAGS") or ""),
        GOFLAGS = "-trimpath -modcacherw " .. (os.getenv("GOFLAGS") or ""),
        GOPATH = unistd.getcwd() .. "/go",
    }
    local f = p.repo_dir .. "/build"
    if not utils.run(f, {destdir, p.ver}, build_env) then
        utils.die(p.pkg, "Build failed")
    end

    -- copy repository files to the package directory.
    if not utils.run("cp", {"-LRf", p.repo_dir, destdir .. "/" .. env.pkg_db .. "/"}) then os.exit(false) end

    utils.log(p.pkg, "Successfully built package")
end

local function gen_manifest(env, p)
    utils.log(p.pkg, "Generating manifest")

    -- Instead of running find, walk through the directories ourselves.
    local function recurse_find(dir)
        local mani = {}

        -- Make use of GLOB_MARK to append a slash to directories for us.
        local t = glob.glob(dir, glob.GLOB_MARK)

        for _,v in ipairs(t) do
            if libgen.basename(v) ~= "charset.alias" and v:sub(-3) ~= ".la" then
                table.insert(mani, v)
                if v:sub(-1) == "/" then
                    local m = recurse_find(v .. "*")

                    -- join this result to mani.
                    for i=1,#m do
                        mani[#mani + 1] = m[i]
                    end
                end
            end
        end

        return mani
    end

    local destdir = env.pkg_dir .. "/" .. p.pkg
    local manifest_file = destdir .. "/" .. env.pkg_db .. "/" .. p.pkg .. "/manifest"

    local mani = recurse_find(destdir .. "/*")

    table.insert(mani, manifest_file)
    -- TODO: etcsums

    -- Sort in reverse.
    table.sort(mani, function (a,b) return b < a end)

    -- Remove the prefix from each line and write to the manifest file.
    local f = io.open(manifest_file, "w")
    local prefix_len = string.len(destdir)

    for _,v in ipairs(mani) do
        f:write(v:sub(prefix_len + 1) .. "\n")
    end

    f:close()
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
        local version = pkg.find_version(p, repo_dir)
        local caches = pkg.resolve(p, sources, env, repo_dir)

        download.download_sources(env, p, sources, caches)
        checksum.verify_checksums(p, repo_dir, caches)

        table.insert(db, {pkg = p, repo_dir = repo_dir, sources = sources, caches = caches, ver = version[1], rel = version[2]})
    end

    -- Now build
    for _,p in ipairs(db) do
        build_extract(env, p)
        build_build(env, p)

        gen_manifest(env, p)
        archive.tar_create(env, p)
    end
end

local M = {
    build = build,
}
return M
