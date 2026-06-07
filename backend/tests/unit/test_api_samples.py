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

def test_sample(filename):
    print(f"\n--- Testing Sample: {filename} ---")
    
    # 1. Create Session
    response = client.post("/api/v1/sessions", json={"username": "test_user", "engine": "transpiler"})
    if response.status_code != 200:
        print(f"Failed to create session: {response.text}")
        return
    
    session_id = response.json()["session_id"]
    
    # 2. Read Sample Code
    sample_path = project_root / "sample" / filename
    if not sample_path.exists():
        print(f"Sample not found: {sample_path}")
        return
    
    code = sample_path.read_text(encoding="utf-8")
    
    # 3. Execute Code
    # Get transpiled code first
    transpiled_response = client.post(f"/api/v1/sessions/{session_id}/transpile", json={"code": code})
    python_code = ""
    if transpiled_response.status_code == 200:
        python_code = transpiled_response.json()["python_code"]

    response = client.post(f"/api/v1/sessions/{session_id}/execute", json={"code": code})
    
    if response.status_code == 200:
        result = response.json()
        if result["success"]:
            print("SUCCESS")
            # print("STDOUT:")
            # print(result["stdout"])
        else:
            print("FAILED")
            print("STDERR:")
            print(result["stderr"])
            if python_code:
                print("TRANSPILED CODE:")
                print(python_code)
            
        if result["plots"]:
            print(f"Generated {len(result['plots'])} plots.")
    else:
        print(f"API Error ({response.status_code}): {response.text}")

    # 4. Cleanup Session
    client.delete(f"/api/v1/sessions/{session_id}")

if __name__ == "__main__":
    samples = [
        "51_electrical_grid_management.m",
        "52_finance_portfolio_optimization.m",
        "53_ml_random_forest_maintenance.m",
        "54_numerical_ode_comparison.m",
        "55_chemical_process_yield.m",
        "56_graph_theory_social_analysis.m",
        "57_astronomy_exoplanet_transit.m",
        "58_control_lqr_pendulum.m",
        "59_signal_radar_range.m",
        "60_image_character_extraction.m"
    ]
    
    for s in samples:
        test_sample(s)
