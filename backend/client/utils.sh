#!/bin/bash

##############################################################################
# UniLab API Test Suite - Utility Functions
##############################################################################

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

assert_http_status() {
    local expected_status="$1"
    local endpoint="$2"
    local message="$3"
    
    local status=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE_URL$endpoint")
    
    if [ "$status" = "$expected_status" ]; then
        echo -e "${GREEN}✓${NC} $message (HTTP $status)"
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Expected HTTP: $expected_status"
        echo "  Got HTTP: $status"
        return 1
    fi
}

# JSON parsing helpers
json_get() {
    local json="$1"
    local key="$2"
    echo "$json" | jq -r "$key" 2>/dev/null || echo ""
}

json_get_value() {
    local json="$1"
    local path="$2"
    echo "$json" | jq ".${path}" 2>/dev/null
}

# Data generation helpers
generate_random_string() {
    local length=${1:-10}
    openssl rand -hex $((length / 2)) | cut -c1-$length
}

generate_test_code() {
    local type="${1:-simple}"
    
    case $type in
        simple)
            echo "x = 1; y = 2; z = x + y;"
            ;;
        matrix)
            echo "A = [1 2 3; 4 5 6]; B = A * 2;"
            ;;
        function)
            echo "function result = test_func(x) result = x * 2; end"
            ;;
        loop)
            echo "for i = 1:10 disp(i); end"
            ;;
        conditional)
            echo "if 5 > 3 disp('yes'); else disp('no'); end"
            ;;
        *)
            echo "x = 42;"
            ;;
    esac
}

# Session management helpers
create_test_session() {
    local username="${1:-testuser}"
    local engine="${2:-transpiler}"
    
    local payload="{\"username\": \"$username\", \"engine\": \"$engine\"}"
    local response=$(http_post "/api/v1/sessions" "$payload")
    
    echo "$response" | jq -r '.session_id // empty'
}

cleanup_session() {
    local session_id="$1"
    
    if [ -z "$session_id" ]; then
        return 1
    fi
    
    http_delete "/api/v1/sessions/$session_id" > /dev/null
    return 0
}

# Performance testing
measure_time() {
    local name="$1"
    shift
    
    local start=$(date +%s%N)
    "$@" > /dev/null 2>&1
    local end=$(date +%s%N)
    
    local duration=$(( (end - start) / 1000000 ))
    echo "${name}: ${duration}ms"
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

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Validation helpers
validate_json_response() {
    local json="$1"
    
    if echo "$json" | jq . >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

validate_session_response() {
    local response="$1"
    
    local session_id=$(echo "$response" | jq -r '.session_id // empty')
    [ -n "$session_id" ] && [ "$session_id" != "null" ]
}

validate_execution_response() {
    local response="$1"
    
    local success=$(echo "$response" | jq -r '.success // empty')
    [ "$success" != "" ]
}

# Retry helpers
retry_request() {
    local max_attempts=3
    local attempt=1
    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-}"
    
    while [ $attempt -le $max_attempts ]; do
        if [ "$method" = "GET" ]; then
            local response=$(http_get "$endpoint")
        else
            local response=$(http_post "$endpoint" "$data")
        fi
        
        if validate_json_response "$response"; then
            echo "$response"
            return 0
        fi
        
        attempt=$((attempt + 1))
        sleep 0.5
    done
    
    return 1
}

# Export functions for use in other scripts
export -f http_get http_post http_delete http_put
export -f assert_equals assert_not_null assert_contains assert_http_status
export -f json_get json_get_value
export -f generate_random_string generate_test_code
export -f create_test_session cleanup_session
export -f measure_time
export -f print_header print_section print_success print_error print_info
export -f validate_json_response validate_session_response validate_execution_response
export -f retry_request
