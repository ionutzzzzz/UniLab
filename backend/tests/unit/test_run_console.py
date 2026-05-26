import asyncio
import os
import sys
import pathlib
sys.path.insert(0, os.path.abspath('.'))
from backend.core.unilab_core import UniLabCore, BackendConfig
from backend.core.models import SessionInfo

async def main():
    cfg = BackendConfig(workspace_root=pathlib.Path('./console_workspaces').resolve())
    core = UniLabCore(cfg)
    await core.start()
    session = await core.create_session("test_user", "transpiler")
    res = await core.run_code(session.session_id, "plot(1:10);")
    print("STDOUT:", repr(res.stdout))
    print("STDERR:", repr(res.stderr))
    await core.stop()

asyncio.run(main())
