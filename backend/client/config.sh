#!/bin/bash

##############################################################################
# UniLab API Test Suite - Configuration
##############################################################################

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

# Create directories if they don't exist
mkdir -p "$TEST_DATA_DIR"
mkdir -p "$TEST_SAMPLES_DIR"

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

# Export for use in other scripts
export API_BASE_URL API_VERSION API_FULL_URL
export TEST_USER TEST_ADMIN
export REQUEST_TIMEOUT LONG_EXECUTION_TIMEOUT
export TEST_SCRIPT_DIR TEST_DATA_DIR TEST_SAMPLES_DIR
export VERBOSE CLEANUP_AFTER_TESTS PARALLEL_TESTS
export LOG_FILE DEBUG_MODE
export RED GREEN YELLOW BLUE MAGENTA CYAN NC
