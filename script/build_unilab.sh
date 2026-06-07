#!/bin/bash
set -e

# Build Unilab-core (CLI) and Unilab (GUI) versions

echo "🚀 Preparing UniLab Versions..."

# 1. Build Rust Core
echo "🦀 Building Rust Core..."
cd backend
cargo build --release -p unilab_core
cargo build --release -p unilab_cli
cd ..

# 2. Build Flutter GUI
echo "💙 Building Flutter GUI (Linux)..."
cd frontend
flutter build linux --release
cd ..

# 3. Prepare Release Directory
RELEASE_DIR="./release"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR/Unilab-core"
mkdir -p "$RELEASE_DIR/Unilab"

# --- VERSION: Unilab-core (CLI) ---
echo "📦 Packaging Unilab-core..."
cp backend/target/release/unilab_cli "$RELEASE_DIR/Unilab-core/unilab-core"
# Copy dependencies
mkdir -p "$RELEASE_DIR/Unilab-core/lib"
cp backend/target/release/libunilab_core.so "$RELEASE_DIR/Unilab-core/lib/"
# Create a wrapper script for core
cat <<EOF > "$RELEASE_DIR/Unilab-core/run.sh"
#!/bin/bash
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:./lib
./unilab-core "\$@"
EOF
chmod +x "$RELEASE_DIR/Unilab-core/run.sh"

# --- VERSION: Unilab (GUI) ---
echo "📦 Packaging Unilab (GUI)..."
cp -r frontend/build/linux/x64/release/bundle/* "$RELEASE_DIR/Unilab/"
# Rename the executable
mv "$RELEASE_DIR/Unilab/unilab" "$RELEASE_DIR/Unilab/Unilab"

echo "✅ Done! Versions are ready in $RELEASE_DIR"
echo "  - Unilab-core: $RELEASE_DIR/Unilab-core/"
echo "  - Unilab: $RELEASE_DIR/Unilab/"
