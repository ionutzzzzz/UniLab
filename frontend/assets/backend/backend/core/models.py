from __future__ import annotations
import pathlib
import tempfile
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Tuple, Callable
from enum import Enum

class EngineType(str, Enum):
    TRANSPILER = "transpiler"

@dataclass
class BackendConfig:
    workspace_root: pathlib.Path = pathlib.Path("./unilab_workspaces")
    use_docker: bool = False
    docker_image: str = "unilab:latest"
    port: int = 8000
    plot_export_dirname: str = "plots"
    tmp_dir: pathlib.Path = pathlib.Path(tempfile.gettempdir())
    max_sessions: int = 16
    default_username: str = "default_user"
    metrics_enabled: bool = True
    auth_check: Optional[Callable[[str, Optional[str]], bool]] = None

@dataclass
class SessionInfo:
    session_id: str
    username: str
    engine: str
    started_at: float
    workspace_path: pathlib.Path
    container_id: Optional[str] = None
    is_shared: bool = False
    metadata: Dict[str, Any] = field(default_factory=dict)

@dataclass
class ExecutionResult:
    success: bool
    stdout: str
    stderr: str
    return_code: int
    duration_s: float
    variables_snapshot: Dict[str, Any] = field(default_factory=dict)
    plots: List[str] = field(default_factory=list)
    extra: Dict[str, Any] = field(default_factory=dict)

@dataclass
class VariableInfo:
    name: str
    dtype: str
    shape: Optional[Tuple[int, ...]] = None
    preview: Any = None
