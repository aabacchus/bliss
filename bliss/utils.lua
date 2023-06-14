-- Copyright 2023 phoebos
local sys_stat = require 'posix.sys.stat'
local unistd = require 'posix.unistd'
local signal = require 'posix.signal'

local colors = {"", "", ""}
local setup, setup_colors, check_execute, get_available, trap_on, trap_off, split, mkdirp, rm_rf, log, warn, die, run, capture, shallowcopy

function setup()
    colors = setup_colors()
    check_execute()

    local env = {
        _LVL    = 1 + (os.getenv("_KISS_LVL") or 0),
        CHK     = os.getenv("KISS_CHK")
                    or get_available("openssl", "sha256sum", "sha256", "shasum", "digest")
                    or warn("No sha256 utility found"),
        COMPRESS= os.getenv("KISS_COMPRESS") or "gz",
        DEBUG   = os.getenv("KISS_DEBUG") or 0,
        FORCE   = os.getenv("KISS_FORCE") or 0,
        GET     = os.getenv("KISS_GET")
                    or get_available("aria2c", "axel", "curl", "wget", "wget2")
                    or warn("No download utility found (aria2c, axel, curl, wget, wget2"),
        HOOK    = split(os.getenv("KISS_HOOK"), ':'),
        KEEPLOG = os.getenv("KISS_KEEPLOG") or 0,
        PATH    = split(os.getenv("KISS_PATH"), ':'),
        PID     = os.getenv("KISS_PID") or unistd.getpid(),
        PROMPT  = os.getenv("KISS_PROMPT") or 1,
        ROOT    = os.getenv("KISS_ROOT") or "",
        SU      = os.getenv("KISS_SU") or get_available("ssu", "sudo", "doas", "su"),
        TMPDIR  = os.getenv("KISS_TMPDIR"),
        time    = os.date("%Y-%m-%d-%H:%M"),
    }
    -- sys_db depends on ROOT so must be set after env is constructed
    env.pkg_db  = "var/db/kiss/installed"
    env.cho_db  = "var/db/kiss/choices"
    env.sys_db  = env.ROOT .. "/" .. env.pkg_db
    env.sys_ch  = env.ROOT .. "/" .. env.cho_db

    env.cac_dir = (os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")) .. "/kiss"
    env.src_dir = env.cac_dir .. "/sources"
    env.log_dir = env.cac_dir .. "/logs/" .. string.sub(env.time, 1, 10)
    env.bin_dir = env.cac_dir .. "/bin"

    env.TMPDIR  = env.TMPDIR or (env.cac_dir .. "/proc")
    env.proc    = env.TMPDIR .. '/' .. env.PID

    env.mak_dir = env.proc .. "/build"
    env.pkg_dir = env.proc .. "/pkg"
    env.tar_dir = env.proc .. "/extract"
    env.tmp_dir = env.proc .. "/tmp"

    mkdirp(env.ROOT .. '/')
    mkdirp(env.src_dir, env.log_dir, env.bin_dir,
        env.mak_dir, env.pkg_dir, env.tar_dir, env.tmp_dir)

    -- make sure os.exit always closes the Lua state
    local o = os.exit
    os.exit = function(code, close) o(code, not close) end

    local atexit = trap_on(env)
    return env, atexit
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

function trap_on(env)
    signal.signal(signal.SIGINT, function () os.exit(false) end)
    -- use a finalizer to get pkg_clean to run on EXIT. A reference to atexit must
    -- be kept for the whole duration of the program (should it be a global?)
    local atexit = setmetatable({}, {__gc = get_pkg_clean(env)})
    return atexit
end

function trap_off(atexit)
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    setmetatable(atexit, {})
end

-- returns a function with cached env so that it can be called without args or globals.
function get_pkg_clean(env)
    return function ()
        if env.DEBUG ~= 0 then return end
        if env._LVL == 1 then
            rm_rf(env.proc)
        else
            rm_rf(env.tar_dir)
        end
    end
end

function split(s, sep)
    local c = {}
    for a in string.gmatch(s, "[^%s"..sep.."]+") do
        table.insert(c, a)
    end
    return c
end

function mkdirp(...)
    for i = 1, select('#', ...) do
        local path = select(i, ...)
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
end

function rm_rf(path)
    os.execute("rm -rf \"" .. path .. "\"")
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
    trap_on     = trap_on,
    trap_off    = trap_off,
    split       = split,
    mkdirp      = mkdirp,
    rm_rf       = rm_rf,
    log         = log,
    warn        = warn,
    die         = die,
    run         = run,
    capture     = capture,
    shallowcopy = shallowcopy,
}

return M
