# GTK+ native Linux build
# Dependencies on Debian/Ubuntu: sudo apt install build-essential pkg-config libgtk-3-dev

CC ?= gcc
PKG_CONFIG ?= pkg-config
CFLAGS ?= -O2 -g -Wall -Wextra -std=c11
GTK_CFLAGS := $(shell $(PKG_CONFIG) --cflags gtk+-3.0)
GTK_LIBS := $(shell $(PKG_CONFIG) --libs gtk+-3.0)
OUTDIR := build
TARGET := $(OUTDIR)/crypticpassword-gtk

all: $(TARGET)

$(OUTDIR):
	mkdir -p $(OUTDIR)

$(TARGET): src/main_gtk.c ../common/crypticpassword_core.c ../common/crypticpassword_core.h | $(OUTDIR)
	$(CC) $(CFLAGS) $(GTK_CFLAGS) -I../common src/main_gtk.c ../common/crypticpassword_core.c -o $(TARGET) $(GTK_LIBS)

install: $(TARGET)
	install -d $(DESTDIR)/usr/bin
	install -m 0755 $(TARGET) $(DESTDIR)/usr/bin/crypticpassword-gtk
	install -d $(DESTDIR)/usr/share/applications
	install -m 0644 packaging/applications/org.cryptic.password.desktop $(DESTDIR)/usr/share/applications/org.cryptic.password.desktop

clean:
	rm -rf $(OUTDIR)
