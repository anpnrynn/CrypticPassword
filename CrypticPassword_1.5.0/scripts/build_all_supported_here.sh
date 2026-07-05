#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
make -C "$ROOT_DIR" core-test
make -C "$ROOT_DIR" mac-swift-test
make -C "$ROOT_DIR" mac-java
if [ "$(uname -s)" = "Darwin" ]; then
    make -C "$ROOT_DIR/mac" app
else
    echo "Skipping macOS Swift/AppKit app bundle: AppKit requires macOS."
fi
if pkg-config --exists gtk+-3.0; then
    make -C "$ROOT_DIR/linux" all
else
    echo "Skipping Linux GTK+ compile: gtk+-3.0 development files not available in this environment."
fi
