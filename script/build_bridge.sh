#!/bin/bash
set -e

echo "Building UniLab FFI bridge..."
cd backend
cargo build --release -p unilab_core

# Determine the .so/.dylib/.dll name based on the platform
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    SO_NAME="libunilab_core.so"
    DEST_DIR="../frontend/linux/"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    SO_NAME="libunilab_core.dylib"
    DEST_DIR="../frontend/macos/Frameworks/"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    SO_NAME="unilab_core.dll"
    DEST_DIR="../frontend/windows/"
else
    echo "Unsupported platform: $OSTYPE"
    exit 1
fi

# Find the built library
if [ -f "target/release/$SO_NAME" ]; then
    mkdir -p "$DEST_DIR"
    cp "target/release/$SO_NAME" "$DEST_DIR"
    echo "✓ Bridge built and copied to: $DEST_DIR$SO_NAME"

    # Also try to copy to the active flutter build bundle if it exists
    BUNDLE_DIR="../frontend/build/linux/x64/debug/bundle/lib/"
    if [ -d "$BUNDLE_DIR" ]; then
        cp "target/release/$SO_NAME" "$BUNDLE_DIR"
        echo "✓ Synced to active bundle: $BUNDLE_DIR$SO_NAME"
    fi
else
    echo "✗ Failed to find $SO_NAME in target/release/"
    ls -la target/release/ | grep unilab_core || true
    exit 1
fi
