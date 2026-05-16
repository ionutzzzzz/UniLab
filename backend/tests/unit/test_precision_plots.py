import asyncio
import pathlib
import sys
import os

PROJECT_ROOT = pathlib.Path(__file__).resolve().parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from backend.core.main import UniLabCore, BackendConfig

async def test_precision():
    print("Starting Precision Rendering Test...")
    cfg = BackendConfig(workspace_root=pathlib.Path("./test_precision"))
    core = UniLabCore(cfg)
    await core.start()
    
    try:
        session = await core.create_session(username="precision_tester", engine="transpiler")
        sid = session.session_id
        
        print("\n" + "="*60)
        print(" TEST: Precise Sin/Cos Waves with Labels")
        print("="*60)
        cmd = """
        x = linspace(0, 10, 100);
        y1 = sin(x);
        y2 = cos(x);
        plot(x, y1, 'r', x, y2, 'b');
        title('PRECISION TEST: SIN & COS');
        xlabel('Time Axis');
        ylabel('Value');
        """
        res = await core.run_code(sid, cmd)
        if res.stdout: print(res.stdout)
        if res.stderr: print(f"Error: {res.stderr}")

    finally:
        await core.stop()
        if pathlib.Path("./test_precision").exists():
            import shutil
            shutil.rmtree("./test_precision")

if __name__ == "__main__":
    asyncio.run(test_precision())
