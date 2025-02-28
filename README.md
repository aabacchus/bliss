BLISS
=====

An implementation of the kiss package manager in Lua.

<https://git.bvnf.space/bliss/>

 * [ ] alternatives
 * [x] build
 * [ ] hooks
 * [x] checksum
 * [x] download
 * [ ] install
 * [x] list
 * [ ] remove
 * [x] search
 * [x] update
 * [ ] upgrade
 * [x] version
 * [ ] ext

Why Lua?
--------

Lua ...

 * shares many goals with KISS, such as simplicity and efficiency.
 * offers advantages over shell as a "proper" programming language.
 * can easily be extended by code written in C (etc).
 * is relatively fast.

Dependencies
------------

 * Lua 5.4 (but I've tried to make it work with 5.1 too for LuaJIT)
 * luaposix library <https://github.com/luaposix/luaposix>
 * BLAKE3 C library <https://git.sr.ht/~mcf/b3sum> (built with -fPIC)

Rationale: plain Lua lacks UNIX-specific bindings which we need (working with
files and paths) so either I would write a set of Lua bindings to C, but it's as
simple to use an existing set such as luaposix.

[LDoc](https://github.com/lunarmodules/LDoc/) is used for internal documentation.
For users, see kiss's documentation.
