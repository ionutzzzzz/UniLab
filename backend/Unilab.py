"""
IDEBackend base class for a browser-based Octave/MATLAB-like IDE.

High-level responsibilities:
- Manage compute containers / processes (Docker / K8s / local)
- Provide an abstraction for interpreter engines (Octave, MATLAB, WASM)
- Execute commands, scripts, and return structured results (stdout, plots, variables)
- Offer debugging hooks (breakpoints, step/continue, variable inspection)
- Manage file-system within workspaces and support snapshots
- Provide collaboration primitives (rooms, sessions, locks, events)
- Provide hooks for telemetry, plugins, and orchestration (Dockerfile / K8s manifest)
"""

from __future__ import annotations
import asyncio
import subprocess
import json
import shlex
from dataclasses import dataclass, field
from typing import (
    Any, Dict, List, Optional, Tuple, Callable, Union, Iterable, Coroutine, Type
)
import pathlib
import uuid
import time
import logging
import tempfile
import os
from abc import ABC, abstractmethod
from enum import Enum

# Python >= 3.10 syntax assumed (for type hints)
logger = logging.getLogger("ide_backend")
logger.setLevel(logging.DEBUG)
ch = logging.StreamHandler()
ch.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
logger.addHandler(ch)


class EngineType(str, Enum):
    OCTAVE = "octave"
    MATLAB = "matlab"
    OCTAVE_WASM = "octave-wasm"
    COMPILED = "compiled"


@dataclass
class BackendConfig:
    workspace_root: pathlib.Path = pathlib.Path("/workspace")
    docker_image: str = "octave:latest"
    use_docker: bool = True
    port: int = 8000
    max_concurrent_sessions: int = 8
    default_engine: EngineType = EngineType.OCTAVE
    socket_path: Optional[str] = None 
    enable_plotly: bool = True
    plot_export_dir: pathlib.Path = pathlib.Path("/workspace/plots")
    metrics_enabled: bool = True
    tmp_dir: pathlib.Path = pathlib.Path(tempfile.gettempdir())
    # auth / security hooks (plug in your auth provider)
    auth_provider: Optional[Callable[[str, str], bool]] = None


@dataclass
class SessionInfo:
    session_id: str
    username: str
    started_at: float
    container_id: Optional[str] = None
    engine_type: EngineType = EngineType.OCTAVE
    workspace_path: pathlib.Path = field(default_factory=lambda: pathlib.Path("/workspace"))
    metadata: Dict[str, Any] = field(default_factory=dict)
    is_shared: bool = False  # shared container among multiple users
    locks: List[str] = field(default_factory=list)


@dataclass
class ExecutionResult:
    success: bool
    stdout: str
    stderr: str
    return_code: int
    duration_s: float
    variables_snapshot: Dict[str, Any] = field(default_factory=dict)
    plots: List[pathlib.Path] = field(default_factory=list)
    extra: Dict[str, Any] = field(default_factory=dict)


@dataclass
class VariableInfo:
    name: str
    dtype: str
    shape: Optional[Tuple[int, ...]] = None
    value_preview: Any = None


# Exceptions for error handling
class BackendError(Exception):
    pass


class EngineError(BackendError):
    pass


class SessionError(BackendError):
    pass


class DebuggerError(BackendError):
    pass


class CollaborationError(BackendError):
    pass


# Event type for pub/sub
@dataclass
class BackendEvent:
    event_type: str
    payload: Dict[str, Any]
    timestamp: float = field(default_factory=time.time)


class PluginHookType(str, Enum):
    PRE_RUN = "pre_run"
    POST_RUN = "post_run"
    PRE_SAVE = "pre_save"
    POST_SAVE = "post_save"
    ON_EVENT = "on_event"


class IDEBackend(ABC):
    """
    Base backend class representing the core services of the IDE.

    Concrete subclasses must implement engine-specific interaction methods:
    - _start_engine_process / _stop_engine_process
    - _send_to_engine / _fetch_variables
    - _set_breakpoint/_remove_breakpoint/_step/_continue etc.
    """

    def __init__(self, config: BackendConfig):
        self.config = config
        self.sessions: Dict[str, SessionInfo] = {}
        self.session_locks: Dict[str, asyncio.Lock] = {}
        self.global_lock = asyncio.Lock()
        self.event_queue: asyncio.Queue[BackendEvent] = asyncio.Queue()
        self.plugin_hooks: Dict[PluginHookType, List[Callable[..., Coroutine[Any,Any,Any]]]] = {}
        self.metrics: Dict[str, Any] = {"runs": 0, "errors": 0, "uptime_start": time.time()}
        self.shutdown_flag = False

        # thread pool executor for blocking ops (Docker CLI, heavy IO)
        self._executor = asyncio.get_event_loop().run_in_executor

        # Simplified in-memory repository for file watchers (can plug fsnotify)
        self._file_watchers: Dict[pathlib.Path, List[Callable[[pathlib.Path], None]]] = {}

        logger.debug(f"IDEBackend initialized with config: {self.config}")

    # ----------------------------
    # Lifecycle / Orchestration
    # ----------------------------
    async def start(self) -> None:
        """
        Start backend core services (schedulers, event pumps, health checks).
        Non-blocking. Subclasses may extend.
        """
        logger.info("Starting IDEBackend core services")
        asyncio.create_task(self._event_pump())
        asyncio.create_task(self._periodic_heartbeat())

    async def stop(self) -> None:
        logger.info("Shutting down IDEBackend")
        self.shutdown_flag = True
        # gracefully stop sessions
        for sid in list(self.sessions.keys()):
            try:
                await self.stop_session(sid)
            except Exception as e:
                logger.exception("Error stopping session %s: %s", sid, e)

    async def _periodic_heartbeat(self) -> None:
        while not self.shutdown_flag:
            await asyncio.sleep(10)
            # health checks, metrics flush, license checks may be added here
            self.metrics["uptime"] = time.time() - self.metrics["uptime_start"]
            logger.debug(f"Heartbeat. Sessions: {len(self.sessions)}. Metrics: {self.metrics}")

    async def _event_pump(self) -> None:
        while not self.shutdown_flag:
            try:
                ev: BackendEvent = await self.event_queue.get()
                logger.debug("Dispatching event: %s", ev.event_type)
                # dispatch to plugin hooks
                hooks = self.plugin_hooks.get(PluginHookType.ON_EVENT, [])
                for hook in hooks:
                    try:
                        asyncio.create_task(hook(ev))
                    except Exception:
                        logger.exception("Plugin hook failed")
                # general event routing (can be extended)
            except asyncio.CancelledError:
                break
            except Exception:
                logger.exception("Event pump error")

    # ----------------------------
    # Session Management
    # ----------------------------
    async def create_session(
        self,
        username: str,
        engine: Optional[EngineType] = None,
        workspace_subpath: Optional[str] = None,
        is_shared: bool = False,
    ) -> SessionInfo:
        """
        Creates and initializes a session for a user. If use_docker is true, this may spawn
        a container, otherwise start a process.
        """
        engine = engine or self.config.default_engine
        session_id = str(uuid.uuid4())
        workspace_path = (self.config.workspace_root / username / (workspace_subpath or session_id)).resolve()
        # ensure workspace exists
        os.makedirs(workspace_path, exist_ok=True)
        session = SessionInfo(
            session_id=session_id,
            username=username,
            started_at=time.time(),
            container_id=None,
            engine_type=engine,
            workspace_path=workspace_path,
            is_shared=is_shared,
        )
        self.sessions[session_id] = session
        self.session_locks[session_id] = asyncio.Lock()
        logger.info("Created session %s for user %s (engine=%s)", session_id, username, engine)

        # spawn container/engine for session
        try:
            container_id = await self._spawn_container_for_session(session)
            session.container_id = container_id
            await self._start_engine(session)
            # post-create plugin hook
            await self._run_plugins(PluginHookType.PRE_RUN, session=session)
        except Exception:
            logger.exception("Error creating session engine")
            # in case of failure, cleanup
            await self.stop_session(session_id)
            raise SessionError("Could not initialize session engine")

        return session

    async def stop_session(self, session_id: str) -> None:
        session = self.sessions.get(session_id)
        if session is None:
            logger.warning("stop_session called with unknown session_id=%s", session_id)
            return
        logger.info("Stopping session %s (user=%s)", session_id, session.username)
        # detach debugger and stop engine
        try:
            await self._stop_engine(session)
        except Exception:
            logger.exception("Error stopping engine for session %s", session_id)
        # stop/destroy container if applicable
        try:
            await self._destroy_container_for_session(session)
        except Exception:
            logger.exception("Error destroying container for session %s", session_id)
        # cleanup structures
        try:
            del self.session_locks[session_id]
        except KeyError:
            pass
        try:
            del self.sessions[session_id]
        except KeyError:
            pass

    # ----------------------------
    # Engine Abstraction (abstract)
    # ----------------------------
    @abstractmethod
    async def _spawn_container_for_session(self, session: SessionInfo) -> Optional[str]:
        """
        Create a container (or process) for the session and return container_id (or process id).
        Implementation detail depends on whether you use Docker, Kubernetes, or local processes.
        """
        raise NotImplementedError

    @abstractmethod
    async def _destroy_container_for_session(self, session: SessionInfo) -> None:
        raise NotImplementedError

    @abstractmethod
    async def _start_engine(self, session: SessionInfo) -> None:
        """
        Start interpreter engine (Octave/MATLAB/WASM) inside session context.
        """
        raise NotImplementedError

    @abstractmethod
    async def _stop_engine(self, session: SessionInfo) -> None:
        raise NotImplementedError

    @abstractmethod
    async def _send_to_engine(self, session: SessionInfo, code: str, timeout: Optional[float] = None) -> ExecutionResult:
        """
        Send code to running engine and return an ExecutionResult.
        Implementations convert engine's output into ExecutionResult fields.
        """
        raise NotImplementedError

    @abstractmethod
    async def _fetch_variables(self, session: SessionInfo) -> Dict[str, VariableInfo]:
        """
        Return a mapping of variable name -> VariableInfo for the session's workspace.
        """
        raise NotImplementedError

    # ----------------------------
    # High-level execution APIs
    # ----------------------------
    async def run_code(self, session_id: str, code: str, timeout: Optional[float] = 30.0) -> ExecutionResult:
        """
        High-level API to run arbitrary code in a session and return structured result.
        Runs plugin hooks and events.
        """
        session = self._get_session(session_id)
        async with self.session_locks[session_id]:
            start_ts = time.time()
            logger.debug("Running code for session %s: %s", session_id, code[:120].replace("\n", "\\n"))
            # pre-run hooks
            await self._run_plugins(PluginHookType.PRE_RUN, session=session, code=code)
            try:
                res = await self._send_to_engine(session, code, timeout=timeout)
                # refresh variables snapshot
                try:
                    vars_snap = await self._fetch_variables(session)
                    res.variables_snapshot = {k: self._variable_info_to_dict(v) for k, v in vars_snap.items()}
                except Exception:
                    logger.exception("Could not fetch variables snapshot")
                self.metrics["runs"] = self.metrics.get("runs", 0) + 1
            except Exception as e:
                logger.exception("Code run error")
                self.metrics["errors"] = self.metrics.get("errors", 0) + 1
                raise EngineError(str(e))
            finally:
                res.duration_s = time.time() - start_ts

            # post-run hooks
            await self._run_plugins(PluginHookType.POST_RUN, session=session, result=res)
            # emit event
            await self._emit_event("run.complete", {"session_id": session_id, "success": res.success})
            return res

    async def run_script_file(self, session_id: str, filepath: pathlib.Path, timeout: Optional[float] = 30.0) -> ExecutionResult:
        if not filepath.exists():
            raise FileNotFoundError(filepath.as_posix())
        code = filepath.read_text(encoding="utf-8")
        return await self.run_code(session_id, code, timeout=timeout)

    async def evaluate_expression(self, session_id: str, expression: str) -> Any:
        """
        Evaluate an expression and return Python-native result (attempts conversion).
        Caller should handle serialization of large arrays.
        """
        # wrap expression into a printing format that engine can return as JSON or a parseable output
        wrapper = f"try, disp(jsonencode({expression})), catch, disp({expression}), end"
        res = await self.run_code(session_id, wrapper)
        if not res.success:
            raise EngineError("Expression evaluation failed: " + res.stderr)
        # try to parse stdout for JSON
        text = res.stdout.strip()
        try:
            parsed = json.loads(text)
            return parsed
        except json.JSONDecodeError:
            # best-effort fallback to raw string
            return text

    # ----------------------------
    # Debugging
    # ----------------------------
    async def set_breakpoint(self, session_id: str, filename: str, line: int) -> None:
        session = self._get_session(session_id)
        return await self._set_breakpoint(session, filename, line)

    @abstractmethod
    async def _set_breakpoint(self, session: SessionInfo, filename: str, line: int) -> None:
        raise NotImplementedError

    @abstractmethod
    async def _remove_breakpoint(self, session: SessionInfo, filename: str, line: int) -> None:
        raise NotImplementedError

    @abstractmethod
    async def step_over(self, session_id: str) -> None:
        raise NotImplementedError

    @abstractmethod
    async def step_in(self, session_id: str) -> None:
        raise NotImplementedError

    @abstractmethod
    async def continue_execution(self, session_id: str) -> None:
        raise NotImplementedError

    # ----------------------------
    # Filesystem / Workspace utilities
    # ----------------------------
    def _resolve_path(self, session: SessionInfo, path: Union[str, pathlib.Path]) -> pathlib.Path:
        p = pathlib.Path(path)
        if p.is_absolute():
            # prefer workspace root enforcement
            try:
                # disallow navigating outside workspace
                resolved = p.resolve()
                if str(self.config.workspace_root.resolve()) not in str(resolved):
                    raise SessionError("Access to path outside workspace denied")
            except Exception:
                raise SessionError("Invalid path")
            return p
        else:
            return (session.workspace_path / p).resolve()

    async def list_files(self, session_id: str, path: Union[str, pathlib.Path] = ".") -> List[Dict[str, Any]]:
        session = self._get_session(session_id)
        target = self._resolve_path(session, path)
        if not target.exists():
            return []
        entries = []
        for entry in sorted(target.iterdir(), key=lambda p: p.name):
            stat = entry.stat()
            entries.append({
                "name": entry.name,
                "path": str(entry),
                "is_dir": entry.is_dir(),
                "size": stat.st_size,
                "mtime": stat.st_mtime,
            })
        return entries

    async def read_file(self, session_id: str, path: Union[str, pathlib.Path]) -> str:
        session = self._get_session(session_id)
        target = self._resolve_path(session, path)
        if not target.exists():
            raise FileNotFoundError(str(target))
        return target.read_text(encoding="utf-8")

    async def write_file(self, session_id: str, path: Union[str, pathlib.Path], content: str, overwrite: bool = True) -> None:
        session = self._get_session(session_id)
        target = self._resolve_path(session, path)
        if target.exists() and not overwrite:
            raise FileExistsError(str(target))
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
        await self._emit_event("file.saved", {"session_id": session_id, "path": str(target)})
        # plugin hook
        await self._run_plugins(PluginHookType.POST_SAVE, session=session, path=str(target))

    async def delete_file(self, session_id: str, path: Union[str, pathlib.Path]) -> None:
        session = self._get_session(session_id)
        target = self._resolve_path(session, path)
        if target.is_dir():
            for x in target.iterdir():
                if x.is_dir():
                    raise BackendError("Refusing to recursively delete directory without explicit request")
            target.rmdir()
        else:
            target.unlink()
        await self._emit_event("file.deleted", {"session_id": session_id, "path": str(target)})

    async def snapshot_workspace(self, session_id: str) -> str:
        """
        Create a lightweight snapshot (tarball path) of the workspace. Returns snapshot path.
        """
        session = self._get_session(session_id)
        tpath = self.config.tmp_dir / f"snapshot_{session.session_id}_{int(time.time())}.tar.gz"
        cmd = f"tar -czf {shlex.quote(str(tpath))} -C {shlex.quote(str(session.workspace_path))} ."
        logger.debug("Creating snapshot with command: %s", cmd)
        proc = await asyncio.create_subprocess_shell(cmd)
        await proc.wait()
        if proc.returncode != 0:
            raise BackendError("Snapshot failed")
        return str(tpath)

    async def restore_snapshot(self, session_id: str, snapshot_path: Union[str, pathlib.Path]) -> None:
        session = self._get_session(session_id)
        sp = pathlib.Path(snapshot_path)
        if not sp.exists():
            raise FileNotFoundError(str(sp))
        # overwrite
        cmd = f"tar -xzf {shlex.quote(str(sp))} -C {shlex.quote(str(session.workspace_path))}"
        logger.debug("Restoring snapshot with command: %s", cmd)
        proc = await asyncio.create_subprocess_shell(cmd)
        await proc.wait()
        if proc.returncode != 0:
            raise BackendError("Restore snapshot failed")

    # ----------------------------
    # Plot handling pipeline
    # ----------------------------
    async def export_plot(self, session_id: str, plot_command: str, fmt: str = "png") -> pathlib.Path:
        """
        Run an inline plotting command (plot_command) that writes a file to the plot export directory and
        returns the file path. Backend implementations should ensure the engine writes files to self.config.plot_export_dir
        with unique names.
        """
        session = self._get_session(session_id)
        plot_dir = session.workspace_path / self.config.plot_export_dir.relative_to(self.config.workspace_root)
        plot_dir.mkdir(parents=True, exist_ok=True)
        file_name = f"plot_{session.session_id}_{int(time.time() * 1000)}.{fmt}"
        target_file = plot_dir / file_name
        # call engine with wrapper code that saves the current figure
        wrapper = self._wrap_plot_save_command(target_file, fmt, plot_command)
        res = await self.run_code(session_id, wrapper, timeout=60)
        if not res.success:
            raise EngineError("Plot export failed: " + res.stderr)
        return target_file

    def _wrap_plot_save_command(self, target_file: pathlib.Path, fmt: str, user_cmd: str) -> str:
        """
        Return a snippet that the engine understands to run plotting commands and save them
        with deterministic path. Keep this generic; concrete engines may override formatting.
        """
        # Example for Octave/MATLAB: user runs plotting commands, then call print(...)
        # We'll return a wrapper that executes user_cmd then prints save path to stdout for detection.
        save_path = str(target_file)
        code = (
            f"% user plotting commands\n"
            f"{user_cmd}\n"
            f"try\n"
            f"  print('-d{fmt}', '{save_path}');\n"
            f"  disp('::SAVED::{save_path}');\n"
            f"catch err\n"
            f"  disp('::PLOT_ERROR::');\n"
            f"  disp(err.message);\n"
            f"end\n"
        )
        return code

    async def get_plotly_from_workspace(self, session_id: str, varname_x: str, varname_y: str) -> Dict[str, Any]:
        """
        Utility to convert workspace arrays to Plotly JSON. Implementation needs to fetch variable arrays
        and convert to simple Python lists / dicts.
        """
        session = self._get_session(session_id)
        # naive implementation: call a small engine wrapper to jsonencode the data
        code = (
            f"try\n"
            f"  xjson = jsonencode({varname_x});\n"
            f"  yjson = jsonencode({varname_y});\n"
            f"  disp(['::PLOTLY::', xjson, '|||', yjson]);\n"
            f"catch err\n"
            f"  disp('::PLOTLY_ERROR::');\n"
            f"  disp(err.message);\n"
            f"end\n"
        )
        res = await self.run_code(session_id, code, timeout=10)
        if not res.success:
            raise EngineError("Failed to construct plotly data: " + res.stderr)
        out = res.stdout.strip()
        if "::PLOTLY::" not in out:
            raise EngineError("Unexpected plotly wrapper output: " + out)
        payload = out.split("::PLOTLY::", 1)[1]
        xjson, yjson = payload.split("|||", 1)
        return {"x": json.loads(xjson), "y": json.loads(yjson)}

    # ----------------------------
    # Collaboration primitives
    # ----------------------------
    async def create_collab_room(self, room_name: str, owner_session: str, shared_workspace: Optional[pathlib.Path] = None) -> str:
        """
        Create a collaboration room mapped to a container or a persisted shared workspace path.
        Returns room id.
        """
        room_id = str(uuid.uuid4())
        # for now, store as a session-like metadata object in sessions (lightweight)
        room_meta = SessionInfo(
            session_id=room_id,
            username=f"room:{room_name}",
            started_at=time.time(),
            container_id=None,
            engine_type=self.config.default_engine,
            workspace_path=(shared_workspace or (self.config.workspace_root / "shared" / room_name)).resolve(),
            is_shared=True,
        )
        # ensure path
        os.makedirs(room_meta.workspace_path, exist_ok=True)
        self.sessions[room_id] = room_meta
        logger.info("Created collaboration room %s (owner=%s) at %s", room_name, owner_session, room_meta.workspace_path)
        return room_id

    async def join_collab_room(self, room_id: str, username: str) -> SessionInfo:
        room = self.sessions.get(room_id)
        if not room or not room.is_shared:
            raise CollaborationError("Room not found or not shared")
        # create ephemeral session that points to the same container/workspace
        s = await self.create_session(username=username, engine=room.engine_type, workspace_subpath=None, is_shared=True)
        # assign same workspace and container (simple approach; more robust approach uses mapping)
        s.workspace_path = room.workspace_path
        s.container_id = room.container_id
        s.is_shared = True
        logger.info("User %s joined room %s", username, room_id)
        return s

    async def leave_collab_room(self, session_id: str) -> None:
        # if session is ephemeral, destroy but do not delete shared workspace
        session = self.sessions.get(session_id)
        if not session:
            return
        if session.is_shared:
            await self.stop_session(session_id)
            logger.info("Left collab room session %s", session_id)

    async def lock_resource(self, session_id: str, resource: str, timeout: Optional[float] = 10.0) -> bool:
        """
        Acquire a lock for a resource (e.g., file) within the workspace. Returns True on success.
        """
        # naive in-memory lock using session.locks array + per-resource lock dictionary
        key = f"lock:{resource}"
        async with self.global_lock:
            for s in self.sessions.values():
                if key in s.locks:
                    return False
            # claim for current session
            self.sessions[session_id].locks.append(key)
            return True

    async def unlock_resource(self, session_id: str, resource: str) -> None:
        key = f"lock:{resource}"
        async with self.global_lock:
            if key in self.sessions[session_id].locks:
                self.sessions[session_id].locks.remove(key)

    # ----------------------------
    # Plugin system
    # ----------------------------
    async def register_plugin(self, hook: PluginHookType, coro: Callable[..., Coroutine[Any, Any, Any]]) -> None:
        self.plugin_hooks.setdefault(hook, []).append(coro)
        logger.debug("Registered plugin hook %s -> %s", hook, coro)

    async def _run_plugins(self, hook: PluginHookType, *args, **kwargs) -> None:
        coros = self.plugin_hooks.get(hook, [])
        for c in coros:
            try:
                await c(*args, **kwargs)
            except Exception:
                logger.exception("Plugin %s failed", c)

    # ----------------------------
    # Utilities & helpers
    # ----------------------------
    async def _emit_event(self, event_type: str, payload: Dict[str, Any]) -> None:
        await self.event_queue.put(BackendEvent(event_type=event_type, payload=payload))

    def _get_session(self, session_id: str) -> SessionInfo:
        session = self.sessions.get(session_id)
        if not session:
            raise SessionError("Unknown session id")
        return session

    def _variable_info_to_dict(self, v: VariableInfo) -> Dict[str, Any]:
        return {"name": v.name, "dtype": v.dtype, "shape": v.shape, "value_preview": v.value_preview}

    # ----------------------------
    # Docker / K8s helpers (default implementations)
    # ----------------------------
    async def generate_dockerfile(self, base_image: Optional[str] = None, extras: Optional[List[str]] = None) -> str:
        base = base_image or self.config.docker_image
        extras = extras or []
        lines = [
            f"FROM {base}",
            "ENV DEBIAN_FRONTEND=noninteractive",
            "RUN apt-get update && apt-get install -y git wget build-essential python3 python3-pip",
            # keep minimal; user may customize to install octave, matlab runtime, etc.
        ]
        for e in extras:
            lines.append(f"RUN {e}")
        return "\n".join(lines)

    async def build_image_cli(self, tag: str, dockerfile_content: str) -> str:
        """
        Write dockerfile content to tmp and call docker build. Returns image id/tag on success.
        Note: this uses the local docker CLI; in production you'd use a proper Docker SDK or a builder.
        """
        tmpdir = pathlib.Path(self.config.tmp_dir) / f"docker_build_{int(time.time()*1000)}"
        tmpdir.mkdir(parents=True, exist_ok=True)
        df = tmpdir / "Dockerfile"
        df.write_text(dockerfile_content, encoding="utf-8")
        cmd = f"docker build -t {shlex.quote(tag)} {shlex.quote(str(tmpdir))}"
        logger.info("Building docker image: %s", cmd)
        proc = await asyncio.create_subprocess_shell(cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
        stdout, stderr = await proc.communicate()
        logger.debug("Docker build stdout: %s", stdout.decode(errors="ignore"))
        if proc.returncode != 0:
            raise BackendError(f"Docker build failed: {stderr.decode(errors='ignore')}")
        return tag

    async def generate_k8s_manifest(self, image: str, replicas: int = 1) -> Dict[str, Any]:
        # minimal manifest generator for reference
        manifest = {
            "apiVersion": "apps/v1",
            "kind": "Deployment",
            "metadata": {"name": f"ide-backend-{uuid.uuid4().hex[:6]}"},
            "spec": {
                "replicas": replicas,
                "selector": {"matchLabels": {"app": "ide-backend"}},
                "template": {
                    "metadata": {"labels": {"app": "ide-backend"}},
                    "spec": {
                        "containers": [
                            {
                                "name": "ide-backend",
                                "image": image,
                                "ports": [{"containerPort": self.config.port}],
                                "env": [{"name": "WORKSPACE_ROOT", "value": str(self.config.workspace_root)}],
                            }
                        ]
                    },
                },
            },
        }
        return manifest

    # ----------------------------
    # Git / repo helpers
    # ----------------------------
    async def git_init(self, session_id: str) -> None:
        session = self._get_session(session_id)
        cmd = f"git init"
        proc = await asyncio.create_subprocess_shell(cmd, cwd=str(session.workspace_path))
        await proc.wait()
        if proc.returncode != 0:
            raise BackendError("git init failed")
        await self._emit_event("git.init", {"session_id": session_id})

    async def git_commit(self, session_id: str, message: str) -> None:
        session = self._get_session(session_id)
        cmds = [
            "git add -A",
            f"git commit -m {shlex.quote(message)}",
        ]
        for c in cmds:
            proc = await asyncio.create_subprocess_shell(c, cwd=str(session.workspace_path))
            await proc.wait()
            if proc.returncode != 0:
                raise BackendError("git command failed: " + c)

    # ----------------------------
    # Health checks / metrics
    # ----------------------------
    async def health_check(self) -> Dict[str, Any]:
        return {
            "alive": not self.shutdown_flag,
            "sessions": len(self.sessions),
            "metrics": self.metrics,
        }

    # ----------------------------
    # Example helpers to wire a basic local engine via subprocess
    # ----------------------------
    async def _spawn_local_process(self, session: SessionInfo, cmd: str) -> str:
        """
        Spawn a local background process for the session and return a pseudo pid string.
        This is a convenience for local prototypes where you don't want Docker.
        """
        # write a simple shell script that runs the engine in the background, capturing output
        runner = session.workspace_path / f"engine_{session.session_id}.sh"
        runner.write_text(cmd, encoding="utf-8")
        proc = await asyncio.create_subprocess_shell(f"bash {shlex.quote(str(runner))} &", cwd=str(session.workspace_path))
        await proc.wait()
        # this is not a real container id, but a placeholder
        pid_tag = f"localproc:{uuid.uuid4().hex[:8]}"
        logger.debug("Spawned local process for session %s => %s", session.session_id, pid_tag)
        return pid_tag

    # ----------------------------
    # Convenience: register user and create session in single call
    # ----------------------------
    async def register_and_create_session(self, username: str, password: Optional[str] = None, **kwargs) -> SessionInfo:
        # auth hook (if configured, call it)
        if self.config.auth_provider:
            ok = self.config.auth_provider(username, password or "")
            if not ok:
                raise SessionError("Authentication failed")
        return await self.create_session(username, **kwargs)


# ----------------------------
# Minimal concrete example subclass for local Octave via CLI
# ----------------------------
class LocalOctaveBackend(IDEBackend):
    """
    A simple concrete backend that uses the local system Octave CLI for prototyping.
    Implements container/engine lifecycle with process wrappers and uses subprocess to send commands.
    NOTE: This is a simple implementation for local dev and not suitable for production.
    """

    def __init__(self, config: BackendConfig):
        super().__init__(config)
        # store mapping session -> octave process (subprocess.Process)
        self._processes: Dict[str, asyncio.subprocess.Process] = {}
        # per-session stdout buffers (simple)
        self._buffers: Dict[str, List[str]] = {}

    async def _spawn_container_for_session(self, session: SessionInfo) -> Optional[str]:
        if self.config.use_docker:
            # spawn a docker container with mounted workspace; this is a simple CLI invocation
            tag = self.config.docker_image
            container_name = f"ide_{session.session_id}"
            cmd = (
                f"docker run -d --name {shlex.quote(container_name)} -v "
                f"{shlex.quote(str(session.workspace_path))}:/workspace {shlex.quote(tag)} tail -f /dev/null"
            )
            proc = await asyncio.create_subprocess_shell(cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
            stdout, stderr = await proc.communicate()
            if proc.returncode != 0:
                logger.error("Docker run failed: %s", stderr.decode(errors="ignore"))
                raise BackendError("Docker container spawn failed")
            container_id = stdout.decode().strip()
            logger.debug("Spawned docker container %s for session %s", container_id, session.session_id)
            return container_id
        else:
            # spawn a local engine process wrapper and return a pseudo id
            pid_tag = await self._spawn_local_process(session, "exec octave --interactive")
            return pid_tag

    async def _destroy_container_for_session(self, session: SessionInfo) -> None:
        cid = session.container_id
        if not cid:
            return
        if cid.startswith("localproc:"):
            # nothing needed for now
            logger.debug("Destroy local process placeholder %s", cid)
        else:
            # remove container
            cmd = f"docker rm -f {shlex.quote(cid)}"
            proc = await asyncio.create_subprocess_shell(cmd)
            await proc.wait()
            logger.debug("Destroyed docker container %s", cid)

    async def _start_engine(self, session: SessionInfo) -> None:
        # For docker-based setup, exec into container and start an interactive octave process attached to it.
        if self.config.use_docker and session.container_id:
            # start octave detached inside container with socat or similar; for prototype, skip attach
            logger.debug("Assuming octave will be invoked on-demand inside container %s", session.container_id)
            return
        else:
            # launch local subprocess and keep handles for future communication
            proc = await asyncio.create_subprocess_exec(
                "octave", "--interactive", "--quiet",
                stdin=asyncio.subprocess.PIPE, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE,
                cwd=str(session.workspace_path)
            )
            self._processes[session.session_id] = proc
            self._buffers[session.session_id] = []
            asyncio.create_task(self._read_process_output_loop(session.session_id, proc))

    async def _stop_engine(self, session: SessionInfo) -> None:
        proc = self._processes.get(session.session_id)
        if proc:
            proc.terminate()
            try:
                await proc.wait()
            except Exception:
                proc.kill()
            del self._processes[session.session_id]
            logger.debug("Stopped local octave process for session %s", session.session_id)

    async def _read_process_output_loop(self, session_id: str, proc: asyncio.subprocess.Process) -> None:
        assert proc.stdout
        while True:
            line = await proc.stdout.readline()
            if not line:
                break
            s = line.decode(errors="ignore").rstrip("\n")
            self._buffers.setdefault(session_id, []).append(s)
            logger.debug("[octave %s] %s", session_id, s)

    async def _send_to_engine(self, session: SessionInfo, code: str, timeout: Optional[float] = None) -> ExecutionResult:
        """
        A naive implementation that writes a script file and executes octave -qf script.m
        then captures stdout/stderr and attempts to detect saved plot markers and jsonencoded variables.
        """
        script_path = session.workspace_path / f"_run_{int(time.time()*1000)}.m"
        script_path.write_text(code, encoding="utf-8")
        logger.debug("Wrote script to %s", script_path)
        if self.config.use_docker and session.container_id:
            # write file into container workspace and run octave -qf inside container
            container = session.container_id
            dst = f"{container}:{str(script_path)}"
            # using docker cp if file created locally; for prototype assume workspace mounted into container
            cmd = f"docker exec {shlex.quote(container)} octave -qf {shlex.quote(str(script_path))}"
        else:
            cmd = f"octave -qf {shlex.quote(str(script_path))}"
        logger.debug("Executing engine command: %s", cmd)
        proc = await asyncio.create_subprocess_shell(cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE, cwd=str(session.workspace_path))
        stdout_b, stderr_b = await asyncio.wait_for(proc.communicate(), timeout=timeout or 30.0)
        stdout = stdout_b.decode(errors="ignore")
        stderr = stderr_b.decode(errors="ignore")
        success = proc.returncode == 0
        plots = []
        # attempt to extract saved file markers
        for line in stdout.splitlines():
            if "::SAVED::" in line:
                p = line.split("::SAVED::", 1)[1].strip()
                plots.append(pathlib.Path(p))
        # variables fetch is done by another call; we return minimally here
        return ExecutionResult(success=success, stdout=stdout, stderr=stderr, return_code=proc.returncode, duration_s=0.0, plots=plots)

    async def _fetch_variables(self, session: SessionInfo) -> Dict[str, VariableInfo]:
        # naive approach: run octave command to list variables as JSON using jsonencode
        code = (
            "try\n"
            "  vars = whos();\n"
            "  out = struct();\n"
            "  for i=1:length(vars)\n"
            "    v = vars(i);\n"
            "    try\n"
            "      out.(v.name) = struct('class', v.class, 'size', v.size, 'preview', eval(v.name));\n"
            "    catch\n"
            "      out.(v.name) = struct('class', v.class, 'size', v.size, 'preview', '<<unfetchable>>');\n"
            "    end\n"
            "  end\n"
            "  disp(jsonencode(out));\n"
            "catch err\n"
            "  disp('{}');\n"
            "end\n"
        )
        res = await self._send_to_engine(session, code, timeout=10)
        text = res.stdout.strip()
        try:
            decoded = json.loads(text)
        except Exception:
            # fallback to empty
            decoded = {}
        out = {}
        for k, v in decoded.items():
            dtype = v.get("class", "unknown")
            size = v.get("size", None)
            preview = v.get("preview", None)
            # try to reduce previews
            if isinstance(preview, list) and len(preview) > 20:
                preview = preview[:20]
            out[k] = VariableInfo(name=k, dtype=dtype, shape=tuple(size) if isinstance(size, list) else None, value_preview=preview)
        return out

    async def _set_breakpoint(self, session: SessionInfo, filename: str, line: int) -> None:
        # Octave CLI debug approach: using keyboard commands is hard; for prototype, write a wrapper marker
        logger.warning("Breakpoint support in LocalOctaveBackend is rudimentary; implement full debugger for production")
        # store breakpoints in session metadata
        session.metadata.setdefault("breakpoints", []).append({"file": filename, "line": line})

    async def _remove_breakpoint(self, session: SessionInfo, filename: str, line: int) -> None:
        bps = session.metadata.get("breakpoints", [])
        session.metadata["breakpoints"] = [b for b in bps if not (b["file"] == filename and b["line"] == line)]

    async def step_over(self, session_id: str) -> None:
        raise DebuggerError("Step over not implemented for LocalOctaveBackend")

    async def step_in(self, session_id: str) -> None:
        raise DebuggerError("Step in not implemented for LocalOctaveBackend")

    async def continue_execution(self, session_id: str) -> None:
        raise DebuggerError("Continue not implemented for LocalOctaveBackend")


# ----------------------------
# Example usage snippet (non-blocking; integrate in an async app)
# ----------------------------
async def _example_run():
    cfg = BackendConfig(workspace_root=pathlib.Path("./workspaces"), use_docker=False, docker_image="octave:latest")
    backend = LocalOctaveBackend(cfg)
    await backend.start()
    session = await backend.register_and_create_session("alice")
    # write a simple script and run
    await backend.write_file(session.session_id, "hello.m", "x = 1:10; y = sin(x); plot(x,y); print('-dpng','plots/hello.png');")
    res = await backend.run_script_file(session.session_id, session.workspace_path / "hello.m", timeout=20)
    print("Run output:", res.stdout[:400])
    # fetch variables
    vars = await backend._fetch_variables(session)
    print("Variables:", {k: v.dtype for k, v in vars.items()})
    await backend.stop_session(session.session_id)
    await backend.stop()

# If you want to test the example, run it in an asyncio loop:
import asyncio
asyncio.run(_example_run())
