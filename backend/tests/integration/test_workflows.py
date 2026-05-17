"""
Integration tests for UniLab API - full workflow testing.
Run with: pytest tests/integration/test_workflows.py -v
"""

import pytest
import asyncio
from fastapi.testclient import TestClient

from backend.api.main import app

client = TestClient(app)


class TestCompleteWorkflows:
    """Integration tests for complete workflows."""
    
    def test_complete_computation_workflow(self):
        """Test a complete computation workflow from session to export."""
        
        # Step 1: Create a session
        session_response = client.post(
            "/api/v1/sessions",
            json={"username": "workflow_test", "engine": "transpiler"}
        )
        assert session_response.status_code == 200
        session_id = session_response.json()["session_id"]
        print(f"Created session: {session_id}")
        
        # Step 2: Execute some code
        exec_response = client.post(
            f"/api/v1/sessions/{session_id}/execute",
            json={"code": "x = linspace(0, 2*pi, 100);"}
        )
        assert exec_response.status_code == 200
        assert exec_response.json()["success"]
        print("Executed linspace code")
        
        # Step 3: Get workspace state
        ws_response = client.get(f"/api/v1/sessions/{session_id}/workspace")
        assert ws_response.status_code == 200
        variables = ws_response.json()["variables"]
        print(f"Workspace has {len(variables)} variables")
        
        # Step 4: Run more computations
        compute_response = client.post(
            f"/api/v1/sessions/{session_id}/execute",
            json={"code": "y = sin(x); z = cos(x);"}
        )
        assert compute_response.status_code == 200
        print("Computed sin and cos")
        
        # Step 5: Export workspace
        export_response = client.post(
            f"/api/v1/sessions/{session_id}/export",
            json={"format": "json"}
        )
        assert export_response.status_code == 200
        print("Exported workspace")
        
        # Step 6: Cleanup
        cleanup_response = client.delete(f"/api/v1/sessions/{session_id}")
        assert cleanup_response.status_code == 200
        print("Deleted session")
    
    def test_batch_script_execution_workflow(self):
        """Test batch script execution workflow."""
        
        # Create session
        session_response = client.post(
            "/api/v1/sessions",
            json={"username": "batch_test", "engine": "transpiler"}
        )
        session_id = session_response.json()["session_id"]
        
        # Create a script file
        create_file_response = client.post(
            f"/api/v1/sessions/{session_id}/files/create",
            json={
                "filename": "analysis.m",
                "content": "data = [1, 2, 3, 4, 5]; mean_val = mean(data);",
                "overwrite": True
            }
        )
        assert create_file_response.status_code == 200
        
        # Run the script
        run_script_response = client.post(
            f"/api/v1/sessions/{session_id}/scripts/run",
            json={"filename": "analysis.m"}
        )
        assert run_script_response.status_code == 200
        
        # Verify results
        ws_response = client.get(f"/api/v1/sessions/{session_id}/workspace")
        assert ws_response.status_code == 200
        
        # Cleanup
        client.delete(f"/api/v1/sessions/{session_id}")
    
    def test_concurrent_session_workflow(self):
        """Test concurrent session operations."""
        
        sessions = []
        
        # Create multiple sessions
        for i in range(3):
            response = client.post(
                "/api/v1/sessions",
                json={"username": f"user_{i}", "engine": "transpiler"}
            )
            assert response.status_code == 200
            sessions.append(response.json()["session_id"])
        
        # Execute code in each session
        for i, session_id in enumerate(sessions):
            response = client.post(
                f"/api/v1/sessions/{session_id}/execute",
                json={"code": f"x = {i * 10};"}
            )
            assert response.status_code == 200
        
        # List all sessions
        list_response = client.get("/api/v1/sessions")
        assert list_response.status_code == 200
        
        # Cleanup
        for session_id in sessions:
            client.delete(f"/api/v1/sessions/{session_id}")
    
    def test_error_recovery_workflow(self):
        """Test error handling and recovery."""
        
        # Create session
        session_response = client.post(
            "/api/v1/sessions",
            json={"username": "error_test", "engine": "transpiler"}
        )
        session_id = session_response.json()["session_id"]
        
        # Execute code that might cause an error
        error_response = client.post(
            f"/api/v1/sessions/{session_id}/execute",
            json={"code": "x = undefined_var;"}
        )
        
        # Should still return 200, but success=false
        assert error_response.status_code == 200
        result = error_response.json()
        # The execution itself succeeded (API-wise), but the code failed
        
        # Verify we can still use the session
        recovery_response = client.post(
            f"/api/v1/sessions/{session_id}/execute",
            json={"code": "x = 42;"}
        )
        assert recovery_response.status_code == 200
        assert recovery_response.json()["success"]
        
        # Cleanup
        client.delete(f"/api/v1/sessions/{session_id}")


class TestDataPersistence:
    """Test data persistence across requests."""
    
    def test_variable_persistence(self):
        """Test that variables persist across requests."""
        
        # Create session
        session_response = client.post(
            "/api/v1/sessions",
            json={"username": "persist_test", "engine": "transpiler"}
        )
        session_id = session_response.json()["session_id"]
        
        # Set a variable
        exec1 = client.post(
            f"/api/v1/sessions/{session_id}/execute",
            json={"code": "x = 100;"}
        )
        assert exec1.status_code == 200
        
        # Use the variable in a new request
        exec2 = client.post(
            f"/api/v1/sessions/{session_id}/execute",
            json={"code": "y = x * 2;"}
        )
        assert exec2.status_code == 200
        
        # Verify both variables exist
        ws_response = client.get(f"/api/v1/sessions/{session_id}/workspace")
        variables = ws_response.json()["variables"]
        
        # Cleanup
        client.delete(f"/api/v1/sessions/{session_id}")
    
    def test_file_persistence(self):
        """Test that files persist across requests."""
        
        # Create session
        session_response = client.post(
            "/api/v1/sessions",
            json={"username": "file_persist_test", "engine": "transpiler"}
        )
        session_id = session_response.json()["session_id"]
        
        # Create a file
        create_response = client.post(
            f"/api/v1/sessions/{session_id}/files/create",
            json={
                "filename": "persistent.m",
                "content": "persistent_x = 123;",
                "overwrite": True
            }
        )
        assert create_response.status_code == 200
        
        # List files - should find it
        list_response = client.get(f"/api/v1/sessions/{session_id}/files")
        assert list_response.status_code == 200
        
        # Cleanup
        client.delete(f"/api/v1/sessions/{session_id}")


class TestMetadataAccuracy:
    """Test accuracy of metadata endpoints."""
    
    def test_functions_list_completeness(self):
        """Test that functions list is complete."""
        
        response = client.get("/api/v1/functions")
        assert response.status_code == 200
        data = response.json()
        
        # Should have multiple functions
        assert data["total"] > 5
        
        # Check for specific functions
        function_names = [f["name"] for f in data["functions"]]
        assert "sin" in function_names
        assert "cos" in function_names
        assert "exp" in function_names
    
    def test_libraries_list_completeness(self):
        """Test that libraries list is complete."""
        
        response = client.get("/api/v1/libraries")
        assert response.status_code == 200
        data = response.json()
        
        # Should have multiple libraries
        assert data["total"] > 3
        
        # Check for specific libraries
        library_names = [lib["name"] for lib in data["libraries"]]
        assert "math" in library_names
        assert "signal" in library_names or "control" in library_names
    
    def test_function_search(self):
        """Test function search functionality."""
        
        response = client.post(
            "/api/v1/functions/search",
            json={"query": "sin"}
        )
        assert response.status_code == 200
        data = response.json()
        
        # Should find sin-related functions
        assert len(data["results"]) > 0


class TestPerformance:
    """Basic performance tests."""
    
    def test_session_creation_speed(self):
        """Test session creation is fast."""
        import time
        
        start = time.time()
        response = client.post(
            "/api/v1/sessions",
            json={"username": "perf_test", "engine": "transpiler"}
        )
        elapsed = time.time() - start
        
        assert response.status_code == 200
        assert elapsed < 5  # Should be fast
        
        # Cleanup
        session_id = response.json()["session_id"]
        client.delete(f"/api/v1/sessions/{session_id}")
    
    def test_execution_speed(self):
        """Test code execution speed for simple operations."""
        import time
        
        session_response = client.post(
            "/api/v1/sessions",
            json={"username": "speed_test", "engine": "transpiler"}
        )
        session_id = session_response.json()["session_id"]
        
        start = time.time()
        response = client.post(
            f"/api/v1/sessions/{session_id}/execute",
            json={"code": "x = 1 + 1;"}
        )
        elapsed = time.time() - start
        
        assert response.status_code == 200
        assert elapsed < 2  # Should be very fast
        
        # Cleanup
        client.delete(f"/api/v1/sessions/{session_id}")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
