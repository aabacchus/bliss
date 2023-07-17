-- This module is not included in init.lua, but used locally by pkg.lua.
local tsort = {}

-- Returns a table of reverse deps
local function reverse(input)
    local reversed = {}
    for k,v in pairs(input) do
        for _,w in ipairs(v) do
            reversed[w] = reversed[w] or {}
            table.insert(reversed[w], k)
        end
    end
    return reversed
end

local function find_cycle(revlinks, start)
    local ret = {[start] = 1}
    local old

    local t = revlinks[start][1]
    while t and not ret[t] do
        ret[t] = 1
        old = t
        t = revlinks[t][1]
    end
    return t, old
end

function tsort.new()
    return setmetatable({nodes={}}, {__index = tsort})
end

-- deps is an array of ALL the deps for node. Calling add for the same node a
-- second time overwrites, not appends.
function tsort:add(node, deps)
    self.nodes[node] = deps
end

function tsort:sort()
    if not self.nodes then return nil end
    local L = {}
    local reversed = reverse(self.nodes)

    -- find nodes with no incoming edges
    local S = {}
    for k in pairs(self.nodes) do
        if not reversed[k] or #reversed[k] == 0 then
            table.insert(S, k)
        end
    end

    while #S ~= 0 do
        local n = table.remove(S, 1)
        table.insert(L, n)
        for _,v in ipairs(self.nodes[n] or {}) do
            -- remove edge n -> v
            for i,j in ipairs(reversed[v]) do
                if j == n then
                    table.remove(reversed[v], i)
                end
            end
            if not reversed[v] or #reversed[v] == 0 then
                table.insert(S, v)
                reversed[v] = nil
            end
        end
    end

    for k,v in pairs(reversed) do
        if #v ~= 0 then
            -- cycle detected
            local x,y = find_cycle(reversed, k)
            return nil, x, y
        end
    end
    return L
end

return tsort
