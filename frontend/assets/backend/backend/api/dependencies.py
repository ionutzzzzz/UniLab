import os
import pathlib
from backend.core.unilab_core import UniLabCore
from backend.core.models import BackendConfig

_core_instance = None

def get_core() -> UniLabCore:
    global _core_instance
    if _core_instance is None:
        default_dir = "./.console_workspace" if pathlib.Path("./.console_workspace").exists() else "./.console_workspaces"
        workspace_root = pathlib.Path(os.environ.get("UNILAB_WORKSPACE_ROOT", default_dir)).resolve()
        config = BackendConfig(
            workspace_root=workspace_root,
            use_docker=False
        )
        _core_instance = UniLabCore(config)
    return _core_instance

