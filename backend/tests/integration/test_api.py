import unittest
from fastapi.testclient import TestClient
import pathlib
import shutil
import os

# We might need to mock dependencies if we can't run the full core
try:
    from backend.api.main import app
    from backend.api.dependencies import get_core
except ImportError:
    # Fallback if fastapi is not installed in the environment where tests are written
    app = None
    get_core = None

from backend.core.unilab_core import UniLabCore, BackendConfig

class TestUniLabAPI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.test_dir = pathlib.Path("./api_test_workspace")
        if cls.test_dir.exists():
            shutil.rmtree(cls.test_dir)
        cls.test_dir.mkdir()
        
        cls.config = BackendConfig(workspace_root=cls.test_dir, use_docker=False)
        cls.core = UniLabCore(cls.config)
        
        if app:
            from fastapi.testclient import TestClient
            # Override dependency
            app.dependency_overrides[get_core] = lambda: cls.core
            cls.client = TestClient(app)
        else:
            cls.client = None

    @classmethod
    def tearDownClass(cls):
        if cls.test_dir.exists():
            shutil.rmtree(cls.test_dir)
        if app:
            app.dependency_overrides.clear()

    def test_root(self):
        if not self.client:
            self.skipTest("FastAPI not installed")
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("UniLab API is running", response.json()["message"])

    def test_create_session(self):
        if not self.client:
            self.skipTest("FastAPI not installed")
        response = self.client.post("/compute/sessions", json={"username": "api_user", "engine": "transpiler"})
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("session_id", data)
        self.assertEqual(data["engine"], "transpiler")
        return data["session_id"]

    def test_run_code(self):
        if not self.client:
            self.skipTest("FastAPI not installed")
        session_id = self.test_create_session()
        code = "a = 5; b = 10; c = a + b; disp(c);"
        response = self.client.post("/compute/run", json={
            "session_id": session_id,
            "code": code
        })
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertTrue(data["success"])
        # Note: result might fail if transpiler is broken, but the API call itself should succeed
        if data["success"]:
            self.assertIn("15", data["stdout"])

    def test_invalid_session(self):
        if not self.client:
            self.skipTest("FastAPI not installed")
        response = self.client.post("/compute/run", json={
            "session_id": "non-existent-session",
            "code": "disp(1);"
        })
        self.assertEqual(response.status_code, 404)

if __name__ == "__main__":
    unittest.main()
