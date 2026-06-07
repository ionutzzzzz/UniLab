import pathlib
from backend.core.unilab_core import UniLabCore
from backend.core.models import BackendConfig

_core_instance = None

def get_core() -> UniLabCore:
    global _core_instance
    if _core_instance is None:
        workspace_root = pathlib.Path(os.environ.get("UNILAB_WORKSPACE_ROOT", "./prod_workspaces")).resolve()
        config = BackendConfig(
            workspace_root=workspace_root,
            use_docker=False
        )
        _core_instance = UniLabCore(config)
    return _core_instance

import os
