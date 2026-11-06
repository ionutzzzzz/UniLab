#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." &>/dev/null && pwd)"

echo "Building UniLab FFI bridge..."
cd "$PROJECT_ROOT/backend"
cargo build --release -p unilab_core

# Determine the .so/.dylib/.dll name based on the platform
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    SO_NAME="libunilab_core.so"
    DEST_DIR="$PROJECT_ROOT/frontend/linux/"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    SO_NAME="libunilab_core.dylib"
    DEST_DIR="$PROJECT_ROOT/frontend/macos/Frameworks/"
elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
    SO_NAME="unilab_core.dll"
    DEST_DIR="$PROJECT_ROOT/frontend/windows/"
else
    echo "Unsupported platform: $OSTYPE"
    exit 1
fi

if [ -f "target/release/$SO_NAME" ]; then
    mkdir -p "$DEST_DIR"
    cp "target/release/$SO_NAME" "$DEST_DIR"
    echo "✓ Bridge built and copied to: $DEST_DIR$SO_NAME"

    # Also copy PyO3 extension alias if on Linux/macOS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        cp "target/release/$SO_NAME" "$PROJECT_ROOT/backend/core/unilab_rust_core.so"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        cp "target/release/$SO_NAME" "$PROJECT_ROOT/backend/core/unilab_rust_core.so"
    fi

    for BUNDLE_DIR in \
        "$PROJECT_ROOT/frontend/build/linux/arm64/debug/bundle/lib" \
        "$PROJECT_ROOT/frontend/build/linux/x64/debug/bundle/lib" \
        "$PROJECT_ROOT/frontend/build/macos/Build/Products/Debug/unilab.app/Contents/Frameworks" \
        "$PROJECT_ROOT/frontend/build/macos/Build/Products/Release/unilab.app/Contents/Frameworks"; do
        if [ -d "$BUNDLE_DIR" ]; then
            cp "target/release/$SO_NAME" "$BUNDLE_DIR/"
            echo "✓ Synced to active bundle: $BUNDLE_DIR/$SO_NAME"
        fi
    done
else
    echo "✗ Failed to find $SO_NAME in backend/target/release/"
    ls -la target/release/ | grep unilab_core || true
    exit 1
fi
