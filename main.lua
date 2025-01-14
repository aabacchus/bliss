#!/usr/bin/env lua
--- Executable interface to the bliss library.
-- @script bliss
local bliss = require "bliss"

local function version()
    print(bliss.version)
end

local function usage()
    --- @usage
    local usage = [[bliss [a|b|c|d|i|l|r|s|u|U|v] [pkg]...
    alternatives List and swap alternatives
    build        Build packages
    checksum     Generate checksums
    download     Download sources
    install      Install packages
    list         List installed packages
    remove       Remove packages
    search       Search for packages
    update       Update the repositories
    upgrade      Update the system
    version      Package manager version]]
    print(usage)
    os.exit(true)
end

local function args(env, arg)
    local args_map = {
        a = bliss.alternatives,
        b = bliss.build,
        c = bliss.checksum,
        d = bliss.download,
        H = bliss.help_ext,
        i = bliss.install,
        l = bliss.list,
        r = bliss.remove,
        s = bliss.search,
        u = bliss.update,
        U = bliss.upgrade,
        v = version,
    }

    if #arg < 1 then usage() end

    local char = string.sub(arg[1], 1, 1)
    if arg[1] == "upgrade" then char = "U" end

    if char == "i" or char == "a" or char == "r" then
        local user = bliss.am_not_owner(env.ROOT .. "/")
        if user then
            local newarg = {
                "env",
                "LOGNAME="..user,
                "HOME="..os.getenv("HOME"),
                "XDG_CACHE_HOME="..(os.getenv("XDG_CACHE_HOME") or ""),
                "KISS_COMPRESS="..env.COMPRESS,
                "KISS_PATH="..table.concat(env.PATH, ":"),
                "KISS_FORCE="..env.FORCE,
                "KISS_ROOT="..env.ROOT,
                "KISS_CHOICE="..env.CHOICE,
                "KISS_COLOR="..env.COLOR,
                "KISS_TMPDIR="..env.TMPDIR,
                "KISS_PID="..env.PID,
                "_KISS_LVL="..env._LVL,
                "LUA_PATH="..package.path,
                "LUA_CPATH="..package.cpath,
            }
            table.move(arg, 0, #arg, #newarg+1, newarg)

            bliss.trap_off(env)
            bliss.as_user(env, user, newarg)
            bliss.trap_on(env)
            return
        end
    end

    -- shift
    table.remove(arg, 1)

    -- TODO: pkg_order
    -- TODO: prepend PWD to PATH if no args and action ~= list

    local f = args_map[char]
    if f then
        -- Run in protected mode. This is to catch bugs rather than user-facing
        -- error handling. None of the action functions return a value; we're
        -- only interested in if they fail or succeed.
        if not xpcall(f, function (msg)
            print(msg)
            print(debug.traceback())
        end, env, arg)
        then
            os.exit(1)
        end
    else
        -- TODO: ext
        usage()
    end
end

local env = bliss.setup()
args(env, arg)
env.atexit()
