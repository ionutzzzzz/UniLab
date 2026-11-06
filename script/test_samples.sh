#!/usr/bin/env bash

# test_samples.sh - UniLab Sample Verification Suite
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
exec "$SCRIPT_DIR/test_samples_transpiler.sh" "$@"
