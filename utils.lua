-- Copyright 2023 phoebos

-- vars
local colors
-- funcs
local setup, setup_colors, check_execute, get_available, log, warn, die, run, capture

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
        HOOK    = os.getenv("KISS_HOOK"),
        KEEPLOG = os.getenv("KISS_KEEPLOG"),
        PATH    = os.getenv("KISS_PATH"),
        PID     = os.getenv("KISS_PID") or nil,
        PROMPT  = os.getenv("KISS_PROMPT"),
        ROOT    = os.getenv("KISS_ROOT") or "",
        SU      = os.getenv("KISS_SU") or get_available("ssu", "sudo", "doas", "su"),
        TMPDIR  = os.getenv("KISS_TMPDIR"),
        time    = os.date("%Y-%m-%d-%H:%M"),
    }
    -- pkg_db depends on ROOT so must be set after env is constructed
    env.pkg_db  = env.ROOT .. "/var/db/kiss/installed"
    return env
end

function setup_colors()
    local t = {"", "", ""}
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

-- utilities

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
    local res, ty, code
    -- faster to use fork + posix.unistd.execp?
    res, ty, code = os.execute(cmd)
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

local P = {
    setup   = setup,
    log     = log,
    warn    = warn,
    die     = die,
    run     = run,
    capture = capture,
}

return P
