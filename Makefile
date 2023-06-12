.POSIX:

PREFIX = /usr
LUA_LMOD = $$(pkgconf --variable=INSTALL_LMOD lua)

install:
	mkdir -p       "$(DESTDIR)$(LUA_LMOD)/bliss"
	cp bliss/*.lua "$(DESTDIR)$(LUA_LMOD)/bliss/"
	mkdir -p    "$(DESTDIR)$(PREFIX)/bin"
	cp main.lua "$(DESTDIR)$(PREFIX)/bin/bliss"
