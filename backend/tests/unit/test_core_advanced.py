import pytest
import asyncio
import pathlib
import shutil
import time
from backend.core.main import UniLabCore, BackendConfig

@pytest.fixture
def workspace_root():
    root = pathlib.Path("./test_core_adv")
    if root.exists():
        shutil.rmtree(root)
    root.mkdir(parents=True, exist_ok=True)
    yield root
    if root.exists():
        shutil.rmtree(root)

@pytest.mark.asyncio
async def test_concurrent_sessions(workspace_root):
    cfg = BackendConfig(workspace_root=workspace_root)
    core = UniLabCore(cfg)
    await core.start()
    
    try:
        # Create two sessions
        s1 = await core.create_session(username="user1")
        s2 = await core.create_session(username="user2")
        
        # Execute code in parallel
        t1 = core.run_code(s1.session_id, "x = 10;")
        t2 = core.run_code(s2.session_id, "x = 20;")
        
        res1, res2 = await asyncio.gather(t1, t2)
        
        assert res1.success
        assert res2.success
        
        # Check isolation
        res1_check = await core.run_code(s1.session_id, "disp(x);")
        res2_check = await core.run_code(s2.session_id, "disp(x);")
        
        assert "10" in res1_check.stdout
        assert "20" in res2_check.stdout
        
    finally:
        await core.stop()

@pytest.mark.asyncio
async def test_workspace_persistence(workspace_root):
    cfg = BackendConfig(workspace_root=workspace_root)
    core = UniLabCore(cfg)
    await core.start()
    
    session_id = None
    username = "persistence_user"
    
    try:
        s = await core.create_session(username=username)
        session_id = s.session_id
        
        # Set a variable
        await core.run_code(session_id, "persisted_var = 123;")
        
        # Stop session (this should save the workspace)
        await core.stop_session(session_id)
        
        # Create a new session for the same user with same workspace path
        # We need to manually recreate it or rely on the same naming convention
        # Core uses f"{username}_{session_id}" which is unique.
        # Let's mock a shared workspace scenario.
        
        shared_path = workspace_root / "shared_ws"
        shared_path.mkdir(exist_ok=True)
        
        s_shared = await core.create_session(username=username, shared_workspace=shared_path)
        await core.run_code(s_shared.session_id, "shared_var = 456;")
        await core.stop_session(s_shared.session_id)
        
        # Re-open shared workspace
        s_shared_revival = await core.create_session(username=username, shared_workspace=shared_path)
        res = await core.run_code(s_shared_revival.session_id, "disp(shared_var);")
        
        assert "456" in res.stdout
        
    finally:
        await core.stop()

@pytest.mark.asyncio
async def test_file_operations(workspace_root):
    cfg = BackendConfig(workspace_root=workspace_root)
    core = UniLabCore(cfg)
    await core.start()
    
    try:
        s = await core.create_session(username="file_user")
        sid = s.session_id
        
        # Write a file
        await core.write_file(sid, "test_file.txt", "Hello UniLab")
        
        # List files
        files = await core.list_files(sid)
        assert any(f["name"] == "test_file.txt" for f in files)
        
        # Read file
        content = await core.read_file(sid, "test_file.txt")
        assert content == "Hello UniLab"
        
    finally:
        await core.stop()

@pytest.mark.asyncio
async def test_autoload_standard_lib(workspace_root):
    # This test assumes 'sin' or some standard library exists
    cfg = BackendConfig(workspace_root=workspace_root)
    core = UniLabCore(cfg)
    await core.start()
    
    try:
        s = await core.create_session(username="lib_user")
        sid = s.session_id
        
        # Test a built-in math function from numpy (np.pi)
        res = await core.run_code(sid, "y = sin(pi()/2); disp(y);")
        assert res.success
        assert "1.0" in res.stdout
        
    finally:
        await core.stop()

@pytest.mark.asyncio
async def test_help_system(workspace_root):
    cfg = BackendConfig(workspace_root=workspace_root)
    core = UniLabCore(cfg)
    await core.start()
    
    try:
        s = await core.create_session(username="help_user")
        sid = s.session_id
        
        # Test help command
        res = await core.run_code(sid, "help sin")
        assert res.success
        assert "sin" in res.stdout.lower()
        
    finally:
        await core.stop()

if __name__ == "__main__":
    pytest.main([__file__])
