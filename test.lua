bliss = require "bliss"

function tts(t) local s = "{ " local sep = "" for k,v in pairs(t) do s = s..sep..k.."="..v sep = ", " end return s .. " }" end

env, atexit = bliss.setup()
for k,v in pairs(env) do
    if "table" == type(v) then
        print(k, tts(v))
    else
        print(k,v)
    end
end

local ctx = bliss.b3sum.init()
bliss.b3sum.update(ctx, "test\n")
local obs = bliss.b3sum.finalize(ctx)

local exp = bliss.capture("echo test | b3sum")
local exp_ = bliss.split(exp[1], " ")[1]
assert(exp_ == obs)

local p = "feh"
local repo_dir = bliss.find(p, env.PATH)
local sources = bliss.find_sources(p, repo_dir)
local caches = bliss.resolve(p, sources, env, repo_dir)
bliss.verify_checksums(p, repo_dir, caches)
