#!/bin/bash

# sample_menu.sh - Interactive Menu for UniLab Samples
# Allows selecting and running individual MATLAB samples.

export PATH="/root/Programming/.cargo/bin:$PATH"
PROJECT_ROOT=$(pwd)
MANIFEST_PATH="$PROJECT_ROOT/backend/Cargo.toml"
SAMPLE_DIR="$PROJECT_ROOT/sample"

# Function to run a sample
run_sample() {
    local file=$1
    clear
    echo "===================================================="
    echo "🏃 Executing: $(basename "$file")"
    echo "===================================================="
    echo ""
    
    # Run the sample
    cargo run --quiet --manifest-path "$MANIFEST_PATH" --bin unilab_cli -- "$file"
    
    echo ""
    echo "===================================================="
    echo "✅ Execution finished. Press any key to return to menu."
    read -n 1 -s
}

# Main loop
while true; do
    # Refresh sample list (handles added/removed files)
    SAMPLES=($(find "$SAMPLE_DIR" -maxdepth 2 -name "*.m" | sort))
    NUM_SAMPLES=${#SAMPLES[@]}

    clear
    echo "===================================================="
    echo "🧪 UniLab Interactive Sample Laboratory"
    echo "===================================================="
    echo "Available Samples:"
    echo ""

    # Print samples in 2 columns to save space
    for ((i=0; i<NUM_SAMPLES; i++)); do
        name=$(basename "${SAMPLES[$i]}")
        printf "%2d) %-40s" $((i+1)) "$name"
        if [ $(( (i+1) % 2 )) -eq 0 ]; then echo ""; fi
    done
    echo ""
    [ $(( NUM_SAMPLES % 2 )) -ne 0 ] && echo ""

    echo "----------------------------------------------------"
    echo "  A) Run All Samples         X) Exit"
    echo "----------------------------------------------------"
    echo -n "Select an option (1-$NUM_SAMPLES): "
    read choice

    case $choice in
        [Xx] | "exit" | "quit")
            echo "Goodbye!"
            exit 0
            ;;
        [Aa] | "all")
            echo "Starting batch execution of all samples..."
            if [ -f "./run_samples.sh" ]; then
                ./run_samples.sh
            else
                for s in "${SAMPLES[@]}"; do run_sample "$s"; done
            fi
            echo "Batch execution complete. Press any key."
            read -n 1 -s
            ;;
        *)
            # Check if it's a number
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$NUM_SAMPLES" ]; then
                idx=$((choice - 1))
                run_sample "${SAMPLES[$idx]}"
            else
                echo "Invalid selection. Press any key."
                read -n 1 -s
            fi
            ;;
    esac
done
