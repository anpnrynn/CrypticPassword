#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$(cd "$ROOT_DIR/.." && pwd)"
NAME="CrypticPassword_1.5.0"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/$NAME"
rm -f "$OUT_DIR/$NAME.tar.gz" "$OUT_DIR/$NAME.zip"
rsync -a \
  --exclude build \
  --exclude build-cmake \
  --exclude build-xcode \
  --exclude dist \
  --exclude '*.zip' \
  --exclude '*.tar.gz' \
  --exclude '*.dmg' \
  "$ROOT_DIR/" "$TMP/$NAME/"
( cd "$TMP" && tar -czf "$OUT_DIR/$NAME.tar.gz" "$NAME" )
( cd "$TMP" && zip -qr "$OUT_DIR/$NAME.zip" "$NAME" )
echo "Created $OUT_DIR/$NAME.tar.gz"
echo "Created $OUT_DIR/$NAME.zip"
