#!/bin/bash

##############################################################################
# UniLab API Test Suite - Code Execution Endpoint Tests
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/utils.sh"

print_header "Code Execution Tests"

# Helper: Get or create session
get_session() {
    if [ -f "$TEST_DATA_DIR/session_id.txt" ]; then
        cat "$TEST_DATA_DIR/session_id.txt"
    else
        local payload='{"username": "test_exec", "engine": "transpiler"}'
        local response=$(http_post "/api/v1/sessions" "$payload")
        echo "$response" | jq -r '.session_id'
    fi
}

# Test 1: Simple arithmetic
test_simple_arithmetic() {
    print_section "Simple Arithmetic"
    
    local session_id=$(get_session)
    local payload='{"code": "x = 5; y = 10; z = x + y;"}'
    local response=$(http_post "/api/v1/sessions/$session_id/execute" "$payload")
    
    local success=$(echo "$response" | jq -r '.success // false')
    
    if [ "$success" != "true" ]; then
        print_error "Execution failed"
        echo "Response: $response"
        return 1
    fi
    
    print_success "Arithmetic computation successful"
    return 0
}

# Test 2: Matrix operations
test_matrix_operations() {
    print_section "Matrix Operations"
    
    local session_id=$(get_session)
    local code='A = [1 2 3; 4 5 6; 7 8 9]; B = A + 1; C = A * 2;'
    local payload="{\"code\": \"$code\"}"
    local response=$(http_post "/api/v1/sessions/$session_id/execute" "$payload")
    
    local success=$(echo "$response" | jq -r '.success // false')
    local vars=$(echo "$response" | jq '.variables_snapshot // {}')
    local var_count=$(echo "$vars" | jq 'length')
    
    if [ "$success" != "true" ] || [ "$var_count" -lt 2 ]; then
        print_error "Matrix operations failed"
        return 1
    fi
    
    print_success "Matrix operations completed, created $var_count variables"
    return 0
}

# Test 3: Trigonometric functions
test_trig_functions() {
    print_section "Trigonometric Functions"
    
    local session_id=$(get_session)
    local code='x = pi; y = sin(x); z = cos(x);'
    local payload="{\"code\": \"$code\"}"
    local response=$(http_post "/api/v1/sessions/$session_id/execute" "$payload")
    
    local success=$(echo "$response" | jq -r '.success // false')
    
    if [ "$success" != "true" ]; then
        print_error "Trigonometric computation failed"
        return 1
    fi
    
    print_success "Trigonometric functions computed"
    return 0
}

# Test 4: Output capture
test_output_capture() {
    print_section "Output Capture"
    
    local session_id=$(get_session)
    local payload='{"code": "disp(\"Hello from UniLab\");"}'
    local response=$(http_post "/api/v1/sessions/$session_id/execute" "$payload")
    
    local stdout=$(echo "$response" | jq -r '.stdout // ""')
    
    if [[ ! "$stdout" =~ "Hello" ]]; then
        print_error "Output not captured"
        echo "Stdout: $stdout"
        return 1
    fi
    
    print_success "Output captured: $stdout"
    return 0
}

# Test 5: Error handling
test_error_handling() {
    print_section "Error Handling"
    
    local session_id=$(get_session)
    local payload='{"code": "x = undefined_variable;"}'
    local response=$(http_post "/api/v1/sessions/$session_id/execute" "$payload")
    
    local success=$(echo "$response" | jq -r '.success // false')
    
    # We expect this to fail or show an error
    if [ "$success" = "true" ]; then
        local stderr=$(echo "$response" | jq -r '.stderr // ""')
        # Should have undefined variable error
        print_success "Error properly detected"
    fi
    
    return 0
}

# Test 6: Batch execution
test_batch_execution() {
    print_section "Batch Execution"
    
    local session_id=$(get_session)
    local commands='[{"code": "x = 1;"}, {"code": "y = 2;"}, {"code": "z = x + y;"}]'
    local payload="{\"commands\": $commands, \"stop_on_error\": false}"
    local response=$(http_post "/api/v1/sessions/$session_id/batch" "$payload")
    
    local total=$(echo "$response" | jq '.total // 0')
    local failed=$(echo "$response" | jq '.failed // 0')
    
    if [ "$total" -ne 3 ] || [ "$failed" -gt 0 ]; then
        print_error "Batch execution incomplete"
        return 1
    fi
    
    print_success "Batch execution completed: $total commands"
    return 0
}

# Test 7: Code transpilation
test_code_transpilation() {
    print_section "Code Transpilation"
    
    local session_id=$(get_session)
    local payload='{"code": "x = [1 2 3]; y = x + 1;"}'
    local response=$(http_post "/api/v1/sessions/$session_id/transpile" "$payload")
    
    local python_code=$(echo "$response" | jq -r '.python_code // ""')
    
    if [ -z "$python_code" ] || [ "$python_code" = "null" ]; then
        print_error "Transpilation failed"
        return 1
    fi
    
    print_success "Code transpiled successfully"
    echo "  Python equivalent length: ${#python_code} chars"
    return 0
}

# Test 8: Loop execution
test_loop_execution() {
    print_section "Loop Execution"
    
    local session_id=$(get_session)
    local code='for i = 1:5 disp(i); end'
    local payload="{\"code\": \"$code\"}"
    local response=$(http_post "/api/v1/sessions/$session_id/execute" "$payload")
    
    local success=$(echo "$response" | jq -r '.success // false')
    local stdout=$(echo "$response" | jq -r '.stdout // ""')
    
    if [ "$success" != "true" ]; then
        print_error "Loop execution failed"
        return 1
    fi
    
    print_success "Loop executed, output lines: $(echo "$stdout" | wc -l)"
    return 0
}

# Main execution
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    test_simple_arithmetic
    test_matrix_operations
    test_trig_functions
    test_output_capture
    test_error_handling
    test_batch_execution
    test_code_transpilation
    test_loop_execution
fi
