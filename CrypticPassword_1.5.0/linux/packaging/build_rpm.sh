#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERSION="1.5.0"
TOPDIR="$ROOT_DIR/linux/build/rpmbuild"
TARBALL="$TOPDIR/SOURCES/crypticpassword-$VERSION.tar.gz"

command -v rpmbuild >/dev/null 2>&1 || { echo "rpmbuild not found. Install rpm-build." >&2; exit 1; }
mkdir -p "$TOPDIR/BUILD" "$TOPDIR/RPMS" "$TOPDIR/SOURCES" "$TOPDIR/SPECS" "$TOPDIR/SRPMS"
TMP="$(mktemp -d)"
mkdir -p "$TMP/crypticpassword-$VERSION"
rsync -a --exclude build "$ROOT_DIR/" "$TMP/crypticpassword-$VERSION/"
tar -C "$TMP" -czf "$TARBALL" "crypticpassword-$VERSION"
cp "$SCRIPT_DIR/rpm/crypticpassword.spec" "$TOPDIR/SPECS/"
rpmbuild --define "_topdir $TOPDIR" -ba "$TOPDIR/SPECS/crypticpassword.spec"
echo "RPM output: $TOPDIR/RPMS"
