kiss = require "libkiss"

function tts(t) local s = "{ " local sep = "" for k,v in pairs(t) do s = s..sep..k.."="..v sep = ', ' end return s .. ' }' end

env = kiss.setup()
for k,v in pairs(env) do
    if "table" == type(v) then
        print(k, tts(v))
    else
        print(k,v)
    end
end
