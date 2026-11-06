#!/usr/bin/env bash
set -euo pipefail

# Synchronizes canonical backend/ and sample/ trees into frontend/assets/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." &>/dev/null && pwd)"

BACKEND_ASSETS="$PROJECT_ROOT/frontend/assets/backend/backend"
SAMPLE_ASSETS="$PROJECT_ROOT/frontend/assets/samples"

echo "🔄 Syncing backend and sample assets into frontend/assets/..."

mkdir -p "$BACKEND_ASSETS" "$SAMPLE_ASSETS"

rsync -a --delete \
  --exclude="__pycache__" \
  --exclude="*.pyc" \
  --exclude="*.pyo" \
  --exclude="*.so" \
  --exclude="*.dylib" \
  --exclude="*.dll" \
  --exclude="target" \
  --exclude="tests" \
  --exclude="unilab_core" \
  --exclude="unilab_cli" \
  --exclude="Cargo.toml" \
  --exclude="Cargo.lock" \
  "$PROJECT_ROOT/backend/" "$BACKEND_ASSETS/"

rsync -a --delete \
  --exclude=".DS_Store" \
  "$PROJECT_ROOT/sample/" "$SAMPLE_ASSETS/"

echo "✅ Frontend assets synchronized successfully."
