--- Install a built package.
-- @module bliss.install
local archive = require "bliss.archive"
local utils = require "bliss.utils"
local pkg = require "bliss.pkg"
local libgen = require "posix.libgen"
local sys_stat = require "posix.sys.stat"

--- The install action.
-- @tparam env env
-- @tparam table arg
local function install(env, arg)
    if #arg == 0 then end

    for _,p in ipairs(arg) do
        local pkgname, tarfile
        if string.match(p, "%.tar%.") then
            -- p is a path to a tarball.
            if not sys_stat.stat(p) then
                utils.die("File '" .. p .. "' does not exist")
            end
            pkgname = string.match(p, ".*/(.-)@")
            tarfile = p
        else
            local path = utils.shallowcopy(env.PATH)
            table.insert(path, env.sys_db)

            local repo_dir = pkg.find(p, path)
            local version = pkg.find_version(p, repo_dir)
            tarfile = pkg.iscached(env, p, version)
            if not tarfile then
                utils.die(p, "Not yet built")
            end
            pkgname = p
        end

        utils.trap_off(env)
        utils.mkcd(env.tar_dir .. "/" .. pkgname)

        archive.tar_extract(tarfile)
        local tar_man = env.tar_dir.."/"..pkgname.."/"..env.pkg_db.."/"..pkgname.."/manifest"
        if not sys_stat.stat(tar_man) then
            utils.die("Not a valid KISS package (no manifest file)")
        end

        if env.FORCE ~= 1 then
            -- check installable
        end

        -- TODO: alternatives

        utils.log(pkgname, "Installing package ("..libgen.basename(tarfile)..")")

        local tar_manifest = pkg.read_lines(tar_man)
        for k,v in ipairs(tar_manifest) do tar_manifest[k] = v[1] end
        table.sort(tar_manifest)

        -- PWD must contain the files
        local function iterate_files(env, tar_manifest, pkgname)
            for _, file in ipairs(tar_manifest) do
                local _file = env.ROOT .. file

                if file:sub(-1) == "/" then
                    -- Directory
                    if not sys_stat.stat(_file) then
                        local mode = sys_stat.stat("./"..file).st_mode
                        local c,msg = sys_stat.mkdir(_file, mode)
                        if not c then utils.die("mkdir "..msg) end
                    end
                else
                    if file:match("^/etc/") then
                        -- TODO: compare checksums
                        warn(pkgname, "saving "..file.." as "..file..".new")
                        _file = _file .. ".new"
                    end

                    local dirname = libgen.dirname(_file)
                    local sb = sys_stat.stat(_file)
                    if sb and sys_stat.S_ISLNK(sb.st_mode) ~= 0 then
                        if not utils.run_quiet("cp", {"-fP", "./"..file, dirname .. "/."}) then os.exit(false) end
                    else
                        local _tmp_file = dirname.."/__bliss-tmp-"..pkgname.."-"..libgen.basename(file).."-"..env.PID

                        if not utils.run_quiet("cp", {"-fP", "./"..file, _tmp_file}) or
                            not utils.run_quiet("mv", {"-f", _tmp_file, _file}) then
                            -- run pkg_clean
                            env.atexit()

                            utils.log(pkgname, "Failed to install package", "ERROR")
                            utils.die(pkgname, "Filesystem now dirty, manual repair needed.")
                        end
                    end
                end
            end
        end

        -- TODO: diff manifests, remove old files, verify new files
        --[[
        eg.
        if isinstalled(pkgname) then
            diff, remove
        end
        --]]
        iterate_files(env, tar_manifest, pkgname)

        utils.trap_on(env)
        utils.log(pkgname, "Installed successfully")
    end
end

--- @export
local M = {
    install = install,
}
return M
