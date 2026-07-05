#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
gradle assembleDebug
echo "APK written to app/build/outputs/apk/debug/app-debug.apk"
