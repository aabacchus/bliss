local utils = require 'bliss.utils'
local dirent = require 'posix.dirent'
local stdio = require 'posix.stdio'

-- extracts tarball to PWD
local function tar_extract(tarball)
    if not utils.run("tar xf '" .. tarball .. "'") then
        utils.die("failed to extract "..tarball)
    end
    
    local top = dirent.dir()
    if #top > 3 then utils.die("more than 1 top-level directory in tarball " .. tarball) end
    for _,v in ipairs(top) do if v ~= '.' and v ~= '..' then top = v break end end

    local d = dirent.dir(top)
    for _,file in ipairs(d) do
        if file ~= '.' and file ~= '..' then
            assert(file:sub(1,1) ~= '/')
            local ok, e = stdio.rename(top..'/'..file, file) 
            if not ok then
                utils.die("couldn't rename " .. file .. ": " .. e)
            end
        end
    end
end

local M = {
    tar_extract = tar_extract,
}
return M
