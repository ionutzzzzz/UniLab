#!/bin/bash
set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." &> /dev/null && pwd)"
PKG_NAME="unilab-core"
PKG_VERSION="0.1.0"
PKG_ARCH=$(dpkg --print-architecture)
BUILD_DIR="$PROJECT_ROOT/build_deb"
INSTALL_DIR="$BUILD_DIR/opt/unilab"

echo "🛠️ Creating .deb package for $PKG_NAME version $PKG_VERSION ($PKG_ARCH)..."
echo "📂 Project Root: $PROJECT_ROOT"

# 1. Cleanup and Prepare Directories
rm -rf "$BUILD_DIR"
mkdir -p "$INSTALL_DIR/backend"
mkdir -p "$INSTALL_DIR/bin"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/DEBIAN"

# 2. Build Rust Components
echo "🦀 Building Rust components..."
cd "$PROJECT_ROOT/backend"
cargo build --release
cd "$PROJECT_ROOT"

# 3. Copy Backend Files
echo "📂 Copying backend files..."
# Only copy necessary directories and files, excluding caches and build artifacts
rsync -a --exclude="__pycache__" --exclude="target" \
    "$PROJECT_ROOT/backend/core" \
    "$PROJECT_ROOT/backend/api" \
    "$PROJECT_ROOT/backend/utils" \
    "$PROJECT_ROOT/backend/stdlib" \
    "$PROJECT_ROOT/backend/UniLab.py" \
    "$INSTALL_DIR/backend/"

# Copy the Rust shared library to the expected location for Python import
cp "$PROJECT_ROOT/backend/target/release/libunilab_core.so" "$INSTALL_DIR/backend/core/unilab_rust_core.so"
# Copy the Rust CLI
cp "$PROJECT_ROOT/backend/target/release/unilab_cli" "$INSTALL_DIR/bin/unilab-cli"

# 4. Setup Virtualenv and Install Dependencies
echo "🐍 Setting up virtualenv and installing dependencies (this may take a while)..."
python3 -m venv "$INSTALL_DIR/venv"
# Use the venv's pip
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip
# Install requirements
"$INSTALL_DIR/venv/bin/pip" install -r "$PROJECT_ROOT/backend/requirements.txt"

# 5. Fix Virtualenv Shebangs for Portability
echo "🩹 Fixing virtualenv shebangs..."
find "$INSTALL_DIR/venv/bin" -type f -executable -exec sed -i "1s|^#!.*python.*|#!/opt/unilab/venv/bin/python3|" {} +

# 6. Create Wrapper Scripts in /usr/bin
echo "📜 Creating wrapper scripts..."

# Main UniLab CLI (Python/Braille)
cat <<EOF > "$BUILD_DIR/usr/bin/unilab"
#!/bin/bash
export PYTHONPATH=/opt/unilab
cd /opt/unilab/backend
/opt/unilab/venv/bin/python3 UniLab.py "\$@"
EOF
chmod +x "$BUILD_DIR/usr/bin/unilab"

# UniLab Server (FastAPI)
cat <<EOF > "$BUILD_DIR/usr/bin/unilab-server"
#!/bin/bash
export PYTHONPATH=/opt/unilab
cd /opt/unilab/backend
/opt/unilab/venv/bin/gunicorn -w 4 -k uvicorn.workers.UvicornWorker api.main:app --bind 0.0.0.0:8000
EOF
chmod +x "$BUILD_DIR/usr/bin/unilab-server"

# Rust CLI
cat <<EOF > "$BUILD_DIR/usr/bin/unilab-cli-rust"
#!/bin/bash
/opt/unilab/bin/unilab-cli "\$@"
EOF
chmod +x "$BUILD_DIR/usr/bin/unilab-cli-rust"

# 7. Create Control File
echo "📝 Creating control file..."
cat <<EOF > "$BUILD_DIR/DEBIAN/control"
Package: $PKG_NAME
Version: $PKG_VERSION
Section: science
Priority: optional
Architecture: $PKG_ARCH
Depends: python3, libblas3, liblapack3, libstdc++6, libc6, libqt5gui5, libqt5widgets5, libqt5core5a, libgl1, libfontconfig1, libx11-6
Maintainer: UniLab Team <contact@unilab.dev>
Description: UniLab Core - Computational Intelligence and Simulation Engine
 Includes the Python backend and Rust core.
 Optimized for high-performance scientific simulations.
 Provides both a Braille-capable CLI and a FastAPI server.
EOF

# 8. Create Post-Install Script
cat <<EOF > "$BUILD_DIR/DEBIAN/postinst"
#!/bin/bash
set -e
# Ensure workspace directory exists and is writable
mkdir -p /var/lib/unilab/workspaces
chmod 777 /var/lib/unilab/workspaces
exit 0
EOF
chmod +x "$BUILD_DIR/DEBIAN/postinst"

# 9. Build the Package
echo "📦 Building .deb package..."
cd "$PROJECT_ROOT"
dpkg-deb --build "build_deb" "${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.deb"

echo "✅ Success! Package created at root: ${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.deb"
