local utils = require "bliss.utils"
local dirent = require "posix.dirent"
local stdio = require "posix.stdio"
local unistd = require "posix.unistd"

-- extracts tarball to PWD
local function tar_extract(tarball)
    if not utils.run("tar", {"xf", tarball}) then
        utils.die("failed to extract "..tarball)
    end

    local top = dirent.dir()
    if #top <= 3 then
        for _,v in ipairs(top) do if v ~= "." and v ~= ".." then top = v break end end

        local d = dirent.dir(top)
        for _,file in ipairs(d) do
            if file ~= "." and file ~= ".." then
                assert(file:sub(1,1) ~= "/")
                local ok, e = stdio.rename(top.."/"..file, file)
                if not ok then
                    utils.die("couldn't rename " .. file .. ": " .. e)
                end
            end
        end
    end
end

-- p is a package table as in bliss.build
local function tar_create(env, p)
    utils.log(p.pkg, "Creating tarball")
    unistd.chdir(env.pkg_dir .. "/" .. p.pkg)

    local _tar_file = env.bin_dir .. "/" .. p.pkg .. "@" .. p.ver .. "-" .. p.rel .. ".tar." .. env.COMPRESS

    -- env.COMPRESS is definitely one of the below (checked in utils.setup)
    local compress_map = {
        bz2  = "bzip2 -z",
        gz   = "gzip -6",
        lzma = "lzma -z",
        lz   = "lzip -z",
        xz   = "xz -z",
        zst  = "zstd -z",
    }
    if not utils.run_shell("tar cf - . | " .. compress_map[env.COMPRESS] .. " > " .. _tar_file) then os.exit(false) end

    -- TODO: cd $OLDPWD?

    utils.log(p.pkg, "Successfully created tarball")
end

local M = {
    tar_extract = tar_extract,
    tar_create = tar_create,
}
return M
