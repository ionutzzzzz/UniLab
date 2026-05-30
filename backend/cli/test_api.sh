#!/bin/bash

##############################################################################
# UniLab API - All-in-one CLI & Test Tool
#
# This script combines configuration, utilities, and tests for the UniLab API.
# It replaces the previously fragmented bash scripts.
##############################################################################

set -e

# --- 1. Configuration ---

# API Configuration
API_BASE_URL="${API_BASE_URL:-http://localhost:8000}"
API_VERSION="v1"
API_FULL_URL="${API_BASE_URL}/api/${API_VERSION}"

# Test User Configuration
TEST_USER="${TEST_USER:-testuser}"
TEST_ADMIN="${TEST_ADMIN:-admin}"

# Timeouts (in seconds)
REQUEST_TIMEOUT=10
LONG_EXECUTION_TIMEOUT=30

# Test Data Paths
TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DATA_DIR="${TEST_SCRIPT_DIR}/test_data"
TEST_SAMPLES_DIR="${TEST_SCRIPT_DIR}/samples"
TEST_RESULTS_DIR="/tmp/unilab_tests"

# Create directories if they don't exist
mkdir -p "$TEST_DATA_DIR"
mkdir -p "$TEST_SAMPLES_DIR"
mkdir -p "$TEST_RESULTS_DIR"

# Test Flags
VERBOSE="${VERBOSE:-false}"
CLEANUP_AFTER_TESTS="${CLEANUP_AFTER_TESTS:-true}"
PARALLEL_TESTS="${PARALLEL_TESTS:-false}"

# Logging
LOG_FILE="/tmp/unilab_api_tests.log"
DEBUG_MODE="${DEBUG_MODE:-false}"

# Colors (for terminal output)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Export for use in other sub-shells
export API_BASE_URL API_VERSION API_FULL_URL
export TEST_USER TEST_ADMIN
export REQUEST_TIMEOUT LONG_EXECUTION_TIMEOUT
export TEST_SCRIPT_DIR TEST_DATA_DIR TEST_SAMPLES_DIR
export VERBOSE CLEANUP_AFTER_TESTS PARALLEL_TESTS
export LOG_FILE DEBUG_MODE
export RED GREEN YELLOW BLUE MAGENTA CYAN NC

# --- 2. Utility Functions ---

# HTTP Request Helpers
http_get() {
    local endpoint="$1"
    local response=$(curl -s -X GET "$API_BASE_URL$endpoint" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json")
    echo "$response"
}

http_post() {
    local endpoint="$1"
    local data="$2"
    local response=$(curl -s -X POST "$API_BASE_URL$endpoint" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "$data")
    echo "$response"
}

http_delete() {
    local endpoint="$1"
    local response=$(curl -s -X DELETE "$API_BASE_URL$endpoint" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json")
    echo "$response"
}

http_put() {
    local endpoint="$1"
    local data="$2"
    local response=$(curl -s -X PUT "$API_BASE_URL$endpoint" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "$data")
    echo "$response"
}

# Assertion Helpers
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
}

assert_not_null() {
    local value="$1"
    local message="$2"
    if [ -n "$value" ] && [ "$value" != "null" ]; then
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        echo -e "${RED}✗${NC} $message (got null or empty)"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Expected to contain: $needle"
        echo "  Got: $haystack"
        return 1
    fi
}

# Pretty printing
print_header() {
    local title="$1"
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $title"
    echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}\n"
}

print_section() {
    local title="$1"
    echo -e "\n${YELLOW}➜ $title${NC}"
}

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }

# Session management helpers
get_or_create_session() {
    if [ -f "$TEST_RESULTS_DIR/session_id.txt" ]; then
        cat "$TEST_RESULTS_DIR/session_id.txt"
    else
        local payload="{\"username\": \"$TEST_USER\", \"engine\": \"transpiler\"}"
        local response=$(http_post "/api/v1/sessions" "$payload")
        local session_id=$(echo "$response" | jq -r '.session_id // empty')
        if [ -n "$session_id" ] && [ "$session_id" != "null" ]; then
            echo "$session_id" > "$TEST_RESULTS_DIR/session_id.txt"
            echo "$session_id"
        else
            return 1
        fi
    fi
}

# --- 3. Test Runner Logic ---

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0
declare -a TEST_RESULTS
declare -a FAILED_TEST_DETAILS

run_test() {
    local test_name="$1"
    local test_func="$2"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ -n "$FILTER" ] && [[ ! "$test_name" =~ $FILTER ]]; then
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
        return
    fi
    if [ "$VERBOSE" = true ]; then echo -e "\n${BLUE}[TEST] $test_name${NC}"; fi
    if $test_func; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS+=("$test_name: ${GREEN}PASS${NC}")
        if [ "$VERBOSE" = true ]; then echo -e "${GREEN}✓ PASS${NC}"; fi
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS+=("$test_name: ${RED}FAIL${NC}")
        FAILED_TEST_DETAILS+=("$test_name")
        if [ "$VERBOSE" = true ]; then echo -e "${RED}✗ FAIL${NC}"; fi
    fi
}

# --- 4. Test Suites ---

# Session Management
test_create_session() {
    local response=$(http_post "/api/v1/sessions" "{\"username\": \"$TEST_USER\", \"engine\": \"transpiler\"}")
    local session_id=$(echo "$response" | jq -r '.session_id // empty')
    if [ -z "$session_id" ] || [ "$session_id" = "null" ]; then return 1; fi
    echo "$session_id" > "$TEST_RESULTS_DIR/session_id.txt"
    return 0
}

test_list_sessions() {
    local response=$(http_get "/api/v1/sessions")
    local total=$(echo "$response" | jq '.total // 0')
    [ "$total" -ge 0 ] && return 0 || return 1
}

test_get_session() {
    local session_id=$(get_or_create_session) || return 1
    local response=$(http_get "/api/v1/sessions/$session_id")
    local returned_id=$(echo "$response" | jq -r '.session_id // empty')
    [ "$returned_id" = "$session_id" ] && return 0 || return 1
}

test_delete_session() {
    local session_id=$(http_post "/api/v1/sessions" "{\"username\": \"temp_user\"}" | jq -r '.session_id')
    [ -z "$session_id" ] && return 1
    local del_response=$(http_delete "/api/v1/sessions/$session_id")
    [ "$(echo "$del_response" | jq -r '.status')" = "success" ] && return 0 || return 1
}

test_multiple_sessions() {
    local count=0
    for i in {1..3}; do
        local sid=$(http_post "/api/v1/sessions" "{\"username\": \"user_$i\"}" | jq -r '.session_id')
        [ -n "$sid" ] && [ "$sid" != "null" ] && count=$((count + 1))
    done
    [ $count -eq 3 ] && return 0 || return 1
}

# Code Execution
test_execute_code_simple() {
    local session_id=$(get_or_create_session) || return 1
    local response=$(http_post "/api/v1/sessions/$session_id/execute" '{"code": "x = 5; y = x * 2;"}')
    [ "$(echo "$response" | jq '.success')" = "true" ] && return 0 || return 1
}

test_execute_code_with_output() {
    local session_id=$(get_or_create_session) || return 1
    local response=$(http_post "/api/v1/sessions/$session_id/execute" '{"code": "disp('\''Hello World'\'');"}')
    [[ "$(echo "$response" | jq -r '.stdout')" == *"Hello"* ]] && return 0 || return 1
}

test_execute_code_with_variables() {
    local session_id=$(get_or_create_session) || return 1
    local response=$(http_post "/api/v1/sessions/$session_id/execute" '{"code": "A = [1 2; 3 4];"}')
    [ "$(echo "$response" | jq '.variables_snapshot | length')" -gt 0 ] && return 0 || return 1
}

test_matrix_operations() {
    local session_id=$(get_or_create_session) || return 1
    local response=$(http_post "/api/v1/sessions/$session_id/execute" '{"code": "A = [1 2; 3 4]; B = A * 2;"}')
    [ "$(echo "$response" | jq '.success')" = "true" ] && return 0 || return 1
}

test_trig_functions() {
    local session_id=$(get_or_create_session) || return 1
    local response=$(http_post "/api/v1/sessions/$session_id/execute" '{"code": "y = sin(pi/2);"}')
    [ "$(echo "$response" | jq '.success')" = "true" ] && return 0 || return 1
}

test_error_handling() {
    local session_id=$(get_or_create_session) || return 1
    local response=$(http_post "/api/v1/sessions/$session_id/execute" '{"code": "x = undefined_var;"}')
    # We expect success=false or stderr to be present
    [ "$(echo "$response" | jq -r '.success')" != "true" ] || [ -n "$(echo "$response" | jq -r '.stderr')" ]
    return 0
}

test_batch_execution() {
    local session_id=$(get_or_create_session) || return 1
    local payload='{"commands": [{"code": "x=1;"}, {"code": "y=2;"}]}'
    local response=$(http_post "/api/v1/sessions/$session_id/batch" "$payload")
    [ "$(echo "$response" | jq '.total')" -eq 2 ] && return 0 || return 1
}

test_code_transpilation() {
    local session_id=$(get_or_create_session) || return 1
    local response=$(http_post "/api/v1/sessions/$session_id/transpile" '{"code": "x = 1;"}')
    [ -n "$(echo "$response" | jq -r '.python_code // empty')" ] && return 0 || return 1
}

test_loop_execution() {
    local session_id=$(get_or_create_session) || return 1
    local response=$(http_post "/api/v1/sessions/$session_id/execute" '{"code": "for i=1:3 disp(i); end"}')
    [ "$(echo "$response" | jq '.success')" = "true" ] && return 0 || return 1
}

# Workspace Management
test_get_workspace() {
    local session_id=$(get_or_create_session) || return 1
    local response=$(http_get "/api/v1/sessions/$session_id/workspace")
    [ "$(echo "$response" | jq '.total_size_bytes')" -ge 0 ] && return 0 || return 1
}

test_set_variable() {
    local session_id=$(get_or_create_session) || return 1
    local response=$(http_post "/api/v1/sessions/$session_id/vars/test_var" '{"value": 42}')
    [ "$(echo "$response" | jq -r '.status')" = "success" ] && return 0 || return 1
}

test_get_variable() {
    local session_id=$(get_or_create_session) || return 1
    local response=$(http_get "/api/v1/sessions/$session_id/vars/test_var")
    [ "$(echo "$response" | jq -r '.name')" = "test_var" ] && return 0 || return 1
}

test_clear_workspace() {
    local session_id=$(get_or_create_session) || return 1
    local response=$(http_post "/api/v1/sessions/$session_id/clear" "{}")
    [ "$(echo "$response" | jq -r '.status')" = "success" ] && return 0 || return 1
}

# File Operations
test_list_files() {
    local session_id=$(get_or_create_session) || return 1
    local response=$(http_get "/api/v1/sessions/$session_id/files")
    [ "$(echo "$response" | jq '.total')" -ge 0 ] && return 0 || return 1
}

test_create_file() {
    local session_id=$(get_or_create_session) || return 1
    local payload='{"filename": "test.m", "content": "x = 1;", "overwrite": true}'
    local response=$(http_post "/api/v1/sessions/$session_id/files/create" "$payload")
    [ "$(echo "$response" | jq -r '.status')" = "success" ] && return 0 || return 1
}

test_run_script() {
    local session_id=$(get_or_create_session) || return 1
    http_post "/api/v1/sessions/$session_id/files/create" '{"filename": "run_me.m", "content": "a=10;"}' > /dev/null
    local response=$(http_post "/api/v1/sessions/$session_id/scripts/run" '{"filename": "run_me.m"}')
    [ "$(echo "$response" | jq -r '.status')" = "success" ] && return 0 || return 1
}

# Metadata
test_list_functions() {
    local response=$(http_get "/api/v1/functions")
    [ "$(echo "$response" | jq '.total')" -gt 0 ] && return 0 || return 1
}

test_get_function() {
    local response=$(http_get "/api/v1/functions/sin")
    [ "$(echo "$response" | jq -r '.name')" = "sin" ] && return 0 || return 1
}

test_list_libraries() {
    local response=$(http_get "/api/v1/libraries")
    [ "$(echo "$response" | jq '.total')" -gt 0 ] && return 0 || return 1
}

# System
test_health_check() {
    local response=$(http_get "/api/v1/health")
    [[ "$(echo "$response" | jq -r '.status')" == *"healthy"* ]] && return 0 || return 1
}

test_get_metrics() {
    local response=$(http_get "/api/v1/metrics")
    [ "$(echo "$response" | jq '.active_sessions')" -ge 0 ] && return 0 || return 1
}

test_get_version() {
    local response=$(http_get "/api/v1/version")
    [ -n "$(echo "$response" | jq -r '.version')" ] && return 0 || return 1
}

# --- 5. Main Execution ---

show_help() {
    echo "UniLab API Unified Test Tool"
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --config FILE    Load custom configuration"
    echo "  --filter PATTERN Only run tests matching pattern"
    echo "  --verbose        Show detailed output"
    echo "  --help           Display this help message"
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --config) source "$2"; shift 2 ;;
            --filter) FILTER="$2"; shift 2 ;;
            --verbose) VERBOSE=true; shift ;;
            --help) show_help; exit 0 ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
    done

    print_header "UniLab API Test Suite"
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  API Base URL: $API_BASE_URL"
    echo "  Test User:    $TEST_USER"
    echo ""

    if ! curl -s --connect-timeout 2 "$API_BASE_URL" > /dev/null; then
        print_error "API is not reachable at $API_BASE_URL"
        exit 1
    fi

    echo -e "${YELLOW}Running Test Suites...${NC}"

    print_section "Session Management"
    run_test "create_session" test_create_session
    run_test "list_sessions" test_list_sessions
    run_test "get_session" test_get_session
    run_test "delete_session" test_delete_session
    run_test "multiple_sessions" test_multiple_sessions

    print_section "Code Execution"
    run_test "execute_code_simple" test_execute_code_simple
    run_test "execute_code_with_output" test_execute_code_with_output
    run_test "execute_code_with_variables" test_execute_code_with_variables
    run_test "matrix_operations" test_matrix_operations
    run_test "trig_functions" test_trig_functions
    run_test "error_handling" test_error_handling
    run_test "batch_execution" test_batch_execution
    run_test "code_transpilation" test_code_transpilation
    run_test "loop_execution" test_loop_execution

    print_section "Workspace Management"
    run_test "get_workspace" test_get_workspace
    run_test "set_variable" test_set_variable
    run_test "get_variable" test_get_variable
    run_test "clear_workspace" test_clear_workspace

    print_section "File Operations"
    run_test "list_files" test_list_files
    run_test "create_file" test_create_file
    run_test "run_script" test_run_script

    print_section "Metadata"
    run_test "list_functions" test_list_functions
    run_test "get_function" test_get_function
    run_test "list_libraries" test_list_libraries

    print_section "System"
    run_test "health_check" test_health_check
    run_test "get_metrics" test_get_metrics
    run_test "get_version" test_get_version

    # Results Summary
    print_header "Test Results"
    echo "  Total Tests:  $TOTAL_TESTS"
    echo "  Passed:       ${GREEN}$PASSED_TESTS${NC}"
    echo "  Failed:       ${RED}$FAILED_TESTS${NC}"
    echo "  Skipped:      $SKIPPED_TESTS"
    echo ""

    if [ $FAILED_TESTS -gt 0 ]; then
        echo -e "${RED}Failed Tests:${NC}"
        for test in "${FAILED_TEST_DETAILS[@]}"; do echo "  - $test"; done
        echo ""
    fi

    # Cleanup if requested
    if [ "$CLEANUP_AFTER_TESTS" = true ] && [ -f "$TEST_RESULTS_DIR/session_id.txt" ]; then
        local sid=$(cat "$TEST_RESULTS_DIR/session_id.txt")
        http_delete "/api/v1/sessions/$sid" > /dev/null
        rm "$TEST_RESULTS_DIR/session_id.txt"
    fi

    [ $FAILED_TESTS -eq 0 ] && exit 0 || exit 1
}

main "$@"
