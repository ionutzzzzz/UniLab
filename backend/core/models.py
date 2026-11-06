from __future__ import annotations
import math
import pathlib
import re
import tempfile
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Tuple, Callable
from enum import Enum

import numpy as np

SAFE_IDENTIFIER_RE = re.compile(r"^[a-zA-Z0-9_-]{1,64}$")


def validate_safe_identifier(value: str, label: str = "identifier") -> str:
    """Validate username or session_id against path-traversal and injection characters."""
    if not isinstance(value, str) or not SAFE_IDENTIFIER_RE.match(value):
        raise ValueError(f"Invalid {label}: must match ^[a-zA-Z0-9_-]{{1,64}}$")
    return value


def safe_resolve_in_workspace(workspace_root: pathlib.Path, user_path: str | pathlib.Path) -> pathlib.Path:
    """Resolve user_path under workspace_root and forbid escaping outside workspace_root."""
    ws_resolved = pathlib.Path(workspace_root).resolve()
    p = pathlib.Path(user_path)
    if p.is_absolute():
        candidate = p.resolve()
    else:
        candidate = (ws_resolved / p).resolve()
    if not candidate.is_relative_to(ws_resolved):
        raise PermissionError(f"Access denied: path '{user_path}' resolves outside workspace")
    return candidate


def sanitize_for_json(obj: Any) -> Any:
    """Recursively sanitize NaN/Inf floats and NumPy scalars/arrays into strict JSON-safe Python values."""
    if obj is None or isinstance(obj, (str, bool, int)):
        return obj
    if isinstance(obj, (np.bool_,)):
        return bool(obj)
    if isinstance(obj, (np.integer,)):
        return int(obj)
    if isinstance(obj, (float, np.floating)):
        val = float(obj)
        if math.isnan(val) or math.isinf(val):
            return None
        return val
    if isinstance(obj, (complex, np.complexfloating)):
        r = sanitize_for_json(obj.real)
        im = sanitize_for_json(obj.imag)
        return {"real": r, "imag": im}
    if isinstance(obj, np.ndarray):
        return sanitize_for_json(obj.tolist())
    if isinstance(obj, dict):
        return {str(k): sanitize_for_json(v) for k, v in obj.items()}
    if isinstance(obj, (list, tuple)):
        return [sanitize_for_json(v) for v in obj]
    return str(obj)


class EngineType(str, Enum):
    TRANSPILER = "transpiler"

@dataclass
class BackendConfig:
    workspace_root: pathlib.Path = pathlib.Path("./.console_workspaces/unilab_workspaces")
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
