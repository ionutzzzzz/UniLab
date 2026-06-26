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

# 4. Setup Standalone Python and Virtualenv
echo "📦 Bundling standalone Python interpreter and stdlib..."
mkdir -p "$INSTALL_DIR/python/bin"
mkdir -p "$INSTALL_DIR/python/lib"
# Copy Python 3.13 executable (dereferencing symlinks)
cp -L /usr/bin/python3.13 "$INSTALL_DIR/python/bin/python3"
chmod +x "$INSTALL_DIR/python/bin/python3"
# Copy standard library
rsync -a --exclude="__pycache__" /usr/lib/python3.13/ "$INSTALL_DIR/python/lib/python3.13/"
# Copy python shared library so PyO3 and other components can use it
cp /usr/lib/aarch64-linux-gnu/libpython3.13.so.1.0 "$INSTALL_DIR/python/lib/"

echo "🐍 Creating virtualenv using bundled Python..."
"$INSTALL_DIR/python/bin/python3" -m venv "$INSTALL_DIR/venv"
# Use the venv's pip
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip

# Create a requirements list including all heavy libraries to be self-contained
cat <<EOF > "$BUILD_DIR/requirements.txt"
numpy==2.4.4
scipy>=1.10.0
matplotlib==3.10.9
pandas>=2.0.0
sympy
Pillow
scikit-learn>=1.2.0
lark==1.3.1
fastapi
uvicorn[standard]
gunicorn
pydantic
python-dotenv
python-multipart
httpx
pytest-asyncio
aiofiles
EOF

echo "📦 Installing all Python dependencies inside virtualenv..."
"$INSTALL_DIR/venv/bin/pip" install --ignore-installed -r "$BUILD_DIR/requirements.txt"
rm "$BUILD_DIR/requirements.txt"

# 5. Fix Paths and Shebangs for Portability
echo "🩹 Fixing virtualenv shebangs and paths for portability..."
# Fix all python shebangs in venv/bin/
find "$INSTALL_DIR/venv/bin" -type f -executable -exec sed -i "1s|^#!.*python.*|#!/opt/unilab/venv/bin/python3|" {} +

# Fix the python symlinks inside the virtualenv bin to be relative
cd "$INSTALL_DIR/venv/bin"
ln -sf ../../python/bin/python3 python3
ln -sf python3 python
ln -sf python3 python3.13
cd "$PROJECT_ROOT"

# Overwrite pyvenv.cfg to use the target machine's path
cat <<EOF > "$INSTALL_DIR/venv/pyvenv.cfg"
home = /opt/unilab/python/bin
include-system-site-packages = false
version = 3.13.5
executable = /opt/unilab/python/bin/python3
command = /opt/unilab/python/bin/python3 -m venv /opt/unilab/venv
EOF

# 6. Create Wrapper Scripts in /usr/bin
echo "📜 Creating wrapper scripts..."

# Main UniLab CLI (Python/Braille)
cat <<EOF > "$BUILD_DIR/usr/bin/unilab"
#!/bin/bash
export LD_LIBRARY_PATH="/opt/unilab/python/lib:\$LD_LIBRARY_PATH"
export PYTHONPATH=/opt/unilab
/opt/unilab/venv/bin/python3 /opt/unilab/backend/UniLab.py "\$@"
EOF
chmod +x "$BUILD_DIR/usr/bin/unilab"

# UniLab Server (FastAPI)
cat <<EOF > "$BUILD_DIR/usr/bin/unilab-server"
#!/bin/bash
export LD_LIBRARY_PATH="/opt/unilab/python/lib:\$LD_LIBRARY_PATH"
export PYTHONPATH=/opt/unilab
cd /opt/unilab/backend
/opt/unilab/venv/bin/gunicorn -w 4 -k uvicorn.workers.UvicornWorker api.main:app --bind 0.0.0.0:8000
EOF
chmod +x "$BUILD_DIR/usr/bin/unilab-server"

# Rust CLI
cat <<EOF > "$BUILD_DIR/usr/bin/unilab-cli-rust"
#!/bin/bash
export LD_LIBRARY_PATH="/opt/unilab/python/lib:\$LD_LIBRARY_PATH"
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
Depends: libblas3, liblapack3, libstdc++6, libc6, libgl1, libfontconfig1, libx11-6
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
