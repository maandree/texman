PREFIX = /usr/local
MANPREFIX = $(PREFIX)/share/man

all: texman.1

texman.1: texman.texman
	./texman man=1 texinfo=1 < texman.texman > "$@"

check: texman.1
	diff texman.1 texman.1.ref >/dev/null

install: texman.1
	mkdir -p -- "$(DESTDIR)$(PREFIX)/bin"
	mkdir -p -- "$(DESTDIR)$(MANPREFIX)/man1"
	mkdir -p -- "$(DESTDIR)$(PREFIX)/share/licenses/texman"
	cp -- texman "$(DESTDIR)$(PREFIX)/bin/"
	cp -- texman.1 "$(DESTDIR)$(MANPREFIX)/man1/"
	cp -- COPYING LICENSE "$(DESTDIR)$(PREFIX)/share/licenses/texman/"

uninstall:
	-rm -- "$(DESTDIR)$(PREFIX)/bin/texman"
	-rm -- "$(DESTDIR)$(MANPREFIX)/man1/texman.1"
	-rm -- "$(DESTDIR)$(PREFIX)/share/licenses/texman/COPYING"
	-rm -- "$(DESTDIR)$(PREFIX)/share/licenses/texman/LICENSE"
	-rmdir -- "$(DESTDIR)$(PREFIX)/share/licenses/texman"

clean:
	-rm texman.1

.PHONY: all check install uninstall clean
