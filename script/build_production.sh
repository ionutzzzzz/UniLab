#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." &>/dev/null && pwd)"
cd "$PROJECT_ROOT"

echo "🚀 Starting UniLab Production Build..."

# 0. Sync assets into frontend/assets
"$SCRIPT_DIR/sync_assets.sh"

# 1. Build Rust Core (if cargo is available)
if command -v cargo >/dev/null 2>&1; then
    echo "🦀 Building Rust Core..."
    (cd backend && cargo build --release -p unilab_core)
else
    echo "⚠️ cargo not found; skipping native Rust compilation (using Python Transpiler Engine)."
fi

# 2. Build Flutter Web
echo "💙 Building Flutter Web..."
(cd frontend && flutter build web --release)

# 3. Create Distribution Folder
echo "📦 Preparing distribution folder..."
DIST_DIR="./dist"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/backend"
mkdir -p "$DIST_DIR/frontend"

# Copy backend files
cp -r backend/core backend/api backend/cli backend/utils backend/stdlib backend/__init__.py backend/__main__.py backend/UniLab.py "$DIST_DIR/backend/"
cp backend/requirements.txt "$DIST_DIR/"
mkdir -p "$DIST_DIR/backend/core/engines"
if [ -d "backend/target/release" ]; then
    cp backend/target/release/libunilab_core.so "$DIST_DIR/backend/core/unilab_rust_core.so" 2>/dev/null || true
    cp backend/target/release/libunilab_core.so "$DIST_DIR/backend/core/engines/" 2>/dev/null || \
    cp backend/target/release/unilab_core.dll "$DIST_DIR/backend/core/engines/" 2>/dev/null || \
    cp backend/target/release/libunilab_core.dylib "$DIST_DIR/backend/core/engines/" 2>/dev/null || true
fi

# Copy frontend web build
cp -r frontend/build/web/* "$DIST_DIR/frontend/"

# Copy production runner script (1 worker preserves in-memory session state)
cat <<'EOF' > "$DIST_DIR/run_production.sh"
#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:."
export UNILAB_WORKSPACE_ROOT=./workspaces
export UNILAB_API_SERVER=1
export MPLBACKEND=Agg
mkdir -p ./workspaces
exec gunicorn -w 1 -k uvicorn.workers.UvicornWorker backend.api.main:app --bind 0.0.0.0:8000
EOF
chmod +x "$DIST_DIR/run_production.sh"

echo "✅ Production build complete! See the '$DIST_DIR' directory."
echo "To run the API: cd $DIST_DIR && ./run_production.sh"
