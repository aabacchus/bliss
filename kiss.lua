#!/usr/bin/env lua
local utils = require 'utils'
--local t = {__index = utils}
--setmetatable(_G, t)

local alternatives, build, checksum, download, help_ext, install, list, remove, update, upgrade, version

function version()
    print("0.0.0")
end

local function usage()
    utils.log(arg[0] .. " [a|b|c|d|i|l|r|s|u|U|v] [pkg]...")
    utils.log("alternatives List and swap alternatives")
    utils.log("build        Build packages")
    utils.log("checksum     Generate checksums")
    utils.log("download     Download sources")
    utils.log("install      Install packages")
    utils.log("list         List installed packages")
    utils.log("remove       Remove packages")
    utils.log("search       Search for packages")
    utils.log("update       Update the repositories")
    utils.log("upgrade      Update the system")
    utils.log("version      Package manager version")

    os.exit(true)
end

local function args(arg)
    local args_map = {
        a = alternatives,
        b = build,
        c = checksum,
        d = download,
        H = help_ext,
        i = install,
        l = list,
        r = remove,
        u = update,
        U = upgrade,
        v = version,
    }

    if #arg < 1 then usage() end

    local char = string.sub(arg[1], 1, 1)
    if arg[1] == "upgrade" then char = 'U' end

    local f = args_map[char]
    if f then
        f()
    else
        -- TODO: ext
        usage()
    end
end

local env = utils.setup()
args(arg)
