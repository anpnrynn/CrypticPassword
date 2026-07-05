# macOS native Swift/AppKit build. DMG creation requires macOS hdiutil.
# The retained Java Swing project lives in mac/swing.

UNAME_S := $(shell uname -s)
SWIFTC ?= swiftc
XCRUN ?= xcrun
APP_NAME := CrypticPassword
SRC := src/swift/CrypticPasswordApp.swift
TEST_SRC := tests/CrypticPasswordSwiftCoreTest.swift
BUILDDIR := build
DISTDIR := dist
APPDIR := $(DISTDIR)/$(APP_NAME).app
BINARY := $(APPDIR)/Contents/MacOS/$(APP_NAME)
PLIST := package/swift/Info.plist

.PHONY: all app run dmg xcode swift-core-test swing swing-run swing-dmg clean

all: app

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

swift-core-test: $(BUILDDIR)
	$(SWIFTC) $(TEST_SRC) -o $(BUILDDIR)/cryptic_swift_core_test
	$(BUILDDIR)/cryptic_swift_core_test

app: $(SRC) $(PLIST)
	@if [ "$(UNAME_S)" != "Darwin" ]; then echo "The Swift/AppKit app bundle target must be built on macOS. Use 'make swift-core-test' here to validate the Swift algorithm." >&2; exit 2; fi
	rm -rf $(APPDIR)
	mkdir -p $(APPDIR)/Contents/MacOS $(APPDIR)/Contents/Resources
	cp $(PLIST) $(APPDIR)/Contents/Info.plist
	MACOSX_DEPLOYMENT_TARGET=10.13 $(XCRUN) swiftc -O -o $(BINARY) $(SRC) -framework Cocoa
	chmod +x $(BINARY)
	touch $(APPDIR)

run: app
	open $(APPDIR)

dmg: app
	./package/swift/make_dmg.sh

xcode:
	@if [ "$(UNAME_S)" != "Darwin" ]; then echo "xcodebuild must be run on macOS." >&2; exit 2; fi
	xcodebuild -project xcode/CrypticPasswordSwift.xcodeproj -scheme CrypticPasswordSwift -configuration Release SYMROOT=$(CURDIR)/build/xcode
	rm -rf $(APPDIR)
	mkdir -p $(DISTDIR)
	cp -R build/xcode/Release/$(APP_NAME).app $(APPDIR)

swing:
	$(MAKE) -C swing app

swing-run:
	$(MAKE) -C swing run

swing-dmg:
	$(MAKE) -C swing dmg

clean:
	rm -rf $(BUILDDIR) $(DISTDIR)
	$(MAKE) -C swing clean || true
