#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." &>/dev/null && pwd)"

# Ensure cargo is in PATH if installed in ~/.cargo/bin
if ! command -v cargo &>/dev/null && [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# Detect Python for PyO3 if not explicitly set
if [ -z "${PYO3_PYTHON:-}" ]; then
    if [ -x "$HOME/anaconda3/bin/python3" ]; then
        export PYO3_PYTHON="$HOME/anaconda3/bin/python3"
    elif command -v python3 &>/dev/null; then
        export PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1
    fi
fi

echo "Building UniLab FFI bridge..."
cd "$PROJECT_ROOT/backend"

if [[ "$OSTYPE" == "darwin"* ]]; then
    PY_LIB_DIR=""
    if [ -n "${PYO3_PYTHON:-}" ]; then
        PY_LIB_DIR="$(cd "$(dirname "$PYO3_PYTHON")/../lib" 2>/dev/null && pwd || true)"
    fi
    RPATH_ARGS="-C link-arg=-Wl,-headerpad_max_install_names -C link-arg=-Wl,-rpath,@loader_path -C link-arg=-Wl,-rpath,@executable_path/../Frameworks"
    if [ -n "$PY_LIB_DIR" ] && [ -d "$PY_LIB_DIR" ]; then
        RPATH_ARGS="$RPATH_ARGS -C link-arg=-Wl,-rpath,$PY_LIB_DIR"
    fi
    export RUSTFLAGS="${RUSTFLAGS:-} $RPATH_ARGS"
fi

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
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Add rpaths to macOS dynamic library so it can locate libpython and bundle frameworks
        install_name_tool -add_rpath "@loader_path" "target/release/$SO_NAME" 2>/dev/null || true
        install_name_tool -add_rpath "@executable_path/../Frameworks" "target/release/$SO_NAME" 2>/dev/null || true
        if [ -n "${PYO3_PYTHON:-}" ]; then
            PY_LIB_DIR="$(cd "$(dirname "$PYO3_PYTHON")/../lib" 2>/dev/null && pwd || true)"
            if [ -n "$PY_LIB_DIR" ] && [ -d "$PY_LIB_DIR" ]; then
                install_name_tool -add_rpath "$PY_LIB_DIR" "target/release/$SO_NAME" 2>/dev/null || true
            fi
        fi
    fi

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
