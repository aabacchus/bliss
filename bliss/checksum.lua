--- Checksum routines.
-- @module bliss.checksum
local utils = require "bliss.utils"
local b3sum = require "bliss.b3sum"
local pkg = require "bliss.pkg"
local download = require "bliss.download"

--- Get the checksum of a single file.
-- @tparam string filename
-- @treturn string the BLAKE3 checksum of the contents of filename
local function checksum_file(filename)
    local f = assert(io.open(filename))
    local ctx = b3sum.init()
    local buf = f:read(4096)
    while buf do
        b3sum.update(ctx, buf)
        buf = f:read(4096)
    end
    f:close()
    return b3sum.finalize(ctx, 33)
end

--- The checksum action.
-- Generates checksums for all the packages.
-- @tparam env env
-- @tparam table arg list of packages
local function checksum(env, arg)
    if #arg == 0 then utils.die("need a package") end
    for _,p in ipairs(arg) do
        local repo_dir = pkg.find(p, env.PATH)
        local sources = pkg.find_sources(p, repo_dir)
        local cache = pkg.resolve(p, sources, env, repo_dir)

        download.download_sources(env, p, sources, cache)

        local f = assert(io.open(repo_dir .. "/checksums", "w"))

        local sums = ""
        for i, v in ipairs(cache) do
            local map = {["git+"] = 1, ["http"] = 2}
            local t = map[string.sub(sources[i][1], 1, 4)] or 3
            if t ~= 1 then
                local sum = checksum_file(v)
                sums = sums .. sum .. "\n"
            end
        end
        if #sums ~= 0 then
            f:write(sums)
            utils.log(p, "Generated checksums")
        else
            -- TODO: don't make checksum file then
            utils.log(p, "No sources needing checksums")
        end
        f:close()
    end
end

--- Verify all the checksums for a package
-- @tparam string p package name
-- @tparam string repo_dir package directory
-- @tparam table caches list of downloaded files to checksum
local function verify_checksums(p, repo_dir, caches)
    utils.log(p, "Verifying sources")

    local sums = pkg.find_checksums(p, repo_dir)
    for i,v in ipairs(caches) do
        -- TODO: skip git
        local sum = checksum_file(v)
        if #sums[i][1] == 64 then
            utils.die(p, "Detected sha256 checksums")
        end
        if sums[i][1] ~= sum and sums[i] ~= "SKIP" then
            utils.die(p, "checksum mismatch for file " .. v)
        end
    end
end

--- @export
local M = {
    checksum = checksum,
    checksum_file = checksum_file,
    verify_checksums = verify_checksums,
}
return M
