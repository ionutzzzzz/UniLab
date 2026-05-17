#!/bin/bash

##############################################################################
# UniLab API Test Suite - Main Test Runner
# 
# This script tests all API endpoints for the UniLab backend.
# Usage: ./test_api.sh [--config config.sh] [--filter test_name] [--verbose]
##############################################################################

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default configuration
CONFIG_FILE="${SCRIPT_DIR}/config.sh"
VERBOSE=false
FILTER=""
TEST_RESULTS_DIR="/tmp/unilab_tests"
mkdir -p "$TEST_RESULTS_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --config) CONFIG_FILE="$2"; shift 2 ;;
        --filter) FILTER="$2"; shift 2 ;;
        --verbose) VERBOSE=true; shift ;;
        --help) show_help; exit 0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo -e "${RED}Error: Config file not found: $CONFIG_FILE${NC}"
    exit 1
fi

# Load utilities
source "${SCRIPT_DIR}/utils.sh"

# Global test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Test results tracking
declare -a TEST_RESULTS
declare -a FAILED_TEST_DETAILS

##############################################################################
# Test Execution Function
##############################################################################

run_test() {
    local test_name="$1"
    local test_func="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Check if test should be run
    if [ -n "$FILTER" ] && [[ ! "$test_name" =~ $FILTER ]]; then
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
        return
    fi
    
    if [ "$VERBOSE" = true ]; then
        echo -e "\n${BLUE}[TEST] $test_name${NC}"
    fi
    
    if $test_func; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS+=("$test_name: ${GREEN}PASS${NC}")
        if [ "$VERBOSE" = true ]; then
            echo -e "${GREEN}✓ PASS${NC}"
        fi
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS+=("$test_name: ${RED}FAIL${NC}")
        FAILED_TEST_DETAILS+=("$test_name")
        if [ "$VERBOSE" = true ]; then
            echo -e "${RED}✗ FAIL${NC}"
        fi
    fi
}

##############################################################################
# Test Suites
##############################################################################

# Session Management Tests
test_create_session() {
    local response=$(http_post "/api/v1/sessions" "{\"username\": \"testuser\", \"engine\": \"transpiler\"}")
    local session_id=$(echo "$response" | jq -r '.session_id // empty')
    
    if [ -z "$session_id" ] || [ "$session_id" = "null" ]; then
        return 1
    fi
    
    # Save for later use
    echo "$session_id" > "$TEST_RESULTS_DIR/session_id.txt"
    return 0
}

test_list_sessions() {
    local response=$(http_get "/api/v1/sessions")
    local total=$(echo "$response" | jq '.total // 0')
    
    [ "$total" -ge 0 ] && return 0 || return 1
}

test_get_session() {
    # This requires a session to exist
    if [ ! -f "$TEST_RESULTS_DIR/session_id.txt" ]; then
        test_create_session || return 1
    fi
    
    local session_id=$(cat "$TEST_RESULTS_DIR/session_id.txt")
    local response=$(http_get "/api/v1/sessions/$session_id")
    local returned_id=$(echo "$response" | jq -r '.session_id // empty')
    
    [ "$returned_id" = "$session_id" ] && return 0 || return 1
}

# Code Execution Tests
test_execute_code_simple() {
    local session_id=$(cat "$TEST_RESULTS_DIR/session_id.txt" 2>/dev/null || echo "")
    
    if [ -z "$session_id" ]; then
        test_create_session || return 1
        session_id=$(cat "$TEST_RESULTS_DIR/session_id.txt")
    fi
    
    local payload='{"code": "x = 5; y = x * 2;"}'
    local response=$(http_post "/api/v1/sessions/$session_id/execute" "$payload")
    local success=$(echo "$response" | jq '.success // false')
    
    [ "$success" = "true" ] && return 0 || return 1
}

test_execute_code_with_output() {
    local session_id=$(cat "$TEST_RESULTS_DIR/session_id.txt" 2>/dev/null)
    [ -z "$session_id" ] && return 1
    
    local payload='{"code": "disp(\"Hello World\");"}'
    local response=$(http_post "/api/v1/sessions/$session_id/execute" "$payload")
    local stdout=$(echo "$response" | jq -r '.stdout // ""')
    
    [[ "$stdout" == *"Hello"* ]] && return 0 || return 1
}

test_execute_code_with_variables() {
    local session_id=$(cat "$TEST_RESULTS_DIR/session_id.txt" 2>/dev/null)
    [ -z "$session_id" ] && return 1
    
    local payload='{"code": "A = [1 2 3; 4 5 6]; B = A + 1;"}'
    local response=$(http_post "/api/v1/sessions/$session_id/execute" "$payload")
    local vars=$(echo "$response" | jq '.variables_snapshot // {}')
    local has_vars=$(echo "$vars" | jq 'length > 0')
    
    [ "$has_vars" = "true" ] && return 0 || return 1
}

# Workspace Tests
test_get_workspace() {
    local session_id=$(cat "$TEST_RESULTS_DIR/session_id.txt" 2>/dev/null)
    [ -z "$session_id" ] && return 1
    
    local response=$(http_get "/api/v1/sessions/$session_id/workspace")
    local total=$(echo "$response" | jq '.total_size_bytes // -1')
    
    [ "$total" -ge 0 ] && return 0 || return 1
}

test_set_variable() {
    local session_id=$(cat "$TEST_RESULTS_DIR/session_id.txt" 2>/dev/null)
    [ -z "$session_id" ] && return 1
    
    local payload='{"value": 42}'
    local response=$(http_post "/api/v1/sessions/$session_id/vars/test_var" "$payload")
    local status=$(echo "$response" | jq -r '.status // ""')
    
    [ "$status" = "success" ] && return 0 || return 1
}

test_get_variable() {
    local session_id=$(cat "$TEST_RESULTS_DIR/session_id.txt" 2>/dev/null)
    [ -z "$session_id" ] && return 1
    
    local response=$(http_get "/api/v1/sessions/$session_id/vars/test_var")
    local name=$(echo "$response" | jq -r '.name // ""')
    
    [ "$name" = "test_var" ] && return 0 || return 1
}

test_clear_workspace() {
    local session_id=$(cat "$TEST_RESULTS_DIR/session_id.txt" 2>/dev/null)
    [ -z "$session_id" ] && return 1
    
    local response=$(http_post "/api/v1/sessions/$session_id/clear" "{}")
    local status=$(echo "$response" | jq -r '.status // ""')
    
    [ "$status" = "success" ] && return 0 || return 1
}

# File Operations Tests
test_list_files() {
    local session_id=$(cat "$TEST_RESULTS_DIR/session_id.txt" 2>/dev/null)
    [ -z "$session_id" ] && return 1
    
    local response=$(http_get "/api/v1/sessions/$session_id/files")
    local total=$(echo "$response" | jq '.total // -1')
    
    [ "$total" -ge 0 ] && return 0 || return 1
}

test_create_file() {
    local session_id=$(cat "$TEST_RESULTS_DIR/session_id.txt" 2>/dev/null)
    [ -z "$session_id" ] && return 1
    
    local payload='{"filename": "test.m", "content": "x = 1; y = 2;", "overwrite": true}'
    local response=$(http_post "/api/v1/sessions/$session_id/files/create" "$payload")
    local status=$(echo "$response" | jq -r '.status // ""')
    
    [ "$status" = "success" ] && return 0 || return 1
}

test_run_script() {
    local session_id=$(cat "$TEST_RESULTS_DIR/session_id.txt" 2>/dev/null)
    [ -z "$session_id" ] && return 1
    
    # First create a test script
    local create_payload='{"filename": "test_script.m", "content": "result = 42;", "overwrite": true}'
    http_post "/api/v1/sessions/$session_id/files/create" "$create_payload" > /dev/null
    
    # Then run it
    local run_payload='{"filename": "test_script.m"}'
    local response=$(http_post "/api/v1/sessions/$session_id/scripts/run" "$run_payload")
    local status=$(echo "$response" | jq -r '.status // ""')
    
    [ "$status" = "success" ] && return 0 || return 1
}

# Metadata Tests
test_list_functions() {
    local response=$(http_get "/api/v1/functions")
    local total=$(echo "$response" | jq '.total // 0')
    
    [ "$total" -gt 0 ] && return 0 || return 1
}

test_get_function() {
    local response=$(http_get "/api/v1/functions/sin")
    local name=$(echo "$response" | jq -r '.name // ""')
    
    [ "$name" = "sin" ] && return 0 || return 1
}

test_list_libraries() {
    local response=$(http_get "/api/v1/libraries")
    local total=$(echo "$response" | jq '.total // 0')
    
    [ "$total" -gt 0 ] && return 0 || return 1
}

test_get_library() {
    local response=$(http_get "/api/v1/libraries/math")
    local name=$(echo "$response" | jq -r '.name // ""')
    
    [ "$name" = "math" ] && return 0 || return 1
}

# System Tests
test_health_check() {
    local response=$(http_get "/api/v1/health")
    local status=$(echo "$response" | jq -r '.status // ""')
    
    [[ "$status" == *"healthy"* ]] && return 0 || return 1
}

test_get_metrics() {
    local response=$(http_get "/api/v1/metrics")
    local sessions=$(echo "$response" | jq '.active_sessions // -1')
    
    [ "$sessions" -ge 0 ] && return 0 || return 1
}

test_get_settings() {
    local response=$(http_get "/api/v1/settings")
    local max_sessions=$(echo "$response" | jq '.max_sessions // 0')
    
    [ "$max_sessions" -gt 0 ] && return 0 || return 1
}

test_get_version() {
    local response=$(http_get "/api/v1/version")
    local version=$(echo "$response" | jq -r '.version // ""')
    
    [ -n "$version" ] && return 0 || return 1
}

##############################################################################
# Main Test Execution
##############################################################################

main() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         UniLab API Test Suite - Main Runner               ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  API Base URL: $API_BASE_URL"
    echo "  Test User: $TEST_USER"
    echo ""
    
    # Check if API is running
    if ! http_get "/" > /dev/null 2>&1; then
        echo -e "${RED}Error: API is not running at $API_BASE_URL${NC}"
        echo "Start the API with: cd backend && python -m uvicorn api.main:app --reload"
        exit 1
    fi
    
    echo -e "${YELLOW}Running Tests...${NC}\n"
    
    # Run all test suites
    echo -e "${BLUE}Session Management:${NC}"
    run_test "create_session" test_create_session
    run_test "list_sessions" test_list_sessions
    run_test "get_session" test_get_session
    
    echo -e "${BLUE}Code Execution:${NC}"
    run_test "execute_code_simple" test_execute_code_simple
    run_test "execute_code_with_output" test_execute_code_with_output
    run_test "execute_code_with_variables" test_execute_code_with_variables
    
    echo -e "${BLUE}Workspace Management:${NC}"
    run_test "get_workspace" test_get_workspace
    run_test "set_variable" test_set_variable
    run_test "get_variable" test_get_variable
    run_test "clear_workspace" test_clear_workspace
    
    echo -e "${BLUE}File Operations:${NC}"
    run_test "list_files" test_list_files
    run_test "create_file" test_create_file
    run_test "run_script" test_run_script
    
    echo -e "${BLUE}Metadata:${NC}"
    run_test "list_functions" test_list_functions
    run_test "get_function" test_get_function
    run_test "list_libraries" test_list_libraries
    run_test "get_library" test_get_library
    
    echo -e "${BLUE}System:${NC}"
    run_test "health_check" test_health_check
    run_test "get_metrics" test_get_metrics
    run_test "get_settings" test_get_settings
    run_test "get_version" test_get_version
    
    # Print results
    echo -e "\n${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                      Test Results                          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${YELLOW}Summary:${NC}"
    echo "  Total Tests:  $TOTAL_TESTS"
    echo "  Passed:       ${GREEN}$PASSED_TESTS${NC}"
    echo "  Failed:       ${RED}$FAILED_TESTS${NC}"
    echo "  Skipped:      $SKIPPED_TESTS"
    echo ""
    
    if [ $FAILED_TESTS -gt 0 ]; then
        echo -e "${RED}Failed Tests:${NC}"
        for test in "${FAILED_TEST_DETAILS[@]}"; do
            echo "  - $test"
        done
        echo ""
    fi
    
    # Write summary to file
    {
        echo "Test Results Summary"
        echo "===================="
        echo "Timestamp: $(date)"
        echo "Total: $TOTAL_TESTS"
        echo "Passed: $PASSED_TESTS"
        echo "Failed: $FAILED_TESTS"
        echo "Skipped: $SKIPPED_TESTS"
        echo ""
        echo "Details:"
        for result in "${TEST_RESULTS[@]}"; do
            echo "  $result"
        done
    } > "$TEST_RESULTS_DIR/summary.txt"
    
    # Return appropriate exit code
    [ $FAILED_TESTS -eq 0 ] && return 0 || return 1
}

# Run main function
main
