#!/usr/bin/env bash
set -u

# test_samples.sh - Unified UniLab Sample Verification Suite
# Supports --engine [transpiler|python|rust] (default: transpiler)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." &>/dev/null && pwd)"
cd "$PROJECT_ROOT"

ENGINE="transpiler"
TIMEOUT_SECS=60
SPECIFIC_SAMPLE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --engine)
            ENGINE="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT_SECS="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Usage: $0 [--engine transpiler|python|rust] [--timeout seconds] [sample.m]"
            exit 1
            ;;
        *)
            SPECIFIC_SAMPLE="$1"
            shift
            ;;
    esac
done

export PYTHONPATH="${PROJECT_ROOT}:${PYTHONPATH:-}"
export UNILAB_WEB_MODE=1
export MPLBACKEND=Agg

if [ -z "${PYTHON_BIN:-}" ] || [ "$PYTHON_BIN" = "python3" ]; then
    if [ -x "/opt/unilab/venv/bin/python3" ]; then
        PYTHON_BIN="/opt/unilab/venv/bin/python3"
    elif [ -x "$PROJECT_ROOT/.venv/bin/python3" ] && "$PROJECT_ROOT/.venv/bin/python3" -c "import numpy" &>/dev/null; then
        PYTHON_BIN="$PROJECT_ROOT/.venv/bin/python3"
    elif [ -x "$PROJECT_ROOT/backend/venv/bin/python3" ]; then
        PYTHON_BIN="$PROJECT_ROOT/backend/venv/bin/python3"
    elif [ -x "$HOME/anaconda3/bin/python3" ]; then
        PYTHON_BIN="$HOME/anaconda3/bin/python3"
    elif [ -x "/opt/homebrew/bin/python3" ]; then
        PYTHON_BIN="/opt/homebrew/bin/python3"
    else
        PYTHON_BIN="python3"
    fi
fi

if [ -f "$PROJECT_ROOT/backend/target/release/libunilab_core.so" ]; then
    ln -sf "$PROJECT_ROOT/backend/target/release/libunilab_core.so" "$PROJECT_ROOT/backend/core/unilab_rust_core.so" 2>/dev/null || true
elif [ -f "$PROJECT_ROOT/backend/target/release/libunilab_core.dylib" ]; then
    ln -sf "$PROJECT_ROOT/backend/target/release/libunilab_core.dylib" "$PROJECT_ROOT/backend/core/unilab_rust_core.so" 2>/dev/null || true
fi

run_with_timeout() {
    local secs="$1"
    shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "${secs}s" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "${secs}s" "$@"
    else
        "$PYTHON_BIN" - "$secs" "$@" <<'PY'
import subprocess, sys
timeout_s = float(sys.argv[1])
cmd = sys.argv[2:]
try:
    res = subprocess.run(cmd, timeout=timeout_s)
    sys.exit(res.returncode)
except subprocess.TimeoutExpired:
    sys.exit(124)
PY
    fi
}

TOTAL=0
PASSED=0
FAILED=0
FAILED_FILES=()

echo "===================================================="
echo "🚀 UniLab Sample Verification Suite (Engine: $ENGINE)"
echo "===================================================="
echo ""

if [ -n "$SPECIFIC_SAMPLE" ]; then
    SAMPLES="$SPECIFIC_SAMPLE"
else
    SAMPLES=$(find sample/ -name "*.m" | sort)
fi

for sample in $SAMPLES; do
    ((TOTAL++))
    filename="$sample"
    echo -n "[$TOTAL] Running $filename... "

    output_file=$(mktemp)
    if [ "$ENGINE" = "rust" ]; then
        RUST_CLI="$PROJECT_ROOT/backend/target/release/unilab_cli"
        if [ ! -f "$RUST_CLI" ]; then
            RUST_CLI="$PROJECT_ROOT/backend/target/debug/unilab_cli"
        fi
        run_with_timeout "$TIMEOUT_SECS" "$RUST_CLI" "$sample" > "$output_file" 2>&1
    elif [ "$ENGINE" = "python" ]; then
        run_with_timeout "$TIMEOUT_SECS" env DISPLAY= "$PYTHON_BIN" backend/cli/app.py run "$sample" > "$output_file" 2>&1
    else
        run_with_timeout "$TIMEOUT_SECS" env DISPLAY= "$PYTHON_BIN" backend/cli/app.py run "$sample" --engine "$ENGINE" > "$output_file" 2>&1
    fi
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        if grep -q "Status: FAILED" "$output_file"; then
            echo "❌ FAILED (Execution Error)"
            ((FAILED++))
            error_msg=$(grep -A 5 "Status: FAILED" "$output_file" | tail -n 3 | tr '\n' ' ')
            FAILED_FILES+=("$filename: $error_msg")
        else
            echo "✅ PASSED"
            ((PASSED++))
        fi
    elif [ $exit_code -eq 124 ]; then
        echo "⏱️ TIMEOUT"
        ((FAILED++))
        FAILED_FILES+=("$filename (TIMEOUT)")
    else
        echo "❌ FAILED (Exit $exit_code)"
        ((FAILED++))
        error_msg=$(tail -n 1 "$output_file")
        FAILED_FILES+=("$filename: $error_msg")
    fi

    rm -f "$output_file"
done

echo ""
echo "===================================================="
echo "📊 Test Summary"
echo "===================================================="
echo "Total Samples: $TOTAL"
echo "Passed:        $PASSED"
echo "Failed:        $FAILED"
if [ $TOTAL -gt 0 ]; then
    echo "Success Rate:  $(awk "BEGIN { printf \"%.2f\", ($PASSED * 100) / $TOTAL }")%"
fi

if [ $FAILED -gt 0 ]; then
    echo ""
    echo "❌ Failures:"
    for entry in "${FAILED_FILES[@]}"; do
        echo "  - $entry"
    done
    exit 1
fi

echo ""
echo "🎉 All samples passed successfully!"
exit 0
