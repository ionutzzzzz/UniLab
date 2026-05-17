import asyncio
import pathlib
import sys
import os
import pytest

PROJECT_ROOT = pathlib.Path(__file__).resolve().parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from backend.core.main import UniLabCore, BackendConfig

@pytest.mark.asyncio
async def test_all_plots():
    print("Starting Comprehensive Plot Tests...")
    cfg = BackendConfig(workspace_root=pathlib.Path("./test_workspace_all"))
    core = UniLabCore(cfg)
    await core.start()
    
    try:
        session = await core.create_session(username="tester", engine="transpiler")
        sid = session.session_id
        
        test_cases = [
            ("Scatter Plot (Sine)", "x = 0:0.5:10; y = sin(x); scatter_plot(x, y, 'Sine Wave');"),
            ("Bar Plot (Categorical)", "labels = {'A', 'B', 'C', 'D'}; values = [5, 12, 18, 7]; bar_plot(values, labels);"),
            ("Histogram (Normal Dist)", "data = randn(100, 1); hist_plot(data, 10);"),
            ("Stem Plot (Pulse)", "s = zeros(1, 10); s(5) = 1; s(6) = 0.5; stem_plot(s);"),
            ("Matrix Plot (Identity)", "plot_matrix(eye(5));"),
            ("Area Plot (Parabola)", "x = -5:1:5; y = x.^2; area_plot(x, y);"),
            ("Stairs Plot (Step)", "x = 0:1:10; y = floor(x/2); stairs_plot(x, y);"),
            ("Heatmap (Random 2D)", "M = rand(10, 10); heatmap(M);"),
            ("Box Plot (Uniform)", "data = rand(100, 1) * 100; box_plot(data);")
        ]
        
        for name, cmd in test_cases:
            print(f"\n" + "="*50)
            print(f" TEST: {name}")
            print("="*50)
            res = await core.run_code(sid, cmd)
            if res.stdout:
                print(res.stdout)
            if res.stderr:
                print(f"Error: {res.stderr}")
                
    finally:
        await core.stop()
        if pathlib.Path("./test_workspace_all").exists():
            import shutil
            shutil.rmtree("./test_workspace_all")

if __name__ == "__main__":
    asyncio.run(test_all_plots())
