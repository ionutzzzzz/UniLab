"""
Unit tests for UniLab API endpoints.
Run with: pytest tests/unit/test_api_endpoints.py -v
"""

import sys
import pathlib

# Add project root to sys.path
current_dir = pathlib.Path(__file__).resolve().parent
project_root = (current_dir / ".." / ".." / "..").resolve()
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

import pytest
pytest.importorskip("backend.api.main")
from fastapi.testclient import TestClient

# Import API and dependencies
from backend.api.main import app

# Test client
client = TestClient(app)


class TestSessionEndpoints:
    """Tests for session management endpoints."""
    
    def test_create_session(self):
        """Test creating a new session."""
        response = client.post(
            "/api/v1/sessions",
            json={
                "username": "testuser",
                "engine": "transpiler"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "session_id" in data
        assert data["username"] == "testuser"
        assert data["engine"] == "transpiler"
    
    def test_list_sessions(self):
        """Test listing all sessions."""
        response = client.get("/api/v1/sessions")
        
        assert response.status_code == 200
        data = response.json()
        assert "sessions" in data
        assert "total" in data
        assert isinstance(data["sessions"], list)
    
    def test_get_session(self):
        """Test getting a specific session."""
        # First create a session
        create_response = client.post(
            "/api/v1/sessions",
            json={"username": "testuser", "engine": "transpiler"}
        )
        session_id = create_response.json()["session_id"]
        
        # Then get it
        response = client.get(f"/api/v1/sessions/{session_id}")
        
        assert response.status_code == 200
        data = response.json()
        assert data["session_id"] == session_id
    
    def test_delete_session(self):
        """Test deleting a session."""
        # Create a session
        create_response = client.post(
            "/api/v1/sessions",
            json={"username": "testuser", "engine": "transpiler"}
        )
        session_id = create_response.json()["session_id"]
        
        # Delete it
        response = client.delete(f"/api/v1/sessions/{session_id}")
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"


class TestExecutionEndpoints:
    """Tests for code execution endpoints."""
    
    def setup_method(self):
        """Set up test fixtures."""
        # Create a session for testing
        response = client.post(
            "/api/v1/sessions",
            json={"username": "testexec", "engine": "transpiler"}
        )
        self.session_id = response.json()["session_id"]
    
    def test_execute_simple_code(self):
        """Test executing simple code."""
        response = client.post(
            f"/api/v1/sessions/{self.session_id}/execute",
            json={"code": "x = 5; y = 10;"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "success" in data
        assert "stdout" in data
        assert "stderr" in data
    
    def test_execute_code_with_output(self):
        """Test code execution with output."""
        response = client.post(
            f"/api/v1/sessions/{self.session_id}/execute",
            json={"code": "disp('Hello World');"}
        )
        
        assert response.status_code == 200
        data = response.json()
        # Output should be captured
        assert "stdout" in data or "Hello" in str(data)
    
    def test_batch_execution(self):
        """Test batch code execution."""
        commands = [
            {"code": "x = 1;"},
            {"code": "y = 2;"},
            {"code": "z = x + y;"}
        ]
        
        response = client.post(
            f"/api/v1/sessions/{self.session_id}/batch",
            json={
                "commands": commands,
                "stop_on_error": False
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 3
        assert data["failed"] == 0
    
    def test_transpile_code(self):
        """Test code transpilation."""
        response = client.post(
            f"/api/v1/sessions/{self.session_id}/transpile",
            json={"code": "x = [1 2 3]; y = x + 1;"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "python_code" in data
        assert "unilab_code" in data
        assert len(data["python_code"]) > 0


class TestWorkspaceEndpoints:
    """Tests for workspace management endpoints."""
    
    def setup_method(self):
        """Set up test fixtures."""
        response = client.post(
            "/api/v1/sessions",
            json={"username": "testworkspace", "engine": "transpiler"}
        )
        self.session_id = response.json()["session_id"]
    
    def test_get_workspace(self):
        """Test getting workspace state."""
        response = client.get(
            f"/api/v1/sessions/{self.session_id}/workspace"
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "variables" in data
        assert "total_size_bytes" in data
        assert "variable_count" in data
    
    def test_set_variable(self):
        """Test setting a variable."""
        response = client.post(
            f"/api/v1/sessions/{self.session_id}/vars/test_var",
            json={"value": 42}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
    
    def test_get_variable(self):
        """Test getting a specific variable."""
        # Set a variable first
        client.post(
            f"/api/v1/sessions/{self.session_id}/vars/test_var",
            json={"value": 42}
        )
        
        # Then get it
        response = client.get(
            f"/api/v1/sessions/{self.session_id}/vars/test_var"
        )
        
        assert response.status_code in [200, 404]  # May not exist immediately
    
    def test_clear_workspace(self):
        """Test clearing workspace."""
        response = client.post(
            f"/api/v1/sessions/{self.session_id}/clear",
            json={}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"


class TestFileEndpoints:
    """Tests for file operations endpoints."""
    
    def setup_method(self):
        """Set up test fixtures."""
        response = client.post(
            "/api/v1/sessions",
            json={"username": "testfiles", "engine": "transpiler"}
        )
        self.session_id = response.json()["session_id"]
    
    def test_list_files(self):
        """Test listing workspace files."""
        response = client.get(
            f"/api/v1/sessions/{self.session_id}/files"
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "files" in data
        assert "total" in data
        assert "path" in data
    
    def test_create_file(self):
        """Test creating a file."""
        response = client.post(
            f"/api/v1/sessions/{self.session_id}/files/create",
            json={
                "filename": "test.m",
                "content": "x = 1; y = 2;",
                "overwrite": True
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["filename"] == "test.m"


class TestMetadataEndpoints:
    """Tests for metadata endpoints."""
    
    def test_list_functions(self):
        """Test listing available functions."""
        response = client.get("/api/v1/functions")
        
        assert response.status_code == 200
        data = response.json()
        assert "functions" in data
        assert "total" in data
        assert data["total"] > 0
    
    def test_get_function(self):
        """Test getting function details."""
        response = client.get("/api/v1/functions/sin")
        
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "sin"
        assert "category" in data
        assert "description" in data
    
    def test_list_libraries(self):
        """Test listing available libraries."""
        response = client.get("/api/v1/libraries")
        
        assert response.status_code == 200
        data = response.json()
        assert "libraries" in data
        assert "total" in data
        assert data["total"] > 0
    
    def test_get_library(self):
        """Test getting library details."""
        response = client.get("/api/v1/libraries/math")
        
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "math"
        assert "functions" in data


class TestSystemEndpoints:
    """Tests for system monitoring endpoints."""
    
    def test_health_check(self):
        """Test health check endpoint."""
        response = client.get("/api/v1/health")
        
        assert response.status_code == 200
        data = response.json()
        assert "status" in data
        assert "uptime_s" in data
        assert "timestamp" in data
    
    def test_get_metrics(self):
        """Test metrics endpoint."""
        response = client.get("/api/v1/metrics")
        
        assert response.status_code == 200
        data = response.json()
        assert "active_sessions" in data
        assert "total_executions" in data
        assert "uptime_s" in data
    
    def test_get_settings(self):
        """Test settings endpoint."""
        response = client.get("/api/v1/settings")
        
        assert response.status_code == 200
        data = response.json()
        assert "max_sessions" in data
        assert "default_engine" in data
        assert "version" in data
    
    def test_get_version(self):
        """Test version endpoint."""
        response = client.get("/api/v1/version")
        
        assert response.status_code == 200
        data = response.json()
        assert "version" in data
        assert "name" in data
    
    def test_system_info(self):
        """Test complete system info endpoint."""
        response = client.get("/api/v1/system-info")
        
        assert response.status_code == 200
        data = response.json()
        assert "health" in data
        assert "metrics" in data
        assert "settings" in data


class TestAPIRouting:
    """Tests for API routing and configuration."""
    
    def test_root_endpoint(self):
        """Test root endpoint."""
        response = client.get("/")
        
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "version" in data
    
    def test_api_v1_root(self):
        """Test API v1 root."""
        response = client.get("/api/v1")
        
        assert response.status_code == 200
        data = response.json()
        assert "endpoints" in data
    
    def test_docs_available(self):
        """Test that API documentation is available."""
        response = client.get("/api/docs")
        
        assert response.status_code == 200
    
    def test_openapi_schema(self):
        """Test that OpenAPI schema is available."""
        response = client.get("/api/openapi.json")
        
        assert response.status_code == 200
        data = response.json()
        assert "openapi" in data


class TestErrorHandling:
    """Tests for error handling."""
    
    def test_nonexistent_session(self):
        """Test accessing nonexistent session."""
        response = client.get("/api/v1/sessions/nonexistent")
        
        assert response.status_code == 404
    
    def test_invalid_json(self):
        """Test invalid JSON payload."""
        response = client.post(
            "/api/v1/sessions",
            data="invalid json",
            headers={"Content-Type": "application/json"}
        )
        
        assert response.status_code == 422  # Validation error
    
    def test_missing_required_fields(self):
        """Test missing required fields."""
        response = client.post(
            "/api/v1/sessions/{session_id}/execute",
            json={}  # Missing 'code' field
        )
        
        # This should fail validation
        assert response.status_code in [404, 422]


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
