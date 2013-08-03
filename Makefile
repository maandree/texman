# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

PREFIX = /usr
DATA = /share
BIN = /bin
PKGNAME = texman
SHABANG = /usr$(BIN)/perl
COMMAND = texman
LICENSES = $(PREFIX)$(DATA)
MAN_SECTION = 1
TEXMAN_SECTION = 1
TEXINFO_SECTION = 1


all: texman doc

doc: man

man: texman

texman.$(TEXMAN_SECTION).gz: texman.texman
	cp "$<" "$<"~
	sed -i '/^@texman{/s/{1}/$(TEXMAN_SECTION)/' "$<"~
	perl texman.pl man=$(MAN_SECTION) texinfo=$(TEXINFO_SECTION) < "$<"~ | gzip -9 -f > "$@"

texman: texman.pl
	cp "$<" "$@"
	sed -i 's:#!/usr/bin/perl:#!$(SHEBANG)":' "$@"

install: texman texman.$(TEXMAN).gz
	install -dm755 "$(DESTDIR)$(PREFIX)$(BIN)"
	install -m755 texman "$(DESTDIR)$(PREFIX)$(BIN)$(COMMAND)"
	install -dm755 "$(DESTDIR)$(LICENSES)/$(PKGNAME)"
	install -m644 COPYING LICENSE "$(DESTDIR)$(LICENSES)/$(PKGNAME)"
	install -dm755 "$(DESTDIR)$(PREFIX)$(DATA)/man/man$(TEXMAN_SECTION)"
	install -m644 texman.$(TEXMAN_SECTION).gz "$(DESTDIR)$(PREFIX)$(DATA)/man/man$(TEXMAN_SECTION)/$(COMMAND).$(TEXMAN_SECTION).gz"

uninstall:
	rm -- "$(DESTDIR)$(PREFIX)$(BIN)/$(COMMAND)"
	rm -- "$(DESTDIR)$(LICENSES)/$(PKGNAME)/COPYING"
	rm -- "$(DESTDIR)$(LICENSES)/$(PKGNAME)/LICENSE"
	rmdir -- "$(DESTDIR)$(LICENSES)/$(PKGNAME)"
	rm -- "$(DESTDIR)$(PREFIX)$(DATA)/man/man$(TEXMAN_SECTION)/$(COMMAND).$(TEXMAN_SECTION).gz"


clean:
	-rm texman texman.$(TEXMAN_SECTION).gz


.PHONY: all doc install uninstall clean

