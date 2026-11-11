import sys
import pathlib
from fastapi.testclient import TestClient

# Add the project root to sys.path
current_dir = pathlib.Path(__file__).resolve().parent
project_root = current_dir.resolve()
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

import pytest
pytest.importorskip("backend.api.main")
from backend.api.main import app

client = TestClient(app)

def test_single_sample(filename):
    print(f"\n--- Testing Sample: {filename} ---")
    
    # 1. Create Session
    response = client.post("/api/v1/sessions", json={"username": "test_user", "engine": "transpiler"})
    if response.status_code != 200:
        print(f"Failed to create session: {response.text}")
        return
    
    session_id = response.json()["session_id"]
    
    # 2. Read Sample Code
    sample_path = project_root / "sample" / filename
    code = sample_path.read_text(encoding="utf-8")
    
    # 3. Execute Code
    response = client.post(f"/api/v1/sessions/{session_id}/execute", json={"code": code})
    
    if response.status_code == 200:
        result = response.json()
        if result["success"]:
            print("SUCCESS")
            print(result["stdout"])
        else:
            print("FAILED")
            print(result["stderr"])
    else:
        print(f"API Error ({response.status_code}): {response.text}")

    # 4. Cleanup Session
    client.delete(f"/api/v1/sessions/{session_id}")

if __name__ == "__main__":
    test_single_sample("53_ml_random_forest_maintenance.m")
