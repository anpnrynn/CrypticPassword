SHELL := /bin/sh

.PHONY: build debug release clean apk

build debug:
	gradle assembleDebug

release:
	gradle assembleRelease

apk: debug
	@echo "Debug APK: app/build/outputs/apk/debug/app-debug.apk"

clean:
	gradle clean
