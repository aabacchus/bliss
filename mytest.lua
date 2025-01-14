--- Test suite
-- @script test

local t = require("testlib")
local posix = require("posix")

-- Set up a temporary directory for ROOT
assert(posix.chdir("tests/"))
local tempd = posix.mkdtemp("/tmp/bliss-test-XXXXXX")
local cachedir = tempd .. "/cache"
local pwd = posix.getcwd()
local repo = pwd .. "/repo"
posix.setenv("KISS_ROOT", tempd)
posix.setenv("XDG_CACHE_HOME", cachedir)
posix.setenv("KISS_PATH", repo)

local bliss = require "bliss"
local tsort = require "bliss.tsort"
local env = bliss.setup()


-- ARCHIVE
-- B3SUM
local ctx = bliss.b3sum.init()
bliss.b3sum.update(ctx, "test\n")
t.test("b3sum", "dea2b412aa90f1b43a06", bliss.b3sum.finalize, ctx, 10)
-- BUILD
-- CHECKSUM
t.test("checksum_file", "dea2b412aa90f1b43a06ca5e8b8feafec45ae1357971322749480f4e1572eaa2ea",
    bliss.checksum_file, "testfile.txt")
-- DOWNLOAD
-- INSTALL
-- LIST
t.test("list (no packages)", nil, bliss.list, env, {})
t.test("list (all packages)", "package1 1-1\n", bliss.list, {sys_db = pwd .. "/repo/"}, {})
t.test("list (one package)", "package1 1-1\n", bliss.list, {sys_db = pwd .. "/repo/"}, {"package1"})
-- PKG
t.test("read_lines", {{"test"}}, bliss.read_lines, "testfile.txt")
t.test("find", pwd .. "/repo/package1", bliss.find, "package1", env.PATH)
t.test("isinstalled (not)", false, bliss.isinstalled, env, "notinstalled")
t.test("iscached (not)", false, bliss.iscached, env, "nonexistent", {0,0})
local repo_dir = bliss.find("package1", env.PATH)
t.test("find_version", {"1","1"},
    bliss.find_version, "package1", repo_dir)

t.test("find_sources", {{"files/testfile"}},
    bliss.find_sources, "package1", repo_dir)

t.test("resolve (file)", {repo_dir .. "/files/testfile"},
    bliss.resolve, "package1", {{"files/testfile"}}, env, repo_dir)

t.test("resolve (http)", {cachedir .. "/kiss/sources/package1/testpath.tar.gz"},
    bliss.resolve, "package1", {{"https://example.com/a/b/testpath.tar.gz"}}, env)

t.test("resolve (http with dest)", {cachedir .. "/kiss/sources/package1/dest/testpath.tar.gz"},
    bliss.resolve, "package1", {{"https://example.com/a/b/testpath.tar.gz", "dest"}}, env)

t.test("resolve (git)", {cachedir .. "/kiss/sources/package1/gitdir.git/"},
    bliss.resolve, "package1", {{"git+https://example.com/a/b/gitdir.git"}}, env)

t.test("resolve (git with branch)", {cachedir .. "/kiss/sources/package1/gitdir.git/"},
    bliss.resolve, "package1", {{"git+https://example.com/a/b/gitdir.git@branch#commit"}}, env)

-- SEARCH
t.test("search", pwd .. "/repo/package1\n", bliss.search, env, {"package1"})
t.test("search (glob)", pwd .. "/repo/package1\n", bliss.search, env, {"package*"})
-- TSORT
local sorter = tsort.new()
sorter:add("a", {"b", "c"})
sorter:add("b", {"c", "d"})
sorter:add("c", {"d"})
t.test("tsort", {"a", "b", "c", "d"}, tsort.sort, sorter)
-- UTILS
t.test("split", {"a", "b", "c"}, bliss.split, "a,b,,c,", ",")
t.test("capture", {"foobar", "barfoo"}, bliss.capture, "echo foobar; echo barfoo")
t.test("shallowcopy", {1,2,3}, bliss.shallowcopy, {1,2,3})
t.test("am_not_owner", "root", bliss.am_not_owner, "/")

local r = t.summarise()
t.coverage(bliss)

os.execute("rm -fr "..tempd)
_exit(r)
