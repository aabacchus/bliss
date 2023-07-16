-- Copyright 2023 phoebos
local sys_stat = require "posix.sys.stat"
local sys_wait = require "posix.sys.wait"
local unistd = require "posix.unistd"
local stdlib = require "posix.stdlib"
local signal = require "posix.signal"

local colors = {"", "", ""}
local setup, setup_colors, check_execute, get_available, get_pkg_clean, trap_on, trap_off, split, mkdirp, mkcd, rm_rf, log, warn, die, prompt, run_shell, run, capture, shallowcopy

function setup()
    colors = setup_colors()
    check_execute()

    local env = {
        _LVL    = 1 + (os.getenv("_KISS_LVL") or 0),
        CHK     = os.getenv("KISS_CHK")
                    or get_available("openssl", "sha256sum", "sha256", "shasum", "digest")
                    or warn("No sha256 utility found"),
        COMPRESS= os.getenv("KISS_COMPRESS") or "gz",
        DEBUG   = tonumber(os.getenv("KISS_DEBUG")) or 0,
        FORCE   = tonumber(os.getenv("KISS_FORCE")) or 0,
        GET     = os.getenv("KISS_GET")
                    or get_available("aria2c", "axel", "curl", "wget", "wget2")
                    or warn("No download utility found (aria2c, axel, curl, wget, wget2"),
        HOOK    = split(os.getenv("KISS_HOOK"), ":"),
        KEEPLOG = tonumber(os.getenv("KISS_KEEPLOG")) or 0,
        PATH    = split(os.getenv("KISS_PATH"), ":"),
        PID     = os.getenv("KISS_PID") or unistd.getpid(),
        PROMPT  = tonumber(os.getenv("KISS_PROMPT")) or 1,
        ROOT    = os.getenv("KISS_ROOT") or "",
        SU      = os.getenv("KISS_SU") or get_available("ssu", "sudo", "doas", "su"),
        TMPDIR  = os.getenv("KISS_TMPDIR"),
        time    = os.date("%Y-%m-%d-%H:%M"),
    }

    local permitted_compress = {bz2 = true, gz = true, lzma = true, lz = true, xz = true, zst = true}
    if not permitted_compress[env.COMPRESS] then
        die("KISS_COMPRESS='"..env.COMPRESS.."' is not permitted (bz2, gz, lzma, lz, xz, zst)")
    end

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
    env.proc    = env.TMPDIR .. "/" .. env.PID

    env.mak_dir = env.proc .. "/build"
    env.pkg_dir = env.proc .. "/pkg"
    env.tar_dir = env.proc .. "/extract"
    env.tmp_dir = env.proc .. "/tmp"

    mkdirp(env.ROOT .. "/")
    mkdirp(env.src_dir, env.log_dir, env.bin_dir,
        env.mak_dir, env.pkg_dir, env.tar_dir, env.tmp_dir)

    -- make sure os.exit always closes the Lua state
    local o = os.exit
    os.exit = function(code, close) o(code, not close) end

    trap_on(env)
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
    local x, res
    for i = 1, select("#", ...) do
        x = select(i, ...)
        res = capture("command -v " .. x)
        if res[1] then return res[1] end
    end
    return nil
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

function trap_on(env)
    signal.signal(signal.SIGINT, function () os.exit(false) end)
    -- use a finalizer to get pkg_clean to run on EXIT. A reference to atexit must
    -- be kept for the whole duration of the program (should it be a global?)
    env.atexit = setmetatable({}, {__gc = get_pkg_clean(env)})
    return env.atexit
end

function trap_off(env)
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    setmetatable(env.atexit, {})
end

function split(s, sep)
    local c = {}
    for a in string.gmatch(s, "[^%s"..sep.."]+") do
        table.insert(c, a)
    end
    return c
end

function mkdirp(...)
    for i = 1, select("#", ...) do
        local path = select(i, ...)
        local sb = sys_stat.stat(path)
        if sb then
            if sys_stat.S_ISDIR(sb.st_mode) == 0 then
                die("'" .. path .. "' already exists and is not a directory")
            end
            goto continue
        end

        assert(string.sub(path, 1, 1) == "/")
        local t = split(path, "/")
        local p = ""
        for _, v in ipairs(t) do
            p = p .. "/" .. v

            local sb = sys_stat.stat(p)
            if not sb then
                local c, msg = sys_stat.mkdir(p)
                if not c then die("mkdir " .. msg) end
            end
        end
        ::continue::
    end
end

function mkcd(...)
    mkdirp(...)
    local first = select(1, ...)
    unistd.chdir(first)
end

function rm_rf(path)
    os.execute("rm -rf \"" .. path .. "\"")
end

function log(name, msg, category)
    -- This is a direct translation of kiss's log(). Quite hacky.
    io.stderr:write(string.format("%s%s %s%s%s %s\n",
        colors[1],
        category or "->",
        colors[3] .. (msg and colors[2] or ""),
        name,
        colors[3],
        msg or ""))
end

function warn(name, msg)
    log(name, msg, "WARNING")
end

function die(name, msg)
    log(name, msg, "ERROR")
    print(debug.traceback(nil, 2))
    os.exit(false)
end

function prompt(env, msg)
    if msg then log(msg) end
    log("Continue? Press Enter to continue or Ctrl+C to abort")
    if env.PROMPT ~= 0 then
        io.stdin:read()
    end
end

-- cmd is a string.
function run_shell(cmd)
    io.stderr:write(cmd.."\n")
    return os.execute(cmd)
end

-- path is a string, cmd is an array, env is a table
-- Despite the variable name, path doesn't have to be absolute because execp is used.
-- If logfile is provided, the output of cmd is copied to a file of that name.
function run(path, cmd, env, logfile)
    io.stderr:write(path .. " " .. table.concat(cmd, " ", 1) .. "\n")

    local f,r,w
    if logfile then
        local err
        f,err = io.open(logfile, "w")
        if not f then
            die("could not create " .. err)
        end

        r,w = unistd.pipe()
        if not r then
            die("could not pipe: " .. w)
        end
    end

    local pid = unistd.fork()

    if not pid then
        die("fork failed")
    elseif pid == 0 then
        if logfile then
            unistd.close(r)
            unistd.dup2(w, unistd.STDOUT_FILENO)
            unistd.dup2(w, unistd.STDERR_FILENO)
            unistd.close(w)
        end

        if env then
            for k,v in pairs(env) do
                stdlib.setenv(k, v)
            end
        end

        unistd.execp(path, cmd)
    else
        if logfile then
            unistd.close(w)
            while true do
                local out = unistd.read(r, 1024)
                if not out or #out == 0 then break end

                io.write(out)
                if logfile then
                    f:write(out)
                end
            end
            unistd.close(r)
            f:close()
        end

        local _, msg, code = sys_wait.wait(pid)
        if msg ~= "exited" then
            die("run failed: " .. msg)
        end
        return code == 0
    end
end

-- Returns an array of lines printed by cmd
function capture(cmd)
    local p = io.popen(cmd, "r")
    local res = {}
    for line in p:lines() do
        table.insert(res, line)
    end
    return res
end

function shallowcopy(t)
    local u = {}
    for k,v in pairs(t) do u[k] = v end
    return u
end

local M = {
    setup       = setup,
    trap_on     = trap_on,
    trap_off    = trap_off,
    split       = split,
    mkdirp      = mkdirp,
    mkcd        = mkcd,
    rm_rf       = rm_rf,
    log         = log,
    warn        = warn,
    die         = die,
    prompt      = prompt,
    run_shell   = run_shell,
    run         = run,
    capture     = capture,
    shallowcopy = shallowcopy,
}

return M
