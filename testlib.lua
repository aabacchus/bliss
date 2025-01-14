--- Test module
-- @module test

local pp = require("pp")

local test = {}
local counter = {failed = 0, succeeded = 0}
local tested_funcs = {}

-- catch deaths
_exit = os.exit
os.exit = function(a)
	error("os.exit was called\n" .. debug.traceback(nil, 2))
end

-- monkeypatch print
local realprint = print
local outputs = {}
local function printtostring(...)
	local s = ""
	for i = 1, select("#", ...) do
		local ss = tostring(select(i, ...))
		if i > 1 then
			s = s .. "\t"
		end
		s = s .. ss
	end
	s = s
	return s
end

local function storeoutput(append_newline, ...)
	local s = printtostring(...)
	if append_newline then
		s = s .. "\n"
	end
	table.insert(outputs, s)
end

print = function (...)
	storeoutput(true, ...)
	--realprint(...)
end
io.write = function (...)
	storeoutput(false, ...)
end

local function log(...)
	local n = select("#", ...)
	if n > 1 then
		io.stderr:write(string.format("%-30s", select(1, ...)))

	end
	io.stderr:write(printtostring(select(n > 1 and 2 or 1, ...)).."\n")
end

local cmp, tablecmp
tablecmp = function (a, b)
	if a == b then return true end
	if #a ~= #b then
		return false
	end
	for k,v in pairs(a) do
		if not cmp(b[k], v) then
			return false
		end
	end
	for k,v in pairs(b) do
		if not cmp(a[k], v) then
			return false
		end
	end
	return true
end

cmp = function (a, b)
	if type(a) == "table" then
		return tablecmp(a, b)
	else
		return a == b
	end
end

function test.test(name, expected, fn, ...)
	tested_funcs[fn] = true
	local r, s = pcall(fn, ...)
	if not r then
		log(name, "FAIL: exception caught: ", s)
		counter.failed = counter.failed + 1
	else
		-- if nil return value, use the last line of output.
		-- false is a valid return value.
		if s == nil then
			s = outputs[#outputs]
		end
		if not cmp(s, expected) then
			log(name, "FAIL: expected " .. pp.format(expected) .. " but got " .. pp.format(s))
			counter.failed = counter.failed + 1
		else
			log(name, "success")
			counter.succeeded = counter.succeeded + 1
		end
	end
	-- reset outputs between tests
	outputs = {}
	return r
end

function test.summarise()
	log("summary: " .. counter.succeeded .. "/" .. counter.succeeded + counter.failed .. " successes")
	return counter.failed == 0
end

function test.coverage(t)
	-- recursively count number of functions in table t and compare to number of functions tested so far
	local function recur_count(t)
		local count = 0
		for _,v in pairs(t) do
			if type(v) == "function" then
				count = count + 1
			elseif type(v) == "table" then
				count = count + recur_count(v)
			end
		end
		return count
	end
	local total = recur_count(t)
	local tested = 0
	for k,v in pairs(tested_funcs) do tested = tested + 1 end
	log("test coverage: " .. tested .. "/" .. total .. " (" .. 100 * tested / total .. "%)")
end

return test
