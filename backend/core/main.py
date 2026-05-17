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
import shutil
from typing import Any, Dict, List, Optional, Union, Callable

from .models import BackendConfig, SessionInfo, ExecutionResult, EngineType
from .engines.transpiler import TranspilerEngine
from .engines.base import BaseEngine

logger = logging.getLogger("UniLabCore")

class UniLabCore:
    def __init__(self, config: Optional[BackendConfig] = None):
        self.config = config or BackendConfig()
        self.config.workspace_root.mkdir(parents=True, exist_ok=True)
        self.sessions: Dict[str, SessionInfo] = {}
        self.engines: Dict[str, BaseEngine] = {}
        self._locks: Dict[str, asyncio.Lock] = {}
        self._event_queue: asyncio.Queue = asyncio.Queue()
        self._plugin_hooks: Dict[str, List[Callable[..., Any]]] = {}
        self._rooms: Dict[str, SessionInfo] = {}
        self._metrics: Dict[str, Any] = {"runs": 0, "errors": 0, "sessions_created": 0, "start_time": time.time()}
        self._shutdown = False
        self._bg_tasks: List[asyncio.Task] = []
        logger.info("UniLabCore initialized")

    async def start(self) -> None:
        self._bg_tasks.append(asyncio.create_task(self._event_pump()))

    async def stop(self) -> None:
        self._shutdown = True
        for sid in list(self.sessions.keys()):
            await self.stop_session(sid)
        for t in self._bg_tasks:
            t.cancel()

    async def _event_pump(self) -> None:
        while not self._shutdown:
            try:
                ev = await self._event_queue.get()
                for name, hooks in self._plugin_hooks.items():
                    for hook in hooks:
                        try:
                            if asyncio.iscoroutinefunction(hook):
                                asyncio.create_task(hook(ev))
                            else: hook(ev)
                        except Exception:
                            logger.exception("Plugin hook failed")
            except asyncio.CancelledError: break
            except Exception: logger.exception("Event pump error")

    async def create_session(self, username: Optional[str] = None, engine: str = "transpiler", shared_workspace: Optional[pathlib.Path] = None) -> SessionInfo:
        username = username or self.config.default_username
        session_id = str(uuid.uuid4())
        workspace = shared_workspace or (self.config.workspace_root / f"{username}_{session_id}").resolve()
        workspace.mkdir(parents=True, exist_ok=True)
        
        s = SessionInfo(
            session_id=session_id,
            username=username,
            engine=engine,
            started_at=time.time(),
            workspace_path=workspace,
            is_shared=bool(shared_workspace)
        )
        self.sessions[session_id] = s
        self._locks[session_id] = asyncio.Lock()
        
        # Factory for engines
        self.engines[session_id] = TranspilerEngine(s)
        
        await self.engines[session_id].start()
        self._metrics["sessions_created"] += 1
        return s

    async def stop_session(self, session_id: str) -> None:
        if session_id in self.engines:
            await self.engines[session_id].stop()
            del self.engines[session_id]
        self.sessions.pop(session_id, None)
        self._locks.pop(session_id, None)

    async def get_session(self, session_id: str) -> Optional[SessionInfo]:
        return self.sessions.get(session_id)

    async def list_sessions(self) -> List[SessionInfo]:
        return list(self.sessions.values())

    async def run_code(self, session_id: str, code: str, timeout: Optional[float] = 30.0) -> ExecutionResult:
        engine = self.engines.get(session_id)
        if not engine: raise KeyError(f"No engine for session {session_id}")
        
        async with self._locks[session_id]:
            res = await engine.run_code(code, timeout=timeout)
            self._metrics["runs"] += 1
            return res

    # File operations refactored to be simpler
    async def list_files(self, session_id: str, path: Optional[str] = None) -> List[Dict[str, Any]]:
        s = self.sessions[session_id]
        base = s.workspace_path if path is None else (s.workspace_path / path)
        return [{"name": p.name, "is_dir": p.is_dir(), "size": p.stat().st_size} for p in base.iterdir()]

    async def read_file(self, session_id: str, path: str) -> str:
        s = self.sessions[session_id]
        return (s.workspace_path / path).read_text()

    async def write_file(self, session_id: str, path: str, content: str) -> None:
        s = self.sessions[session_id]
        p = s.workspace_path / path
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)

    async def export_workspace(self, session_id: str, format: str = "json", filename: Optional[str] = None) -> str:
        engine = self.engines.get(session_id)
        if not engine: raise KeyError(f"No engine for session {session_id}")
        
        # Fetch current variables
        vars_snapshot = await engine.fetch_variables()
        # For simplicity, we just export the previews/values
        data_to_export = {k: v['preview'] for k, v in vars_snapshot.items()}
        
        filename = filename or f"workspace_export_{int(time.time())}.{format}"
        output_path = self.sessions[session_id].workspace_path / filename
        
        from backend.exporters import CSVExporter, JSONExporter
        if format.lower() == "csv":
            exporter = CSVExporter()
        else:
            exporter = JSONExporter()
            
        return await exporter.export(data_to_export, str(output_path))
