"""
main.py

UniLabCore: Concrete Python3 backend implementing an Octave/MATLAB-like
engine and workspace manager suitable as the base for a browser IDE.

Features:
- Async session lifecycle (create/stop sessions)
- Local Octave execution (subprocess) and optional Docker-backed sessions
- Run code/snippets and scripts, return structured ExecutionResult
- Fetch workspace variables via jsonencode (best-effort conversion)
- Plot export wrapper (save PNG/PDF from Octave into workspace)
- File and workspace utilities (read/write/list/delete/snapshot/restore)
- Collaboration rooms, locks, and session joining
- Plugin hooks & event queue
- Minimal debugger stubs (breakpoint bookkeeping)
- Git helpers, Dockerfile/K8s manifest generators
- Health checks & basic metrics

Usage (example at bottom): run this in an `asyncio` loop. For production,
adapt engine spawning to Docker SDK, secure session auth, enforce resource limits.
"""

from __future__ import annotations
import asyncio
import json
import shlex
import time
import uuid
import tempfile
import logging
import pathlib
import os
import stat
import subprocess
import shutil
import platform
import subprocess as _subprocess
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Tuple, Callable, Union

logger = logging.getLogger("UniLabCore")
logger.setLevel(logging.DEBUG)
# attach simple handler if no handlers exist
if not logger.handlers:
    ch = logging.StreamHandler()
    ch.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
    logger.addHandler(ch)


# ---------------------------
# Data classes & helper types
# ---------------------------
@dataclass
class BackendConfig:
    workspace_root: pathlib.Path = pathlib.Path("./workspaces")
    use_docker: bool = False
    docker_image: str = "octave:latest"
    port: int = 8000
    plot_export_dirname: str = "plots"
    tmp_dir: pathlib.Path = pathlib.Path(tempfile.gettempdir())
    max_sessions: int = 16
    default_username: str = "user"
    metrics_enabled: bool = True
    auth_check: Optional[Callable[[str, Optional[str]], bool]] = None  # simple auth hook
    octave_cmd: Optional[str] = None

@dataclass
class SessionInfo:
    session_id: str
    username: str
    engine: str  # e.g., "octave" or "matlab"
    started_at: float
    workspace_path: pathlib.Path
    container_id: Optional[str] = None  # docker container id if used
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


# ---------------------------
# UniLabCore
# ---------------------------
class UniLabCore:
    """
    Concrete core backend for UniLab.

    This class is designed to be a "drop-in" base backend: it manages sessions,
    runs Octave code via subprocess or inside optional docker containers, and
    provides a rich API for the front-end code editor / workspace / plots.
    """

    def __init__(self, config: Optional[BackendConfig] = None):
        self.config = config or BackendConfig()
        # Ensure workspace root exists
        self.config.workspace_root.mkdir(parents=True, exist_ok=True)
        # Active sessions: session_id -> SessionInfo
        self.sessions: Dict[str, SessionInfo] = {}
        # Per-session engine processes (local prototyping)
        self._process_map: Dict[str, asyncio.subprocess.Process] = {}
        # In-memory stdout buffers (per session)
        self._stdout_buffers: Dict[str, List[str]] = {}
        # Locks per session for concurrency control
        self._locks: Dict[str, asyncio.Lock] = {}
        # Event queue & plugin hooks (async)
        self._event_queue: asyncio.Queue = asyncio.Queue()
        self._plugin_hooks: Dict[str, List[Callable[..., Any]]] = {}
        # Simple collaboration room store: room_id -> SessionInfo (shared workspace)
        self._rooms: Dict[str, SessionInfo] = {}
        # Global metrics
        self._metrics: Dict[str, Any] = {"runs": 0, "errors": 0, "sessions_created": 0, "start_time": time.time()}
        # Flag for shutdown
        self._shutdown = False
        # Background tasks
        self._bg_tasks: List[asyncio.Task] = []
        logger.info("UniLabCore initialized with workspace root: %s", str(self.config.workspace_root))

    # -------------------------
    # Lifecycle and background
    # -------------------------
    async def start(self) -> None:
        """Start background workers (event pump, heartbeat)."""
        logger.debug("Starting UniLabCore background tasks")
        self._bg_tasks.append(asyncio.create_task(self._event_pump()))
        self._bg_tasks.append(asyncio.create_task(self._heartbeat()))

    async def stop(self) -> None:
        """Stop all sessions and background tasks."""
        self._shutdown = True
        for sid in list(self.sessions.keys()):
            try:
                await self.stop_session(sid)
            except Exception:
                logger.exception("Error stopping session %s", sid)
        # cancel background tasks
        for t in self._bg_tasks:
            t.cancel()
        logger.info("UniLabCore stopped")

    async def _heartbeat(self) -> None:
        while not self._shutdown:
            await asyncio.sleep(10)
            uptime = time.time() - self._metrics["start_time"]
            logger.debug("Heartbeat: sessions=%d, uptime=%.1fs, runs=%d", len(self.sessions), uptime, self._metrics["runs"])

    async def _event_pump(self) -> None:
        while not self._shutdown:
            try:
                ev = await self._event_queue.get()
                # Run hooks
                for name, hooks in self._plugin_hooks.items():
                    for hook in hooks:
                        try:
                            # If hook is coroutine, schedule it
                            if asyncio.iscoroutinefunction(hook):
                                asyncio.create_task(hook(ev))
                            else:
                                hook(ev)
                        except Exception:
                            logger.exception("Plugin hook failed: %s", hook)
            except asyncio.CancelledError:
                break
            except Exception:
                logger.exception("Event pump error")

    async def _emit_event(self, ev_type: str, payload: Dict[str, Any]) -> None:
        await self._event_queue.put({"type": ev_type, "payload": payload, "ts": time.time()})

    def register_hook(self, name: str, func: Callable[..., Any]) -> None:
        self._plugin_hooks.setdefault(name, []).append(func)
        logger.debug("Registered hook %s -> %s", name, func)

    # -------------------------
    # Session management
    # -------------------------
    async def create_session(self, username: Optional[str] = None, engine: str = "octave", shared_workspace: Optional[pathlib.Path] = None, use_docker: Optional[bool] = None) -> SessionInfo:
        username = username or self.config.default_username
        use_docker = self.config.use_docker if use_docker is None else use_docker
        session_id = str(uuid.uuid4())
        if shared_workspace:
            workspace = shared_workspace.resolve()
            workspace.mkdir(parents=True, exist_ok=True)
        else:
            workspace = (self.config.workspace_root / f"{username}_{session_id}").resolve()
            workspace.mkdir(parents=True, exist_ok=True)
        s = SessionInfo(
            session_id=session_id,
            username=username,
            engine=engine,
            started_at=time.time(),
            workspace_path=workspace,
            container_id=None,
            is_shared=bool(shared_workspace),
        )
        self.sessions[session_id] = s
        self._locks[session_id] = asyncio.Lock()
        self._stdout_buffers[session_id] = []
        self._metrics["sessions_created"] += 1
        logger.info("Created session %s (user=%s, engine=%s, docker=%s)", session_id, username, engine, use_docker)

        # spawn engine: for local (non-docker) sessions, start a persistent Octave process
        try:
            if use_docker:
                cid = await self._spawn_docker_for_session(s)
                s.container_id = cid
            else:
                await self._start_persistent_octave(s)
        except Exception:
            logger.exception("Failed to spawn engine for session %s", session_id)
            await self.stop_session(session_id)
            raise
        await self._emit_event("session.created", {"session_id": session_id, "username": username})
        return s
    
    async def _start_persistent_octave(self, session: SessionInfo) -> None:
        """
        Start a persistent interactive Octave process for the session.

        Robust behaviour:
        - Use self._find_octave_executable() to locate an executable.
        - If that process exits right away (launcher like octave-launch.exe), search the install
            folder for likely persistent binaries (octave-cli.exe, octave.exe) and restart with one of them.
        - Use creationflags on Windows to avoid extra console windows.
        """
        try:
            octave_exe = self._find_octave_executable()
        except Exception as e:
            logger.exception("Could not locate Octave executable: %s", e)
            raise

        def _try_start(exe_path: str):
            """Helper to synchronously call create_subprocess_exec (returns coroutine)."""
            args = [exe_path, "--interactive", "--quiet", "--no-init-file"]
            creationflags = 0
            try:
                if platform.system().lower().startswith("win"):
                    creationflags = _subprocess.CREATE_NO_WINDOW
            except Exception:
                creationflags = 0
            return asyncio.create_subprocess_exec(
                *args,
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.STDOUT,
                cwd=str(session.workspace_path),
                creationflags=creationflags if creationflags else 0
            )

        # 1) Try start the executable we found
        try:
            proc = await _try_start(octave_exe)
        except FileNotFoundError as e:
            logger.exception("Octave binary not found at '%s': %s", octave_exe, e)
            raise BackendError(f"Failed to start Octave process: {e}")
        except Exception as e:
            logger.exception("Failed to spawn Octave at '%s': %s", octave_exe, e)
            raise BackendError(f"Failed to spawn Octave process: {e}")

        # Give it a short moment to initialize; if it exits immediately we'll try alternatives
        await asyncio.sleep(0.15)
        # If the process has already terminated (launcher that spawns child then exits), try to locate real binary
        if getattr(proc, "returncode", None) is not None:
            logger.warning("Octave process started from '%s' exited immediately (probably a launcher). Searching for real binary...", octave_exe)
            # Inspect possible install root(s) relative to the launcher
            exe_path = pathlib.Path(octave_exe)
            candidate_paths = []

            # look under parent dirs for known locations, especially mingw64\bin\octave-cli.exe
            search_roots = list(exe_path.parents)[:4]  # examine up to 4 ancestor dirs
            # add an explicit candidate: parent.joinpath('mingw64','bin')
            for root in search_roots:
                cand_cli = root / "mingw64" / "bin" / "octave-cli.exe"
                cand_oct = root / "mingw64" / "bin" / "octave.exe"
                cand_bin_cli = root / "bin" / "octave-cli.exe"
                cand_bin_oct = root / "bin" / "octave.exe"
                candidate_paths += [cand_cli, cand_oct, cand_bin_cli, cand_bin_oct]

            # also search for any octave*.exe under the top-level install root (limited rglob)
            top = exe_path.parents[0] if exe_path.parents else exe_path
            try:
                for p in top.rglob("octave*.exe"):
                    candidate_paths.append(p)
            except Exception:
                pass

            # dedupe and keep only existing
            candidates = []
            seen = set()
            for p in candidate_paths:
                try:
                    s = str(p)
                except Exception:
                    continue
                if s in seen:
                    continue
                seen.add(s)
                if pathlib.Path(s).exists():
                    candidates.append(s)

            # If we found candidates, try them in order
            started = False
            for cand in candidates:
                logger.info("Trying alternative Octave binary: %s", cand)
                try:
                    proc2 = await _try_start(cand)
                except Exception:
                    logger.exception("Failed to spawn candidate %s", cand)
                    continue
                await asyncio.sleep(0.12)
                if getattr(proc2, "returncode", None) is None:
                    # success: persistent process running
                    proc = proc2
                    octave_exe = cand
                    started = True
                    logger.info("Started persistent Octave using candidate '%s'", cand)
                    break
                else:
                    # candidate exited immediately too
                    logger.warning("Candidate '%s' also exited immediately", cand)
                    try:
                        proc2.terminate()
                    except Exception:
                        pass

            if not started:
                # no persistent binary found
                raise BackendError(
                    "Could not find a persistent Octave binary (octave-cli.exe/octave.exe). "
                    "The launcher you pointed at exits immediately. Please set BackendConfig.octave_cmd "
                    "to the full path of the real Octave CLI executable (e.g. ...\\mingw64\\bin\\octave-cli.exe)."
                )

        # record running process and start stdout reader
        self._process_map[session.session_id] = proc
        self._stdout_buffers[session.session_id] = []
        asyncio.create_task(self._read_process_output_loop(session.session_id, proc))
        logger.info("Started persistent Octave for session %s using executable '%s'", session.session_id, str(octave_exe))
        # short pause to let Octave initialize its prompt
        await asyncio.sleep(0.08)


    async def _read_process_output_loop(self, session_id: str, proc: asyncio.subprocess.Process) -> None:
        """
        Read stdout lines from the persistent process and append to buffer.
        This lets run_code wait for completion markers.
        """
        assert proc.stdout is not None
        buffer = self._stdout_buffers.setdefault(session_id, [])
        try:
            while True:
                line = await proc.stdout.readline()
                if not line:
                    break
                text = line.decode(errors="ignore").rstrip("\n")
                buffer.append(text)
                logger.debug("[octave %s] %s", session_id, text)
        except asyncio.CancelledError:
            return
        except Exception:
            logger.exception("Persistent process stdout reader failed for session %s", session_id)


    async def stop_session(self, session_id: str) -> None:
        s = self.sessions.get(session_id)
        if not s:
            logger.debug("stop_session: unknown session %s", session_id)
            return
        proc = self._process_map.get(session_id)
        if proc:
            try:
                proc.terminate()
                await asyncio.wait_for(proc.wait(), timeout=3.0)
            except Exception:
                try:
                    proc.kill()
                except Exception:
                    pass
            self._process_map.pop(session_id, None)
        if s.container_id and not s.container_id.startswith("local:"):
            try:
                await self._docker_rm(s.container_id)
            except Exception:
                logger.exception("Failed to remove docker container %s", s.container_id)
        self._locks.pop(session_id, None)
        self._stdout_buffers.pop(session_id, None)
        self.sessions.pop(session_id, None)
        await self._emit_event("session.stopped", {"session_id": session_id})
        logger.info("Stopped session %s", session_id)

    # -------------------------
    # Engine / Docker helpers
    # -------------------------
    async def _spawn_docker_for_session(self, session: SessionInfo) -> str:
        """
        Lightweight docker run -d prototype. Mounts the workspace into /workspace in container.
        Returns container id (stdout from docker run).
        """
        image = self.config.docker_image
        cname = f"unilab_{session.session_id}"
        workspace = str(session.workspace_path)
        cmd = f"docker run -d --name {shlex.quote(cname)} -v {shlex.quote(workspace)}:/workspace {shlex.quote(image)} tail -f /dev/null"
        logger.debug("Running docker spawn cmd: %s", cmd)
        proc = await asyncio.create_subprocess_shell(cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
        out, err = await proc.communicate()
        if proc.returncode != 0:
            raise RuntimeError(f"docker run failed: {err.decode(errors='ignore')}")
        cid = out.decode().strip()
        logger.info("Spawned docker container %s for session %s", cid, session.session_id)
        return cid

    async def _docker_exec(self, container_id: str, cmd: str, cwd: Optional[str] = None, timeout: Optional[float] = None) -> Tuple[int, str, str]:
        """
        Run 'docker exec <container> sh -lc "<cmd>"' and return (rc, stdout, stderr).
        """
        if cwd:
            # ensure to cd into workspace path inside container
            cmd = f"cd {shlex.quote(cwd)} && {cmd}"
        full = f"docker exec {shlex.quote(container_id)} sh -lc {shlex.quote(cmd)}"
        logger.debug("docker exec: %s", full)
        proc = await asyncio.create_subprocess_shell(full, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
        try:
            out, err = await asyncio.wait_for(proc.communicate(), timeout=timeout or 30.0)
        except asyncio.TimeoutError:
            proc.kill()
            out, err = await proc.communicate()
            return -1, out.decode(errors="ignore"), err.decode(errors="ignore")
        return proc.returncode, out.decode(errors="ignore"), err.decode(errors="ignore")

    async def _docker_rm(self, container_id: str) -> None:
        cmd = f"docker rm -f {shlex.quote(container_id)}"
        proc = await asyncio.create_subprocess_shell(cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
        await proc.communicate()
        logger.debug("docker rm executed for %s", container_id)

    # -------------------------
    # Running code & scripts
    # -------------------------
    async def run_code(self, session_id: str, code: str, timeout: Optional[float] = 30.0) -> ExecutionResult:
        """
        Robust run_code for persistent Octave process:
        - Writes script to workspace
        - Uses persistent process (if present) and sends a wrapper that prints start/end markers
        - Uses POSIX path for `source()`
        - Collects all stdout lines until marker or timeout
        - Returns ExecutionResult with stdout containing collected lines
        """
        session = self._get_session(session_id)
        async with self._locks[session_id]:
            start_ts = time.time()
            script_name = f"_run_{int(start_ts*1000)}.m"
            script_path = session.workspace_path / script_name
            script_path.write_text(code, encoding="utf-8")
            plots: List[str] = []
            rc = 0
            collected_lines: List[str] = []
            out_text = ""
            err_text = ""

            proc = self._process_map.get(session_id)
            if proc and proc.stdin:
                # Use POSIX style path (forward slashes) so Octave interprets it reliably on Windows
                script_posix = script_path.as_posix().replace("'", "''")
                marker = f"__UNILAB_DONE_{uuid.uuid4().hex}__"
                start_marker = f"::UNILAB::START::{marker}"
                end_marker = f"::UNILAB::END::{marker}"

                # Build wrapper: print start marker, run source, catch errors printing ::ERR::, print end marker
                wrapper = (
                    f"disp('{start_marker}');\n"
                    f"try\n"
                    f"  source('{script_posix}');\n"
                    f"catch err\n"
                    f"  disp(['::ERR::', err.message]);\n"
                    f"end\n"
                    f"disp('{end_marker}');\n"
                )

                logger.debug("Sending to persistent octave: %s", wrapper.replace("\n", " ; "))

                # clear any stale buffer items before sending
                buf = self._stdout_buffers.setdefault(session_id, [])
                # drop existing buffer contents (but capture them to logs)
                if buf:
                    logger.debug("Dropping %d stale lines from buffer before sending", len(buf))
                    collected_lines.extend(buf.copy())
                    buf.clear()

                # send wrapper to process stdin
                try:
                    proc.stdin.write(wrapper.encode())
                    await proc.stdin.drain()
                except Exception as e:
                    logger.exception("Failed to write to persistent process stdin: %s", e)
                    raise EngineError("Failed to send command to persistent engine: " + str(e))

                # wait for end marker
                deadline = time.time() + (timeout or 30.0)
                seen_end = False
                while time.time() < deadline:
                    # consume buffer
                    while buf:
                        line = buf.pop(0)
                        collected_lines.append(line)
                        # log for diagnostics
                        logger.debug("[octave-out] %s", line)
                        if end_marker in line:
                            seen_end = True
                            break
                    if seen_end:
                        break
                    await asyncio.sleep(0.05)

                out_text = "\n".join(collected_lines)
                # collect plot markers
                for line in collected_lines:
                    if "::SAVED::" in line:
                        p = line.split("::SAVED::", 1)[1].strip()
                        plots.append(p)
                # detect errors
                rc = 0 if not any(l.startswith("::ERR::") for l in collected_lines) else 1
                success = (rc == 0)
                duration = time.time() - start_ts
                # fetch variables snapshot after run
                vars_snapshot = {}
                try:
                    vars_snapshot = await self._fetch_variables(session_id)
                except Exception:
                    logger.exception("Failed to fetch variables snapshot after run")
                result = ExecutionResult(success=success, stdout=out_text, stderr=err_text, return_code=rc, duration_s=duration, variables_snapshot=vars_snapshot, plots=plots)
                # emit event & metrics
                self._metrics["runs"] += 1
                await self._emit_event("code.ran", {"session_id": session_id, "success": success, "duration": duration})
                return result

            else:
                # No persistent proc: fallback to previous behavior (ephemeral process)
                # Keep your existing fallback implementation here (unchanged)
                # For brevity, call the old fallback method if you have it, else implement ephemeral run.
                # Example ephemeral run:
                proc2 = await asyncio.create_subprocess_shell(f"octave -qf {shlex.quote(str(script_path))}",
                                                            stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE,
                                                            cwd=str(session.workspace_path))
                try:
                    out_b, err_b = await asyncio.wait_for(proc2.communicate(), timeout=timeout or 30.0)
                except asyncio.TimeoutError:
                    proc2.kill()
                    out_b, err_b = await proc2.communicate()
                rc = proc2.returncode
                out_text = out_b.decode(errors="ignore")
                err_text = err_b.decode(errors="ignore")
                duration = time.time() - start_ts
                vars_snapshot = {}
                try:
                    vars_snapshot = await self._fetch_variables(session_id)
                except Exception:
                    logger.exception("Fallback: could not fetch variables")
                result = ExecutionResult(success=(rc == 0), stdout=out_text, stderr=err_text, return_code=rc, duration_s=duration, variables_snapshot=vars_snapshot, plots=plots)
                self._metrics["runs"] += 1
                await self._emit_event("code.ran", {"session_id": session_id, "success": (rc == 0), "duration": duration})
                return result


    async def run_script_file(self, session_id: str, filepath: Union[str, pathlib.Path], timeout: Optional[float] = 30.0) -> ExecutionResult:
        path = pathlib.Path(filepath)
        if not path.is_absolute():
            session = self._get_session(session_id)
            path = (session.workspace_path / path).resolve()
        if not path.exists():
            raise FileNotFoundError(str(path))
        code = path.read_text(encoding="utf-8")
        return await self.run_code(session_id, code, timeout=timeout)

    # -------------------------
    # Variables & workspace
    # -------------------------
    async def _fetch_variables(self, session_id: str) -> Dict[str, Any]:
        """
        Ask Octave to jsonencode all variables using a helper script. Because Octave
        sometimes can't jsonencode complex objects, we use try/catch and fetch best-effort values.
        """
        session = self._get_session(session_id)
        wrapper = (
            "try\n"
            "  vars = whos();\n"
            "  out = struct();\n"
            "  for i=1:length(vars)\n"
            "    v = vars(i);\n"
            "    name = v.name;\n"
            "    try\n"
            "      val = eval(name);\n"
            "      out.(name) = struct('class', v.class, 'size', v.size, 'value', val);\n"
            "    catch\n"
            "      out.(name) = struct('class', v.class, 'size', v.size, 'value', '<<unfetchable>>');\n"
            "    end\n"
            "  end\n"
            "  disp(['::VARS::', jsonencode(out)]);\n"
            "catch err\n"
            "  disp('::VARS::{}');\n"
            "end\n"
        )
        res = await self.run_code(session_id, wrapper, timeout=10.0)
        if not res.success and not res.stdout:
            return {}
        out = res.stdout
        idx = out.find("::VARS::")
        if idx == -1:
            # attempt to parse entire stdout as json
            try:
                return json.loads(out)
            except Exception:
                return {}
        payload = out[idx + len("::VARS::"):].strip()
        try:
            decoded = json.loads(payload)
        except Exception:
            logger.exception("Could not parse variables payload")
            return {}
        # convert to VariableInfo like dict: name -> VariableInfo
        result = {}
        for k, v in decoded.items():
            cls = v.get("class", "unknown")
            size = v.get("size", None)
            val = v.get("value", None)
            preview = val
            # try to reduce preview size for big arrays
            if isinstance(preview, list) and len(preview) > 50:
                preview = preview[:50]
            shape = tuple(size) if isinstance(size, list) else None
            result[k] = {"name": k, "dtype": cls, "shape": shape, "preview": preview}
        return result

    async def evaluate_expression(self, session_id: str, expr: str) -> Any:
        """
        Evaluate an expression and return a best-effort Python object (via jsonencode).
        """
        # wrap with try/jsonencode
        wrapper = (
            "try\n"
            f"  out = jsonencode({expr});\n"
            "  disp(['::EVAL::', out]);\n"
            "catch err\n"
            "  disp(['::EVAL_ERROR::', err.message]);\n"
            "end\n"
        )
        res = await self.run_code(session_id, wrapper, timeout=10.0)
        if "::EVAL::" in res.stdout:
            payload = res.stdout.split("::EVAL::", 1)[1].strip()
            try:
                return json.loads(payload)
            except Exception:
                return payload
        raise RuntimeError("Expression evaluation failed: " + res.stderr)

    # -------------------------
    # Plot helpers
    # -------------------------

    def _find_octave_executable(self) -> str:
        """
        Resolve the octave executable to use.

        Priority:
        1. self.config.octave_cmd if provided and executable
        2. common names found on PATH (octave, octave-cli, octave.exe, octave-cli.exe)
        3. search common Windows install locations (Program Files, C:\Octave, Program Files (x86))
        4. search a few common Unix locations (if not Windows)

        Raises BackendError with actionable instructions if none found.
        """
        if getattr(self.config, "octave_cmd", None):
            candidate = str(self.config.octave_cmd)
            found = shutil.which(candidate)
            if found:
                logger.debug("Using octave executable from config via PATH: %s -> %s", candidate, found)
                return found
            cand_path = pathlib.Path(candidate)
            if cand_path.exists():
                logger.debug("Using octave executable from config as path: %s", str(cand_path))
                return str(cand_path)
            logger.warning("Configured BackendConfig.octave_cmd not found: %s", candidate)

        candidates = ["octave", "octave-cli", "octave.exe", "octave-cli.exe"]
        for name in candidates:
            found = shutil.which(name)
            if found:
                logger.debug("Found octave executable on PATH: %s -> %s", name, found)
                return found

        sysname = platform.system().lower()
        if sysname.startswith("win"):
            probes = []
            pf = os.environ.get("ProgramFiles")
            pfx86 = os.environ.get("ProgramFiles(x86)")
            probes.extend([p for p in (pf, pfx86, r"C:\Octave") if p])
            probes.extend([r"C:\Program Files", r"C:\Program Files (x86)", r"C:\Programs"])
            seen = set()
            for base in probes:
                if not base:
                    continue
                base_path = pathlib.Path(base)
                if not base_path.exists():
                    continue
                try:
                    for p in base_path.rglob("octave*.exe"):
                        if str(p) in seen:
                            continue
                        seen.add(str(p))
                        logger.debug("Found possible octave exe at: %s", str(p))
                        return str(p)
                except Exception:
                    continue

            common_paths = [
                r"C:\Octave\Octave-*-mingw64\bin\octave-cli.exe",
                r"C:\Octave\Octave-*\bin\octave-cli.exe",
                r"C:\Program Files\GNU Octave\*\bin\octave-cli.exe",
                r"C:\Program Files\GNU Octave\*\bin\octave.exe",
            ]
            for pattern in common_paths:
                try:
                    for match in glob.glob(pattern):
                        if match:
                            logger.debug("Found octave via glob: %s", match)
                            return match
                except Exception:
                    continue

        else:
            # 4) non-Windows fallback probes
            unix_probes = ["/usr/bin", "/usr/local/bin", "/opt/octave/bin"]
            for base in unix_probes:
                try:
                    for p in pathlib.Path(base).glob("octave*"):
                        if p.exists() and os.access(str(p), os.X_OK):
                            logger.debug("Found octave in unix probe: %s", str(p))
                            return str(p)
                except Exception:
                    continue

        # not found: build helpful error
        msg = (
            "Could not find an Octave executable on PATH or in common install locations.\n\n"
            "Options to fix:\n"
            "  1) Install Octave and ensure 'octave' is on PATH. Test in PowerShell/CMD:\n"
            "       where octave\n"
            "       octave --version\n"
            "  2) If Octave is installed but not on PATH, set BackendConfig.octave_cmd to the full path,\n"
            "     e.g. BackendConfig(..., octave_cmd=r'C:\\Octave\\Octave-8.3.0\\mingw64\\bin\\octave-cli.exe')\n"
            "  3) On Windows, common install locations are 'C:\\Octave\\...' or under 'C:\\Program Files\\GNU Octave\\...'\n\n"
            "If you want, paste the output of `where octave` (PowerShell/CMD) or the path where Octave is installed\n"
            "and I will show the exact string to put into BackendConfig.octave_cmd."
        )
        logger.error(msg)
        raise BackendError(msg)


    def _plot_save_snippet(self, target_path: str, fmt: str = "png") -> str:
        """
        Return Octave code that saves current figure and prints a marker for detection.
        """
        fmt_flag = {"png": "png", "pdf": "pdf", "svg": "svg"}.get(fmt, fmt)
        target_escaped = target_path.replace("'", "''")
        code = (
            f"try\n"
            f"  print('-d{fmt_flag}', '{target_escaped}');\n"
            f"  disp('::SAVED::{target_escaped}');\n"
            f"catch err\n"
            f"  disp(['::PLOT_ERROR::', err.message]);\n"
            f"end\n"
        )
        return code

    async def export_plot(self, session_id: str, user_plot_commands: str, fmt: str = "png", timeout: Optional[float] = 30.0) -> str:
        """
        Run user-supplied plotting commands and save the result into the session's plots directory.
        Returns path (string) to saved file within workspace.
        """
        session = self._get_session(session_id)
        plots_dir = session.workspace_path / self.config.plot_export_dirname
        plots_dir.mkdir(parents=True, exist_ok=True)
        fname = f"plot_{session.session_id}_{int(time.time()*1000)}.{fmt}"
        target = plots_dir / fname
        wrapper = user_plot_commands + "\n" + self._plot_save_snippet(str(target), fmt=fmt)
        res = await self.run_code(session_id, wrapper, timeout=timeout)
        if not res.success:
            raise RuntimeError("Plot export failed: " + (res.stderr or res.stdout))
        # verify existence
        if not target.exists():
            logger.warning("Plot expected at %s but file not found locally; returning logical path", str(target))
        return str(target)

    async def get_plotly_json_for_vars(self, session_id: str, x_var: str, y_var: str) -> Dict[str, Any]:
        """
        Convert workspace arrays into JSON for use with Plotly on the front end.
        Implementation: jsonencode the variables and parse them back.
        """
        session = self._get_session(session_id)
        wrapper = (
            "try\n"
            f"  xj = jsonencode({x_var});\n"
            f"  yj = jsonencode({y_var});\n"
            "  disp(['::PLOTLY::', xj, '|||', yj]);\n"
            "catch err\n"
            "  disp(['::PLOTLY_ERROR::', err.message]);\n"
            "end\n"
        )
        res = await self.run_code(session_id, wrapper, timeout=10.0)
        if "::PLOTLY::" not in res.stdout:
            raise RuntimeError("Could not construct plotly payload: " + res.stdout + res.stderr)
        payload = res.stdout.split("::PLOTLY::", 1)[1]
        xjson, yjson = payload.split("|||", 1)
        return {"x": json.loads(xjson), "y": json.loads(yjson)}

    # -------------------------
    # File & workspace utilities
    # -------------------------
    async def list_files(self, session_id: str, path: Optional[Union[str, pathlib.Path]] = None) -> List[Dict[str, Any]]:
        session = self._get_session(session_id)
        base = session.workspace_path if path is None else (session.workspace_path / str(path))
        base = base.resolve()
        if not base.exists():
            return []
        out = []
        for p in sorted(base.iterdir(), key=lambda x: x.name):
            st = p.stat()
            out.append({"name": p.name, "path": str(p.relative_to(session.workspace_path)), "is_dir": p.is_dir(), "size": st.st_size, "mtime": st.st_mtime})
        return out

    async def read_file(self, session_id: str, path: Union[str, pathlib.Path]) -> str:
        session = self._get_session(session_id)
        p = (session.workspace_path / str(path)).resolve()
        if not str(p).startswith(str(session.workspace_path)):
            raise PermissionError("Access outside workspace denied")
        if not p.exists():
            raise FileNotFoundError(str(p))
        return p.read_text(encoding="utf-8")

    async def write_file(self, session_id: str, path: Union[str, pathlib.Path], content: str, overwrite: bool = True) -> None:
        session = self._get_session(session_id)
        p = (session.workspace_path / str(path)).resolve()
        if not str(p).startswith(str(session.workspace_path)):
            raise PermissionError("Access outside workspace denied")
        if p.exists() and not overwrite:
            raise FileExistsError(str(p))
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content, encoding="utf-8")
        await self._emit_event("file.saved", {"session_id": session_id, "path": str(p)})

    async def delete_file(self, session_id: str, path: Union[str, pathlib.Path]) -> None:
        session = self._get_session(session_id)
        p = (session.workspace_path / str(path)).resolve()
        if not str(p).startswith(str(session.workspace_path)):
            raise PermissionError("Access outside workspace denied")
        if p.is_dir():
            # simple safety: only delete empty dirs
            if any(p.iterdir()):
                raise RuntimeError("Directory not empty")
            p.rmdir()
        else:
            p.unlink()
        await self._emit_event("file.deleted", {"session_id": session_id, "path": str(p)})

    async def snapshot_workspace(self, session_id: str) -> str:
        session = self._get_session(session_id)
        out_path = self.config.tmp_dir / f"snapshot_{session.session_id}_{int(time.time())}.tar.gz"
        cmd = f"tar -czf {shlex.quote(str(out_path))} -C {shlex.quote(str(session.workspace_path))} ."
        proc = await asyncio.create_subprocess_shell(cmd)
        await proc.wait()
        if proc.returncode != 0:
            raise RuntimeError("Snapshot failed")
        return str(out_path)

    async def restore_snapshot(self, session_id: str, snapshot_path: Union[str, pathlib.Path]) -> None:
        session = self._get_session(session_id)
        sp = pathlib.Path(snapshot_path)
        if not sp.exists():
            raise FileNotFoundError(str(sp))
        cmd = f"tar -xzf {shlex.quote(str(sp))} -C {shlex.quote(str(session.workspace_path))}"
        proc = await asyncio.create_subprocess_shell(cmd)
        await proc.wait()
        if proc.returncode != 0:
            raise RuntimeError("Restore failed")
        await self._emit_event("workspace.restored", {"session_id": session_id, "snapshot": str(sp)})

    # -------------------------
    # Collaboration primitives
    # -------------------------
    async def create_room(self, room_name: str, owner_session_id: str) -> str:
        owner = self._get_session(owner_session_id)
        room_id = str(uuid.uuid4())
        # create shared workspace directory
        shared_path = (self.config.workspace_root / "shared" / room_name).resolve()
        shared_path.mkdir(parents=True, exist_ok=True)
        room = SessionInfo(session_id=room_id, username=f"room:{room_name}", engine=owner.engine, started_at=time.time(), workspace_path=shared_path, is_shared=True)
        self._rooms[room_id] = room
        logger.info("Created room %s (owner=%s) workspace=%s", room_id, owner_session_id, shared_path)
        return room_id

    async def join_room(self, room_id: str, username: str) -> SessionInfo:
        if room_id not in self._rooms:
            raise RuntimeError("Room not found")
        room = self._rooms[room_id]
        # create ephemeral session that maps to the same workspace (shared)
        s = await self.create_session(username=username, shared_workspace=room.workspace_path)
        # mark as shared and reuse container if present (simple mapping)
        s.is_shared = True
        s.container_id = room.container_id
        logger.info("User %s joined room %s", username, room_id)
        return s

    async def leave_room(self, session_id: str) -> None:
        s = self.sessions.get(session_id)
        if not s:
            return
        if s.is_shared:
            await self.stop_session(session_id)
            logger.info("Session %s left room", session_id)

    # -------------------------
    # Locks
    # -------------------------
    async def lock_resource(self, session_id: str, resource: str, timeout: Optional[float] = 5.0) -> bool:
        """
        Acquire a simple global resource lock. This is naive single-process lock store.
        """
        key = f"lock:{resource}"
        # ensure no other session has claimed it
        async with asyncio.Lock():
            for sid, s in self.sessions.items():
                locks = s.metadata.setdefault("locks", [])
                if key in locks:
                    return False
            # claim for current session
            self.sessions[session_id].metadata.setdefault("locks", []).append(key)
            return True

    async def unlock_resource(self, session_id: str, resource: str) -> None:
        key = f"lock:{resource}"
        s = self.sessions.get(session_id)
        if not s:
            return
        locks = s.metadata.get("locks", [])
        if key in locks:
            locks.remove(key)

    # -------------------------
    # Debugger stubs
    # -------------------------
    async def set_breakpoint(self, session_id: str, filename: str, line: int) -> None:
        s = self._get_session(session_id)
        s.metadata.setdefault("breakpoints", []).append({"file": filename, "line": line})
        await self._emit_event("debug.breakpoint.set", {"session": session_id, "file": filename, "line": line})

    async def remove_breakpoint(self, session_id: str, filename: str, line: int) -> None:
        s = self._get_session(session_id)
        bps = s.metadata.get("breakpoints", [])
        s.metadata["breakpoints"] = [b for b in bps if not (b["file"] == filename and b["line"] == line)]
        await self._emit_event("debug.breakpoint.removed", {"session": session_id, "file": filename, "line": line})

    async def step_over(self, session_id: str) -> None:
        raise NotImplementedError("Step-over is not implemented in UniLabCore prototype")

    async def step_in(self, session_id: str) -> None:
        raise NotImplementedError("Step-in is not implemented in UniLabCore prototype")

    async def continue_exec(self, session_id: str) -> None:
        raise NotImplementedError("Continue execution is not implemented in UniLabCore prototype")

    # -------------------------
    # Git helpers
    # -------------------------
    async def git_init(self, session_id: str) -> None:
        s = self._get_session(session_id)
        proc = await asyncio.create_subprocess_shell("git init", cwd=str(s.workspace_path))
        await proc.wait()
        if proc.returncode != 0:
            raise RuntimeError("git init failed")
        await self._emit_event("git.init", {"session_id": session_id})

    async def git_commit(self, session_id: str, message: str) -> None:
        s = self._get_session(session_id)
        cmds = ["git add -A", f"git commit -m {shlex.quote(message)}"]
        for c in cmds:
            proc = await asyncio.create_subprocess_shell(c, cwd=str(s.workspace_path))
            await proc.wait()
            if proc.returncode != 0:
                raise RuntimeError(f"git command failed: {c}")
        await self._emit_event("git.commit", {"session_id": session_id, "message": message})

    # -------------------------
    # Docker / k8s helpers (lightweight)
    # -------------------------
    async def generate_dockerfile(self, base_image: Optional[str] = None, extra_runs: Optional[List[str]] = None) -> str:
        base = base_image or self.config.docker_image
        lines = [
            f"FROM {base}",
            "ENV DEBIAN_FRONTEND=noninteractive",
            "RUN apt-get update && apt-get install -y python3 python3-pip git curl sudo",
            "WORKDIR /workspace",
        ]
        if extra_runs:
            lines += [f"RUN {r}" for r in extra_runs]
        return "\n".join(lines)

    async def generate_k8s_manifest(self, image: str, replicas: int = 1) -> Dict[str, Any]:
        manifest = {
            "apiVersion": "apps/v1",
            "kind": "Deployment",
            "metadata": {"name": f"unilab-{uuid.uuid4().hex[:6]}"},
            "spec": {
                "replicas": replicas,
                "selector": {"matchLabels": {"app": "unilab"}},
                "template": {
                    "metadata": {"labels": {"app": "unilab"}},
                    "spec": {"containers": [{"name": "unilab", "image": image, "ports": [{"containerPort": self.config.port}]}]},
                },
            },
        }
        return manifest

    # -------------------------
    # Health / util
    # -------------------------
    async def health_check(self) -> Dict[str, Any]:
        return {"alive": not self._shutdown, "sessions": len(self.sessions), "metrics": self._metrics}

    def _get_session(self, session_id: str) -> SessionInfo:
        s = self.sessions.get(session_id)
        if not s:
            raise KeyError(f"Unknown session {session_id}")
        return s


# ---------------------------
# Example usage
# ---------------------------
if __name__ == "__main__":
    import asyncio

    async def demo():
        cfg = BackendConfig(workspace_root=pathlib.Path("./demo_workspaces"), use_docker=False, octave_cmd=r"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\GNU Octave 10.2.0")
        core = UniLabCore(cfg)
        await core.start()
        # create a session
        s = await core.create_session(username="alice", engine="octave")
        # write a simple file
        await core.write_file(s.session_id, "example.m", "x = 0:0.1:2*pi; y = sin(x); plot(x,y); print('-dpng','plots/sin.png');")
        # run the script
        res = await core.run_script_file(s.session_id, s.workspace_path / "example.m", timeout=20.0)
        print("Run success:", res.success)
        print("Stdout:", res.stdout[:400])
        # fetch variables
        vars_snap = await core._fetch_variables(s.session_id)
        print("Variables in workspace:", list(vars_snap.keys()))
        # export an interactive plot using the same commands
        plot_path = await core.export_plot(s.session_id, "x = 0:0.1:2*pi; y = sin(x); plot(x,y);", fmt="png")
        print("Plot exported at:", plot_path)
        # snapshot workspace
        snap = await core.snapshot_workspace(s.session_id)
        print("Snapshot stored at:", snap)
        # stop session and shutdown
        await core.stop_session(s.session_id)
        await core.stop()

    asyncio.run(demo())
