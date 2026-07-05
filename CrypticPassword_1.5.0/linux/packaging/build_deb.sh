#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINUX_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$LINUX_DIR/.." && pwd)"
VERSION="1.5.0"
ARCH="${ARCH:-amd64}"
PKGROOT="$LINUX_DIR/build/pkgroot"
OUTDIR="$LINUX_DIR/build/packages"

command -v dpkg-deb >/dev/null 2>&1 || { echo "dpkg-deb not found" >&2; exit 1; }
command -v pkg-config >/dev/null 2>&1 || { echo "pkg-config not found" >&2; exit 1; }
pkg-config --exists gtk+-3.0 || { echo "gtk+-3.0 development files not found. Install libgtk-3-dev." >&2; exit 1; }

make -C "$LINUX_DIR" clean all
rm -rf "$PKGROOT" "$OUTDIR"
mkdir -p "$PKGROOT/DEBIAN" "$OUTDIR"
cp -R "$SCRIPT_DIR/debian/DEBIAN/." "$PKGROOT/DEBIAN/"
sed -i "s/^Architecture:.*/Architecture: $ARCH/" "$PKGROOT/DEBIAN/control"
make -C "$LINUX_DIR" DESTDIR="$PKGROOT" install
find "$PKGROOT" -type d -exec chmod 0755 {} +
dpkg-deb --build "$PKGROOT" "$OUTDIR/crypticpassword_${VERSION}_${ARCH}.deb"
echo "Built $OUTDIR/crypticpassword_${VERSION}_${ARCH}.deb"
