#!/bin/bash
set -e

# build_unilab_win.sh - Windows Build & Packaging Script for UniLab
# Based on script/build_unilab.sh

echo "===================================================="
echo "🚀 Building UniLab for Windows"
echo "===================================================="

# 1. Build Rust Core (DLL and CLI)
echo "🦀 Step 1: Building Rust Core components..."
cd backend
cargo build --release -p unilab_core
cargo build --release -p unilab_cli
cd ..

# 2. Sync Bridge to Flutter (Required for Windows build)
echo "🔗 Step 2: Syncing Rust Bridge to Flutter..."
mkdir -p frontend/windows
cp backend/target/release/unilab_core.dll frontend/windows/

# 3. Build Flutter GUI
echo "💙 Step 3: Building Flutter GUI for Windows..."
cd frontend
# Check if flutter is in path
if ! command -v flutter &> /dev/null; then
    echo "⚠️ 'flutter' command not found. Please ensure Flutter SDK is in your PATH."
    exit 1
fi
flutter build windows --release
cd ..

# 4. Prepare Release Directory
RELEASE_DIR="./release-windows"
echo "📦 Step 4: Packaging into $RELEASE_DIR..."

rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR/Unilab-core"
mkdir -p "$RELEASE_DIR/Unilab"

# --- PACKAGE: Unilab-core (CLI) ---
echo "  - Packaging Unilab-core..."
cp backend/target/release/unilab_cli.exe "$RELEASE_DIR/Unilab-core/unilab-core.exe"
cp backend/target/release/unilab_core.dll "$RELEASE_DIR/Unilab-core/"

# Create a simple batch runner for convenience
cat <<EOF > "$RELEASE_DIR/Unilab-core/run.bat"
@echo off
"%~dp0unilab-core.exe" %*
EOF

# --- PACKAGE: Unilab (GUI) ---
echo "  - Packaging Unilab (GUI)..."
if [ -d "frontend/build/windows/x64/release/bundle/" ]; then
    cp -r frontend/build/windows/x64/release/bundle/* "$RELEASE_DIR/Unilab/"
    # Rename executable to UniLab.exe
    if [ -f "$RELEASE_DIR/Unilab/unilab.exe" ]; then
        mv "$RELEASE_DIR/Unilab/unilab.exe" "$RELEASE_DIR/Unilab/UniLab.exe"
    fi
else
    echo "❌ Error: Flutter build output not found!"
    exit 1
fi

# --- PACKAGE: Python Environment ---
echo "🐍 Packaging Embedded Python..."
PYTHON_DIR="temp_python"
if [ -d "$PYTHON_DIR" ]; then
    # Ensure pip is installed
    if [ ! -f "$PYTHON_DIR/Scripts/pip.exe" ]; then
        curl -sS https://bootstrap.pypa.io/get-pip.py -o "$PYTHON_DIR/get-pip.py"
        sed -i 's/#import site/import site/g' "$PYTHON_DIR/python313._pth"
        "$PYTHON_DIR/python.exe" "$PYTHON_DIR/get-pip.py"
        rm "$PYTHON_DIR/get-pip.py"
    fi
    
    # Ensure site-packages exists and is in .pth
    mkdir -p "$PYTHON_DIR/Lib/site-packages"
    if ! grep -q "./Lib/site-packages" "$PYTHON_DIR/python313._pth"; then
        echo "./Lib/site-packages" >> "$PYTHON_DIR/python313._pth"
    fi

    # Install requirements directly into the embedded python's site-packages
    echo "  - Installing requirements into embedded python..."
    "$PYTHON_DIR/python.exe" -m pip install -r backend/requirements.txt --target "$PYTHON_DIR/Lib/site-packages" --upgrade

    # Copy the configured Python environment into the release directories
    echo "  - Copying Python environment to releases..."
    cp -r "$PYTHON_DIR/"* "$RELEASE_DIR/Unilab/"
    cp -r "$PYTHON_DIR/"* "$RELEASE_DIR/Unilab-core/"
else
    echo "⚠️ Warning: $PYTHON_DIR not found. Python environment will not be bundled!"
fi

# 5. Create ZIP archives
echo "🗜️ Step 5: Creating ZIP archives..."
if command -v zip &> /dev/null; then
    zip -r UniLab-Windows-GUI.zip "$RELEASE_DIR/Unilab"
    zip -r UniLab-Windows-CLI.zip "$RELEASE_DIR/Unilab-core"
    echo "  ✅ Created UniLab-Windows-GUI.zip"
    echo "  ✅ Created UniLab-Windows-CLI.zip"
else
    echo "  ⚠️ 'zip' command not found, skipping archive creation."
fi

echo ""
echo "===================================================="
echo "✅ Done! Windows releases are ready."
echo "===================================================="
echo "📂 Location: $RELEASE_DIR"
echo "  ▶️ GUI:   $RELEASE_DIR/Unilab/UniLab.exe"
echo "  ▶️ CLI:   $RELEASE_DIR/Unilab-core/unilab-core.exe"
