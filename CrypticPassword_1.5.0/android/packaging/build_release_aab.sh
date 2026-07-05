#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
gradle bundleRelease
echo "Android App Bundle written to app/build/outputs/bundle/release/app-release.aab"
