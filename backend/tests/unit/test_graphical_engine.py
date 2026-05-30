import asyncio
import pathlib
import sys
import os
import pytest

PROJECT_ROOT = pathlib.Path(__file__).resolve().parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from backend.core.unilab_core import UniLabCore, BackendConfig

@pytest.mark.asyncio
async def test_graphical_engine():
    print("Starting Graphical Engine Tests...")
    cfg = BackendConfig(workspace_root=pathlib.Path("./test_graphical"))
    core = UniLabCore(cfg)
    await core.start()
    
    try:
        session = await core.create_session(username="beginner", engine="transpiler")
        sid = session.session_id
        
        print("\n" + "="*50)
        print(" TEST 1: Standard plot() -> graph.jpg")
        print("="*50)
        res = await core.run_code(sid, "x = 0:0.1:10; y = sin(x); plot(x, y);")
        print(f"STDOUT:\n{res.stdout}")
        
        graph_path = pathlib.Path("./test_graphical") / session.workspace_path.name / "graph.jpg"
        if graph_path.exists():
            print(f"✅ Success: graph.jpg created at {graph_path}")
        else:
            print(f"❌ Error: graph.jpg NOT found at {graph_path}")
            
        print("\n" + "="*50)
        print(" TEST 2: terminal_plot() -> updates graph.jpg")
        print("="*50)

        res = await core.run_code(sid, "scatter_plot(0:1:5, [1 4 9 16 25 36], 'Updates');")
        print(f"STDOUT:\n{res.stdout}")

        if graph_path.exists():
            print(f"✅ Success: graph.jpg still exists (updated)")

    finally:
        await core.stop()
        if pathlib.Path("./test_graphical").exists():
            import shutil
            shutil.rmtree("./test_graphical")

if __name__ == "__main__":
    asyncio.run(test_graphical_engine())
