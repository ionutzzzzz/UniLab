import asyncio
import pathlib
import sys
import pytest

PROJECT_ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from backend.core.unilab_core import UniLabCore, BackendConfig

@pytest.mark.asyncio
async def test_ascii_labels():
    print("Starting ASCII Labels and Grid Tests...")
    cfg = BackendConfig(workspace_root=pathlib.Path("./test_labels"))
    core = UniLabCore(cfg)
    await core.start()
    
    try:
        session = await core.create_session(username="beginner", engine="transpiler")
        sid = session.session_id
        
        print("\n" + "="*50)
        print(" TEST 1: Labels and Grid in Transpiler")
        print("="*50)
        code = """
        x = 0:0.1:10;
        y = sin(x);
        plot(x, y);
        title('Sine Wave');
        xlabel('Time (s)');
        ylabel('Amplitude');
        grid on;
        """
        res = await core.run_code(sid, code)
        print(f"STDOUT:\n{res.stdout}")
        
        print("\n" + "="*50)
        print(" TEST 2: Grid as parameter in plot()")
        print("="*50)
        code = "plot(0:1:5, [1 4 9 16 25 36], 'grid', 'on'); title('Grid Param Test');"
        res = await core.run_code(sid, code)
        print(f"STDOUT:\n{res.stdout}")

    finally:
        await core.stop()
        if pathlib.Path("./test_labels").exists():
            import shutil
            shutil.rmtree("./test_labels")

if __name__ == "__main__":
    asyncio.run(test_ascii_labels())
