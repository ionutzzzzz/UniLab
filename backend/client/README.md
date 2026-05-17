# UniLab API - Complete Testing Guide

This directory contains comprehensive testing tools for the UniLab REST API.

## Overview

- **API Endpoints**: 25+ REST endpoints for scientific computing
- **Test Coverage**: Bash scripts, Python unit tests, and integration tests
- **Local Deployment**: Ready to use with local backend

## Quick Start

### 1. Start the API Server

```bash
cd /home/john/Documents/GitHub/Unilab/backend
python -m uvicorn api.main:app --reload --port 8000
```

The API will be available at `http://localhost:8000`

### 2. Run API Tests (Bash)

```bash
cd /home/john/Documents/GitHub/Unilab/backend/client

# Run all tests
./test_api.sh

# Run specific tests with verbose output
./test_api.sh --verbose

# Run specific test category
./test_api.sh --filter "test_execute"

# Run with custom configuration
./test_api.sh --config custom_config.sh
```

### 3. Run Unit Tests (Python)

```bash
cd /home/john/Documents/GitHub/Unilab/backend

# Install test dependencies (if needed)
pip install pytest pytest-asyncio

# Run all unit tests
pytest tests/unit/test_api_endpoints.py -v

# Run specific test class
pytest tests/unit/test_api_endpoints.py::TestSessionEndpoints -v

# Run with coverage report
pytest tests/unit/test_api_endpoints.py --cov=backend/api --cov-report=html
```

### 4. Run Integration Tests

```bash
cd /home/john/Documents/GitHub/Unilab/backend

# Run all integration tests
pytest tests/integration/test_workflows.py -v

# Run specific test class
pytest tests/integration/test_workflows.py::TestCompleteWorkflows -v
```

## Test Scripts Overview

### `test_api.sh` - Main Test Runner
**Comprehensive test orchestration for all API endpoints**

```bash
./test_api.sh [OPTIONS]

Options:
  --config FILE    Load custom configuration (default: config.sh)
  --filter PATTERN Only run tests matching pattern
  --verbose        Show detailed output
  --help          Display help message
```

Tests Covered:
- ✅ Session Management (4 tests)
- ✅ Code Execution (3 tests)
- ✅ Workspace Management (4 tests)
- ✅ File Operations (3 tests)
- ✅ Metadata (4 tests)
- ✅ System Monitoring (4 tests)

Output: HTML report with color-coded results

### `config.sh` - Configuration
**Centralized configuration for all tests**

```bash
# Key settings:
API_BASE_URL="http://localhost:8000"        # API server URL
TEST_USER="testuser"                        # Default test user
REQUEST_TIMEOUT=10                          # HTTP timeout
VERBOSE=false                               # Verbose output
CLEANUP_AFTER_TESTS=true                    # Auto cleanup
```

### `utils.sh` - Utility Functions
**Reusable helper functions for testing**

Available functions:
- `http_get()` - Make GET request
- `http_post()` - Make POST request
- `http_delete()` - Make DELETE request
- `assert_equals()` - Assert equality
- `assert_contains()` - Assert substring
- `print_section()` - Print test section header
- `create_test_session()` - Create temporary session
- `measure_time()` - Measure execution time

### `test_sessions.sh` - Session Endpoint Tests
**Comprehensive session management tests**

Tests:
- Create sessions
- List sessions
- Get session details
- Delete sessions
- Multiple concurrent sessions

Usage:
```bash
./test_sessions.sh
```

### `test_execution.sh` - Code Execution Tests
**Comprehensive code execution tests**

Tests:
- Simple arithmetic
- Matrix operations
- Trigonometric functions
- Output capture
- Error handling
- Batch execution
- Code transpilation
- Loop execution

Usage:
```bash
./test_execution.sh
```

## Python Unit Tests

### `tests/unit/test_api_endpoints.py`
**Low-level endpoint tests**

Test Classes:
- `TestSessionEndpoints` - Session CRUD
- `TestExecutionEndpoints` - Code execution
- `TestWorkspaceEndpoints` - Workspace management
- `TestFileEndpoints` - File operations
- `TestMetadataEndpoints` - Metadata queries
- `TestSystemEndpoints` - System monitoring
- `TestAPIRouting` - Routing configuration
- `TestErrorHandling` - Error scenarios

### `tests/integration/test_workflows.py`
**High-level workflow tests**

Test Classes:
- `TestCompleteWorkflows` - Full workflows
- `TestDataPersistence` - Data across requests
- `TestMetadataAccuracy` - Metadata correctness
- `TestPerformance` - Performance benchmarks

## API Endpoints Reference

### Session Management
```
POST   /api/v1/sessions              Create session
GET    /api/v1/sessions              List sessions
GET    /api/v1/sessions/{id}         Get session
DELETE /api/v1/sessions/{id}         Delete session
```

### Code Execution
```
POST   /api/v1/sessions/{id}/execute           Execute code
POST   /api/v1/sessions/{id}/execute-async     Async execution
POST   /api/v1/sessions/{id}/batch             Batch execution
POST   /api/v1/sessions/{id}/transpile         Transpile code
POST   /api/v1/sessions/{id}/debug             Debug execution
POST   /api/v1/sessions/{id}/profile           Profile code
```

### Workspace Management
```
GET    /api/v1/sessions/{id}/workspace         Get workspace
GET    /api/v1/sessions/{id}/vars/{name}       Get variable
POST   /api/v1/sessions/{id}/vars/{name}       Set variable
DELETE /api/v1/sessions/{id}/vars/{name}       Delete variable
POST   /api/v1/sessions/{id}/clear             Clear workspace
```

### File Operations
```
GET    /api/v1/sessions/{id}/files                  List files
GET    /api/v1/sessions/{id}/files/{path}          Get file
POST   /api/v1/sessions/{id}/files/create          Create file
POST   /api/v1/sessions/{id}/files/upload          Upload file
POST   /api/v1/sessions/{id}/files/delete          Delete file
POST   /api/v1/sessions/{id}/scripts/run           Run script
```

### Export & Visualization
```
POST   /api/v1/sessions/{id}/export              Export data
POST   /api/v1/sessions/{id}/plot                Generate plot
GET    /api/v1/sessions/{id}/plots               List plots
```

### Metadata
```
GET    /api/v1/functions                         List functions
GET    /api/v1/functions/{name}                  Get function
POST   /api/v1/functions/search                  Search functions
GET    /api/v1/libraries                         List libraries
GET    /api/v1/libraries/{name}                  Get library
```

### System
```
GET    /api/v1/health                            Health check
GET    /api/v1/metrics                           System metrics
GET    /api/v1/settings                          Settings
GET    /api/v1/version                           Version info
GET    /api/v1/system-info                       Complete info
```

## Example Workflows

### Example 1: Simple Computation
```bash
# Create session
SESSION=$(curl -s -X POST http://localhost:8000/api/v1/sessions \
  -H "Content-Type: application/json" \
  -d '{"username": "user1", "engine": "transpiler"}' | jq -r '.session_id')

# Execute code
curl -X POST http://localhost:8000/api/v1/sessions/$SESSION/execute \
  -H "Content-Type: application/json" \
  -d '{"code": "x = 5; y = 10; z = x + y;"}'

# Export results
curl -X POST http://localhost:8000/api/v1/sessions/$SESSION/export \
  -H "Content-Type: application/json" \
  -d '{"format": "json"}'
```

### Example 2: Script Execution
```bash
# Create session
SESSION=$(curl -s -X POST http://localhost:8000/api/v1/sessions \
  -H "Content-Type: application/json" \
  -d '{"username": "user2"}' | jq -r '.session_id')

# Upload script
curl -X POST http://localhost:8000/api/v1/sessions/$SESSION/files/create \
  -H "Content-Type: application/json" \
  -d '{
    "filename": "analysis.m",
    "content": "data = [1,2,3]; result = mean(data);"
  }'

# Run script
curl -X POST http://localhost:8000/api/v1/sessions/$SESSION/scripts/run \
  -H "Content-Type: application/json" \
  -d '{"filename": "analysis.m"}'
```

## Test Reports

Test results are saved to `/tmp/unilab_tests/`:

- `summary.txt` - Overall test summary
- Individual test logs - Detailed results

View summary:
```bash
cat /tmp/unilab_tests/summary.txt
```

## Troubleshooting

### API Not Running
```bash
# Check if API is up
curl http://localhost:8000/

# Start API if needed
cd /home/john/Documents/GitHub/Unilab/backend
python -m uvicorn api.main:app --reload
```

### Test Failures
```bash
# Run with verbose output
./test_api.sh --verbose

# Check API logs
# Look at the terminal where uvicorn is running
```

### Session Not Found
```bash
# Sessions are created per request
# Use the session_id from create response immediately
```

## Performance Tips

- Use `--parallel` for faster test execution (requires xargs)
- Filter tests to run only what you need: `--filter pattern`
- Sessions are lightweight - create multiple for concurrent testing

## Development

### Adding New Tests

**Bash test example:**
```bash
test_new_endpoint() {
    print_section "My New Test"
    
    local session_id=$(get_session)
    local response=$(http_get "/api/v1/sessions/$session_id/workspace")
    
    if [ "$(echo "$response" | jq '.total_size_bytes')" -ge 0 ]; then
        print_success "Workspace retrieved"
        return 0
    else
        print_error "Failed"
        return 1
    fi
}
```

**Python test example:**
```python
def test_new_endpoint(self):
    """Test description."""
    response = client.get("/api/v1/sessions")
    assert response.status_code == 200
```

### Running Coverage Analysis

```bash
# Unit test coverage
pytest tests/unit/ --cov=backend/api --cov-report=html
open htmlcov/index.html

# Integration test coverage
pytest tests/integration/ --cov=backend/core --cov-report=term-missing
```

## Performance Benchmarks

- Session creation: < 500ms
- Simple execution: < 1s
- Batch execution (3 commands): < 2s
- Metadata queries: < 100ms

## Security Notes

⚠️ **Development Only**
- CORS is open to all origins
- No authentication enforced
- Use only for local testing

For production:
- Enable authentication
- Restrict CORS origins
- Use HTTPS
- Implement rate limiting

## Documentation

- API Docs (Swagger): `http://localhost:8000/api/docs`
- ReDoc: `http://localhost:8000/api/redoc`
- OpenAPI Schema: `http://localhost:8000/api/openapi.json`

## Support

For issues or questions about testing:
1. Check test output for error messages
2. Review logs in `/tmp/unilab_tests/`
3. Run with `--verbose` flag
4. Check API logs in uvicorn terminal
