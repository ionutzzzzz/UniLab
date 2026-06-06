#!/bin/bash

# test_samples_transpiler.sh - UniLab Backend Sample Verification Script using Transpiler Engine
# Runs all MATLAB samples in the sample/ directory and reports results.

export PYTHONPATH=$PYTHONPATH:.

# Statistics
TOTAL=0
PASSED=0
FAILED=0
FAILED_FILES=()

echo "===================================================="
echo "🚀 UniLab Sample Verification Suite (Transpiler Engine)"
echo "===================================================="
echo ""

# Find all .m files in sample/ directory and its subdirectories, sorted
SAMPLES=$(find sample/ -name "*.m" | sort)

for sample in $SAMPLES; do
    ((TOTAL++))
    filename=$sample
    
    echo -n "[$TOTAL] Running $filename... "
    
    output_file=$(mktemp)
    
    # Force the transpiler engine
    timeout 60s python3 backend/cli/app.py run "$sample" --engine transpiler > "$output_file" 2>&1
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        if grep -q "Status: FAILED" "$output_file"; then
             echo "❌ FAILED (Execution Error)"
             ((FAILED++))
             error_msg=$(grep -A 5 "Status: FAILED" "$output_file" | tail -n 3)
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
        echo "❌ FAILED (Crash)"
        ((FAILED++))
        error_msg=$(tail -n 1 "$output_file")
        FAILED_FILES+=("$filename: $error_msg")
    fi
    
    rm "$output_file"
done

echo ""
echo "===================================================="
echo "📊 Test Summary"
echo "===================================================="
echo "Total Samples: $TOTAL"
echo "Passed:        $PASSED"
echo "Failed:        $FAILED"
if [ $TOTAL -gt 0 ]; then
    echo "Success Rate:  $(echo "scale=2; $PASSED * 100 / $TOTAL" | bc)%"
fi

if [ $FAILED -gt 0 ]; then
    echo ""
    echo "❌ Failures:"
    for entry in "${FAILED_FILES[@]}"; do
        echo "  - $entry"
    done
fi
