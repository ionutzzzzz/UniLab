#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." &>/dev/null && pwd)"

cd "$PROJECT_ROOT"
export PYTHONPATH="${PROJECT_ROOT}:${PYTHONPATH:-}"
export UNILAB_API_SERVER=1
export MPLBACKEND=Agg

exec python3 -m uvicorn backend.api.main:app --host "${HOST:-127.0.0.1}" --port "${PORT:-8000}"
