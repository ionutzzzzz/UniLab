import asyncio
import pathlib
import sys
import os

# Add the project root to sys.path to import the backend
PROJECT_ROOT = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(PROJECT_ROOT))

from backend.core.main import UniLabCore, BackendConfig

async def test_advanced_features():
    print("Initializing UniLabCore...")
    cfg = BackendConfig(workspace_root=pathlib.Path("./test_workspaces"), use_docker=False)
    core = UniLabCore(cfg)
    await core.start()
    
    print("Creating session with 'transpiler' engine...")
    try:
        session = await core.create_session(username="test_user", engine="transpiler")
        
        # 1. Test Switch/Case
        switch_code = """
val = 2;
switch val
    case 1
        result = 'one';
    case 2
        result = 'two';
    otherwise
        result = 'other';
end
        """
        print("\nTesting Switch/Case:")
        res = await core.run_code(session.session_id, switch_code)
        vars_snap = await core._fetch_variables(session.session_id)
        print(f" - result: {vars_snap.get('result', {}).get('preview')}")

        # 2. Test Try/Catch
        try_code = """
try
    A = [1 2; 3 4];
    % This should fail because 'non_existent_var' is undefined
    X = A + non_existent_var;
catch err
    error_msg = 'Caught an error';
end
        """
        print("\nTesting Try/Catch:")
        res = await core.run_code(session.session_id, try_code)
        vars_snap = await core._fetch_variables(session.session_id)
        print(f" - error_msg: {vars_snap.get('error_msg', {}).get('preview')}")

        # 3. Test Global
        global_code = """
global G_VAR;
G_VAR = 100;

function v = get_global()
    global G_VAR;
    v = G_VAR;
end

val_from_global = get_global();
        """
        print("\nTesting Global variables:")
        res = await core.run_code(session.session_id, global_code)
        vars_snap = await core._fetch_variables(session.session_id)
        print(f" - val_from_global: {vars_snap.get('val_from_global', {}).get('preview')}")

    except Exception as e:
        print(f"Error during test: {e}")
        import traceback
        traceback.print_exc()
    finally:
        await core.stop()

if __name__ == "__main__":
    asyncio.run(test_advanced_features())
