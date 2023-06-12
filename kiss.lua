#!/usr/bin/env lua
local kiss = require 'libkiss'

local function version()
    print("0.0.0")
end

local function usage()
    kiss.log(arg[0] .. " [a|b|c|d|i|l|r|s|u|U|v] [pkg]...")
    kiss.log("alternatives List and swap alternatives")
    kiss.log("build        Build packages")
    kiss.log("checksum     Generate checksums")
    kiss.log("download     Download sources")
    kiss.log("install      Install packages")
    kiss.log("list         List installed packages")
    kiss.log("remove       Remove packages")
    kiss.log("search       Search for packages")
    kiss.log("update       Update the repositories")
    kiss.log("upgrade      Update the system")
    kiss.log("version      Package manager version")

    os.exit(true)
end

local function args(arg)
    local args_map = {
        a = kiss.alternatives,
        b = kiss.build,
        c = kiss.checksum,
        d = kiss.download,
        H = kiss.help_ext,
        i = kiss.install,
        l = kiss.list,
        r = kiss.remove,
        s = kiss.search,
        u = kiss.update,
        U = kiss.upgrade,
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

env = kiss.setup()
args(arg)
