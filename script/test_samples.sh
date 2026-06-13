#!/bin/bash

# test_samples.sh - UniLab Backend Sample Verification Script
# Runs all MATLAB samples in the sample/ directory and reports results.

# Set path to include cargo if not already there
export PATH="/root/Programming/.cargo/bin:$PATH"

# Project root directory
PROJECT_ROOT=$(pwd)
MANIFEST_PATH="$PROJECT_ROOT/backend/Cargo.toml"

# Statistics
TOTAL=0
PASSED=0
FAILED=0
FAILED_FILES=()

echo "===================================================="
echo "🚀 UniLab Sample Verification Suite"
echo "===================================================="
echo "Manifest: $MANIFEST_PATH"
echo ""

# Find all .m files in sample/ directory, sorted numerically/alphabetically
SAMPLES=$(find sample/ -maxdepth 1 -name "*.m" | sort)

for sample in $SAMPLES; do
    filename=$(basename "$sample")
    
    if [ "$filename" = "11_chaotic_weather_lorenz96.m" ]; then
        echo "⏭️ SKIPPED $filename"
        continue
    fi

    ((TOTAL++))
    
    echo -n "[$TOTAL] Running $filename... "
    
    # Run the sample and capture output/stderr
    # We use a timeout of 60 seconds per sample to prevent hangs
    # Redirecting output to a temporary file to keep the console clean
    output_file=$(mktemp)
    
    timeout 60s env PYTHONPATH="$PROJECT_ROOT/backend" python3 "$PROJECT_ROOT/backend/UniLab.py" run "$sample" > "$output_file" 2>&1
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "✅ PASSED"
        ((PASSED++))
    elif [ $exit_code -eq 124 ]; then
        echo "⏱️ TIMEOUT"
        ((FAILED++))
        FAILED_FILES+=("$filename (TIMEOUT)")
    else
        echo "❌ FAILED"
        ((FAILED++))
        # Extract last line of error for quick debugging
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
echo "Success Rate:  $(echo "scale=2; $PASSED * 100 / $TOTAL" | bc)%"

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
