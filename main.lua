#!/usr/bin/env lua
local bliss = require 'bliss'

local function version()
    print("0.0.0")
end

local function usage()
    bliss.log("bliss [a|b|c|d|i|l|r|s|u|U|v] [pkg]...")
    bliss.log("alternatives List and swap alternatives")
    bliss.log("build        Build packages")
    bliss.log("checksum     Generate checksums")
    bliss.log("download     Download sources")
    bliss.log("install      Install packages")
    bliss.log("list         List installed packages")
    bliss.log("remove       Remove packages")
    bliss.log("search       Search for packages")
    bliss.log("update       Update the repositories")
    bliss.log("upgrade      Update the system")
    bliss.log("version      Package manager version")

    os.exit(true)
end

local function args(arg)
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
    if arg[1] == "upgrade" then char = 'U' end

    -- shift
    table.remove(arg, 1)

    local f = args_map[char]
    if f then
        f(env, arg)
    else
        -- TODO: ext
        usage()
    end
end

env = bliss.setup()
args(arg)
