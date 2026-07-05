#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAC_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP="$MAC_DIR/dist/CrypticPassword.app"
DMG="$MAC_DIR/dist/CrypticPassword-macos-swift.dmg"

command -v hdiutil >/dev/null 2>&1 || { echo "hdiutil is required to build a DMG. Run this on macOS." >&2; exit 1; }
[ -d "$APP" ] || { echo "$APP not found. Run make -C mac app first." >&2; exit 1; }
mkdir -p "$MAC_DIR/dist"
rm -f "$DMG"
hdiutil create -volname "CrypticPassword" -srcfolder "$APP" -ov -format UDZO "$DMG"
echo "Built $DMG"
