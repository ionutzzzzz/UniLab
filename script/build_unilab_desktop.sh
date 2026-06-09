#!/bin/bash
set -e

# This script builds the Rust core and packages the Flutter app for the current desktop platform.

PLATFORM="unknown"
case "$(uname -s)" in
    Linux*)     PLATFORM="linux";;
    Darwin*)    PLATFORM="macos";;
    MINGW*)     PLATFORM="windows";;
esac

echo "🚀 Building UniLab for $PLATFORM..."

# 1. & 2. Build Rust Core and Copy to Flutter
echo "🦀 Building Rust Core Bridge..."
./script/build_bridge.sh

# 3. Bundle Backend code into assets
echo "📂 Bundling backend source and samples into assets..."
rm -rf frontend/assets/backend || true
rm -rf frontend/assets/samples || true
mkdir -p frontend/assets/backend/backend
mkdir -p frontend/assets/samples

# Explicitly copy each directory to ensure nothing is missed
for dir in core api utils stdlib; do
    cp -r "backend/$dir" frontend/assets/backend/backend/
done

# Copy root files
cp backend/requirements.txt frontend/assets/backend/backend/
cp backend/__init__.py frontend/assets/backend/backend/ 2>/dev/null || touch frontend/assets/backend/backend/__init__.py

# Copy samples
cp -r sample/* frontend/assets/samples/
mkdir -p frontend/assets/samples
cp -r sample/* frontend/assets/samples/

# 4. Build and Package Flutter App
echo "💙 Packaging Flutter App..."
cd frontend

# Ensure Dart global binaries are in PATH
if [ "$PLATFORM" == "windows" ]; then
    export PATH="$PATH:$(cygpath "$LOCALAPPDATA")/Pub/Cache/bin"
else
    export PATH="$PATH":"$HOME/.pub-cache/bin"
fi

# Check for flutter_distributor
if ! command -v flutter_distributor &> /dev/null; then
    echo "⚠️ flutter_distributor not found. Installing..."
    dart pub global activate flutter_distributor
fi

flutter pub get

# Determine targets based on platform
TARGETS=""
if [ "$PLATFORM" == "linux" ]; then
    # AppImage maker is having issues with ldd, using deb as primary
    TARGETS="deb"
elif [ "$PLATFORM" == "macos" ]; then
    TARGETS="dmg,pkg"
elif [ "$PLATFORM" == "windows" ]; then
    TARGETS="exe,msix"
fi

# Use flutter_distributor to create the installer
if [ "$PLATFORM" == "windows" ]; then
    flutter_distributor.bat package --platform $PLATFORM --targets $TARGETS
else
    flutter_distributor package --platform $PLATFORM --targets $TARGETS
fi

# Final sync: for Linux .deb/AppImage we sometimes need samples in a specific place
# This is a bit of a hack because distributor runs its own build
if [ "$PLATFORM" == "linux" ]; then
   echo "🔗 Finalizing Linux bundle..."
   # Note: distributor puts things in frontend/dist/
fi

echo "✅ Build complete! Check frontend/dist/ directory for installers."
