#!/usr/bin/env bash
set -euo pipefail

# Synchronizes sample/ tree into frontend/assets/samples/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." &>/dev/null && pwd)"

SAMPLE_ASSETS="$PROJECT_ROOT/frontend/assets/samples"

echo "🔄 Syncing sample assets into frontend/assets/samples/..."
mkdir -p "$SAMPLE_ASSETS"

rsync -a --delete \
  --exclude=".DS_Store" \
  "$PROJECT_ROOT/sample/" "$SAMPLE_ASSETS/"

echo "✅ Sample assets synchronized successfully."
