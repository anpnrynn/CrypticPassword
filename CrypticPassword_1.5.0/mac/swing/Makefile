# macOS Swing build. Requires a JDK. DMG creation requires macOS hdiutil.

JAVAC ?= javac
JAR ?= jar
APP_NAME := CrypticPassword
CLASS := CrypticPasswordSwing
BUILDDIR := build
DISTDIR := dist
CLASSES := $(BUILDDIR)/classes
JARDIR := $(BUILDDIR)/jar
JARFILE := $(JARDIR)/$(APP_NAME).jar
APPDIR := $(DISTDIR)/$(APP_NAME).app

all: app

$(CLASSES):
	mkdir -p $(CLASSES)

$(JARDIR):
	mkdir -p $(JARDIR)

$(JARFILE): src/$(CLASS).java | $(CLASSES) $(JARDIR)
	$(JAVAC) -Xlint:all -d $(CLASSES) src/$(CLASS).java
	printf 'Main-Class: $(CLASS)\n' > $(BUILDDIR)/MANIFEST.MF
	$(JAR) cfm $(JARFILE) $(BUILDDIR)/MANIFEST.MF -C $(CLASSES) .

app: $(JARFILE)
	rm -rf $(APPDIR)
	mkdir -p $(APPDIR)/Contents/MacOS $(APPDIR)/Contents/Resources/Java
	cp $(JARFILE) $(APPDIR)/Contents/Resources/Java/$(APP_NAME).jar
	cp package/Info.plist $(APPDIR)/Contents/Info.plist
	printf '#!/bin/sh\nDIR="$$(cd "$$(dirname "$$0")" && pwd)"\nexec java -jar "$$DIR/../Resources/Java/$(APP_NAME).jar"\n' > $(APPDIR)/Contents/MacOS/$(APP_NAME)
	chmod +x $(APPDIR)/Contents/MacOS/$(APP_NAME)
	touch $(APPDIR)

run: $(JARFILE)
	java -jar $(JARFILE)

dmg: app
	./package/make_dmg.sh

clean:
	rm -rf $(BUILDDIR) $(DISTDIR)
