.POSIX:

PREFIX = /usr
LUA_LMOD = $$(pkgconf --variable=INSTALL_LMOD lua)
LUA_CMOD = $$(pkgconf --variable=INSTALL_CMOD lua)

CFLAGS = -Wall -Wextra -pedantic
LDFLAGS = -shared -fPIC
LIBS = $$(pkgconf --libs lua)

all: bliss/b3sum.so

install: all
	mkdir -p       "$(DESTDIR)$(LUA_LMOD)/bliss"
	mkdir -p       "$(DESTDIR)$(LUA_CMOD)/bliss"
	mkdir -p       "$(DESTDIR)$(PREFIX)/bin"
	cp bliss/*.lua "$(DESTDIR)$(LUA_LMOD)/bliss/"
	cp bliss/*.so  "$(DESTDIR)$(LUA_CMOD)/bliss/"
	cp main.lua    "$(DESTDIR)$(PREFIX)/bin/bliss"

bliss/b3sum.so: bliss/b3sum.c
	$(CC) $(CFLAGS) -o $@ bliss/b3sum.c $(LDFLAGS) $(LIBS) -lblake3

clean:
	rm -f bliss/b3sum.so
