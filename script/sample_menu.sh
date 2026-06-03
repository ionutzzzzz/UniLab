#!/bin/bash

# sample_menu.sh - Advanced UniLab Laboratory Dashboard
# Interactive menu for running samples, tests, and visual demos.

export PATH="/root/Programming/.cargo/bin:$PATH"
PROJECT_ROOT=$(pwd)
MANIFEST_PATH="$PROJECT_ROOT/backend/Cargo.toml"
SAMPLE_DIR="$PROJECT_ROOT/sample"
TEST_DIR="$PROJECT_ROOT/backend/tests/unit"

# Colors
C_BLUE="\x1b[38;2;137;207;240m"
C_PURPLE="\x1b[38;2;191;148;228m"
C_YELLOW="\x1b[38;2;253;253;150m"
C_GREEN="\x1b[38;2;119;221;119m"
C_RED="\x1b[38;2;255;105;97m"
C_GRAY="\x1b[38;2;169;169;169m"
RESET="\x1b[0m"

# Utility: Press any key to continue
pause() {
    echo -e "\n${C_GRAY}Press any key to return to menu...${RESET}"
    read -n 1 -s
}

# Function to run a MATLAB sample
run_sample() {
    local file=$1
    clear
    echo -e "${C_BLUE}====================================================${RESET}"
    echo -e "🚀 ${C_BLUE}Executing Sample:${RESET} $(basename "$file")"
    echo -e "${C_BLUE}====================================================${RESET}"
    echo ""
    cargo run --quiet --manifest-path "$MANIFEST_PATH" --bin unilab_cli -- "$file"
    pause
}

# Function to run Python unit tests
run_test() {
    local test_name=$1
    local test_file=$2
    clear
    echo -e "${C_PURPLE}====================================================${RESET}"
    echo -e "🧪 ${C_PURPLE}Running Test Group:${RESET} $test_name"
    echo -e "${C_PURPLE}====================================================${RESET}"
    echo ""
    python3 -m pytest "$test_file" -v
    pause
}

# Function to run visual demos
run_demo() {
    local demo_name=$1
    local demo_file=$2
    clear
    echo -e "${C_YELLOW}====================================================${RESET}"
    echo -e "🎨 ${C_YELLOW}Visual Demo:${RESET} $demo_name"
    echo -e "${C_YELLOW}====================================================${RESET}"
    echo ""
    python3 "$demo_file"
    pause
}

# Main Loop
while true; do
    SAMPLES=($(find "$SAMPLE_DIR" -maxdepth 1 -name "*.m" | sort))
    NUM_SAMPLES=${#SAMPLES[@]}

    clear
    echo -e "${C_BLUE}====================================================${RESET}"
    echo -e "🔬 ${C_BLUE}UniLab Scientific Laboratory Dashboard${RESET}"
    echo -e "${C_BLUE}====================================================${RESET}"
    
    # Grid Layout for Samples
    echo -e "${C_GRAY}--- [S] MATLAB Scientific Samples (1-$NUM_SAMPLES) ---${RESET}"
    for ((i=0; i<NUM_SAMPLES; i++)); do
        name=$(basename "${SAMPLES[$i]}")
        num=$((i+1))
        # Highlight some specific categories by number if we wanted to
        printf " %2d) %-34s" $num "${name:0:34}"
        if [ $(( (i+1) % 2 )) -eq 0 ]; then echo ""; fi
    done
    [ $(( NUM_SAMPLES % 2 )) -ne 0 ] && echo ""
    
    echo ""
    echo -e "${C_PURPLE}--- [T] Automated Test Suites ---${RESET}"
    echo -e "  T1) Core Logic & Sessions      T2) Transpiler & Grammar"
    echo -e "  T3) API Endpoints              T4) Statistics Library"
    echo -e "  T5) Full Test Suite (Pytest)   T6) Sample Compatibility"
    
    echo ""
    echo -e "${C_YELLOW}--- [V] Visuals & Graphics ---${RESET}"
    echo -e "  V1) TrueColor Support Test     V2) Braille Image Rendering"
    echo -e "  V3) ASCII Plotting Showcase    V4) Terminal Color Palette"
    
    echo ""
    echo -e "${C_GRAY}--- [A] Operations ---${RESET}"
    echo -e "  A) Run All Samples (Batch)     H) System Health & Metrics"
    echo -e "  X) Exit Dashboard"
    echo ""
    echo -e -n "${C_BLUE}Select Option >> ${RESET}"
    read choice

    case $choice in
        [Xx] | "exit") exit 0 ;;
        
        # Samples
        [0-9]*)
            if [ "$choice" -ge 1 ] && [ "$choice" -le "$NUM_SAMPLES" ]; then
                run_sample "${SAMPLES[$((choice-1))]}"
            fi
            ;;
            
        # Tests
        T1) run_test "Core Engine" "$TEST_DIR/test_core.py $TEST_DIR/test_core_advanced.py" ;;
        T2) run_test "Transpiler" "$TEST_DIR/test_transpiler.py $TEST_DIR/test_transpiler_advanced.py" ;;
        T3) run_test "REST API" "$TEST_DIR/test_api_endpoints.py" ;;
        T4) run_test "Stats Library" "$TEST_DIR/test_stats_lib.py" ;;
        T5) run_test "Full Suite" "$TEST_DIR" ;;
        T6) run_test "Sample Integration" "$TEST_DIR/test_samples.py" ;;
        
        # Visuals
        V1) run_demo "TrueColor Test" "$TEST_DIR/test_color.py" ;;
        V2) run_demo "Braille Rendering" "$TEST_DIR/test_braille.py" ;;
        V3) run_demo "ASCII Plotting" "$TEST_DIR/test_plots.py" ;;
        V4) run_demo "Terminal Palette" "$TEST_DIR/test_terminal_colors.py" ;;
        
        # Operations
        [Aa])
            if [ -f "./run_samples.sh" ]; then
                ./run_samples.sh
                pause
            fi
            ;;
        [Hh])
            clear
            echo -e "${C_GREEN}--- System Health ---${RESET}"
            curl -s http://localhost:8000/api/v1/health | python3 -m json.tool || echo "API not running (Run UniLab.sh first)"
            echo -e "\n${C_GREEN}--- Rust Backend Status ---${RESET}"
            cargo --version
            echo -e "\n${C_GREEN}--- Python Environment ---${RESET}"
            pip list | grep -E "numpy|scipy|matplotlib|fastapi"
            pause
            ;;
        *)
            ;;
    esac
done
