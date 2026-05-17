#!/bin/bash

##############################################################################
# UniLab API Test Suite - Session Management Endpoint Tests
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/utils.sh"

print_header "Session Management Tests"

# Test 1: Create a new session
test_create_session() {
    print_section "Create Session"
    
    local payload='{"username": "test_user", "engine": "transpiler"}'
    local response=$(http_post "/api/v1/sessions" "$payload")
    
    local session_id=$(echo "$response" | jq -r '.session_id // empty')
    
    if [ -z "$session_id" ] || [ "$session_id" = "null" ]; then
        print_error "Failed to create session"
        echo "Response: $response"
        return 1
    fi
    
    print_success "Session created: $session_id"
    echo "$session_id" > "$TEST_DATA_DIR/session_id.txt"
    return 0
}

# Test 2: List all sessions
test_list_sessions() {
    print_section "List Sessions"
    
    local response=$(http_get "/api/v1/sessions")
    local total=$(echo "$response" | jq '.total // 0')
    
    if [ -z "$total" ] || [ "$total" -lt 0 ]; then
        print_error "Failed to list sessions"
        return 1
    fi
    
    print_success "Found $total session(s)"
    return 0
}

# Test 3: Get specific session details
test_get_session_details() {
    print_section "Get Session Details"
    
    if [ ! -f "$TEST_DATA_DIR/session_id.txt" ]; then
        print_error "No session ID found"
        return 1
    fi
    
    local session_id=$(cat "$TEST_DATA_DIR/session_id.txt")
    local response=$(http_get "/api/v1/sessions/$session_id")
    
    local returned_id=$(echo "$response" | jq -r '.session_id // empty')
    
    if [ "$returned_id" != "$session_id" ]; then
        print_error "Session ID mismatch"
        return 1
    fi
    
    print_success "Retrieved session $session_id"
    return 0
}

# Test 4: Delete session
test_delete_session() {
    print_section "Delete Session"
    
    # Create a temporary session to delete
    local payload='{"username": "temp_user", "engine": "transpiler"}'
    local response=$(http_post "/api/v1/sessions" "$payload")
    local session_id=$(echo "$response" | jq -r '.session_id // empty')
    
    if [ -z "$session_id" ]; then
        print_error "Failed to create temporary session"
        return 1
    fi
    
    # Delete it
    local del_response=$(http_delete "/api/v1/sessions/$session_id")
    local status=$(echo "$del_response" | jq -r '.status // empty')
    
    if [ "$status" != "success" ]; then
        print_error "Failed to delete session"
        return 1
    fi
    
    print_success "Session deleted: $session_id"
    return 0
}

# Test 5: Create multiple sessions concurrently
test_multiple_sessions() {
    print_section "Multiple Sessions"
    
    local sessions_created=0
    
    for i in {1..3}; do
        local payload="{\"username\": \"user_$i\", \"engine\": \"transpiler\"}"
        local response=$(http_post "/api/v1/sessions" "$payload")
        local session_id=$(echo "$response" | jq -r '.session_id // empty')
        
        if [ -n "$session_id" ] && [ "$session_id" != "null" ]; then
            sessions_created=$((sessions_created + 1))
            echo "  Session $i: $session_id"
        fi
    done
    
    if [ $sessions_created -eq 3 ]; then
        print_success "Created $sessions_created sessions"
        return 0
    else
        print_error "Only created $sessions_created out of 3 sessions"
        return 1
    fi
}

# Main execution
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    test_create_session
    test_list_sessions
    test_get_session_details
    test_delete_session
    test_multiple_sessions
fi
