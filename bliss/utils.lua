-- Copyright 2023 phoebos
local sys_stat = require 'posix.sys.stat'
local unistd = require 'posix.unistd'

local colors = {"", "", ""}
local setup, setup_colors, check_execute, get_available, split, mkdirp, log, warn, die, run, capture, shallowcopy

function setup()
    colors = setup_colors()
    check_execute()

    local env = {
        CHK     = os.getenv("KISS_CHK")
                    or get_available("openssl", "sha256sum", "sha256", "shasum", "digest")
                    or warn("No sha256 utility found"),
        COMPRESS= os.getenv("KISS_COMPRESS") or "gz",
        DEBUG   = os.getenv("KISS_DEBUG"),
        FORCE   = os.getenv("KISS_FORCE"),
        GET     = os.getenv("KISS_GET")
                    or get_available("aria2c", "axel", "curl", "wget", "wget2")
                    or warn("No download utility found (aria2c, axel, curl, wget, wget2"),
        HOOK    = split(os.getenv("KISS_HOOK"), ':'),
        KEEPLOG = os.getenv("KISS_KEEPLOG"),
        PATH    = split(os.getenv("KISS_PATH"), ':'),
        PID     = os.getenv("KISS_PID") or unistd.getpid(),
        PROMPT  = os.getenv("KISS_PROMPT"),
        ROOT    = os.getenv("KISS_ROOT") or "",
        SU      = os.getenv("KISS_SU") or get_available("ssu", "sudo", "doas", "su"),
        TMPDIR  = os.getenv("KISS_TMPDIR"),
        time    = os.date("%Y-%m-%d-%H:%M"),
    }
    -- pkg_db depends on ROOT so must be set after env is constructed
    env.pkg_db  = env.ROOT .. "/var/db/kiss/installed"

    mkdirp(env.ROOT .. '/')
    return env
end

function setup_colors()
    local t = {}
    if os.getenv("KISS_COLOR") ~= "0" then
        t[1] = "\x1B[1;33m"
        t[2] = "\x1B[1;34m"
        t[3] = "\x1B[m"
    end
    return t
end

function check_execute()
    if not os.execute() then die("cannot execute shell commands") end
end

function get_available(...)
    local x, p, res
    for i = 1, select('#', ...) do
        x = select(i, ...)
        res = capture("command -v " .. x)
        if res[1] then return res[1] end
    end
    return nil
end

function split(s, sep)
    local c = {}
    for a in string.gmatch(s, "[^%s"..sep.."]+") do
        table.insert(c, a)
    end
    return c
end

function mkdirp(path)
    assert(string.sub(path, 1, 1) == '/')
    local t = split(path, '/')
    local p = ''
    for _, v in ipairs(t) do
        p = p .. '/' .. v

        local sb = sys_stat.stat(p)
        if not sb then
            local c, msg = sys_stat.mkdir(p)
            if not c then die("mkdir " .. msg) end
        end
    end
end

function log(name, msg, category)
    -- This is a direct translation of kiss's log(). Quite hacky.
    io.stderr:write(string.format("%s%s %s%s%s %s\n",
        colors[1],
        category or "->",
        colors[3] .. (msg and colors[2] or ''),
        name,
        colors[3],
        msg or ""))
end

function warn(name, msg)
    log(name, msg, "WARNING")
end

function die(name, msg)
    log(name, msg, "ERROR")
    os.exit(false)
end

function run(cmd)
    io.stderr:write(cmd.."\n")
    -- faster to use fork + posix.unistd.execp?
    local res, ty, code = os.execute(cmd)
    return res
end

-- Returns an array of lines printed by cmd
function capture(cmd)
    local p = io.popen(cmd, 'r')
    local res = {}
    for line in p:lines() do
        table.insert(res, line)
    end
    return res
end

function shallowcopy(t)
    local u = {}
    for k,v in pairs(t) do u[k] = v end
    return t
end

local M = {
    setup       = setup,
    split       = split,
    mkdirp      = mkdirp,
    log         = log,
    warn        = warn,
    die         = die,
    run         = run,
    capture     = capture,
    shallowcopy = shallowcopy,
}

return M
