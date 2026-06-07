#!/bin/bash
set -e

echo "🚀 Starting UniLab Production Build..."

# 1. Build Rust Core
echo "🦀 Building Rust Core..."
cd backend
cargo build --release -p unilab_core
cd ..

# 2. Build Flutter Web
echo "💙 Building Flutter Web..."
cd frontend
flutter build web --release
cd ..

# 3. Create Distribution Folder
echo "📦 Preparing distribution folder..."
DIST_DIR="./dist"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/backend"
mkdir -p "$DIST_DIR/frontend"

# Copy backend files
cp -r backend/core backend/api backend/utils backend/stdlib backend/packages "$DIST_DIR/backend/"
cp backend/requirements.txt "$DIST_DIR/"
cp backend/target/release/libunilab_core.so "$DIST_DIR/backend/core/engines/" 2>/dev/null || \
cp backend/target/release/unilab_core.dll "$DIST_DIR/backend/core/engines/" 2>/dev/null || \
cp backend/target/release/libunilab_core.dylib "$DIST_DIR/backend/core/engines/" 2>/dev/null

# Copy frontend web build
cp -r frontend/build/web/* "$DIST_DIR/frontend/"

# Copy production runner script
cat <<EOF > "$DIST_DIR/run_production.sh"
#!/bin/bash
export PYTHONPATH=$PYTHONPATH:.
export UNILAB_WORKSPACE_ROOT=./workspaces
mkdir -p ./workspaces
gunicorn -w 4 -k uvicorn.workers.UvicornWorker backend.api.main:app --bind 0.0.0.0:8000
EOF
chmod +x "$DIST_DIR/run_production.sh"

echo "✅ Production build complete! See the '$DIST_DIR' directory."
echo "To run the API: cd $DIST_DIR && ./run_production.sh"