import asyncio
import os
import uuid
import time
import shutil
import platform
import pathlib
import logging
import json
import subprocess as _subprocess
from typing import Any, Dict, List, Optional, Tuple
from .base import BaseEngine
from ..models import ExecutionResult, SessionInfo, BackendConfig

logger = logging.getLogger("OctaveEngine")

class OctaveEngine(BaseEngine):
    def __init__(self, session: SessionInfo, config: BackendConfig):
        super().__init__(session)
        self.config = config
        self.proc: Optional[asyncio.subprocess.Process] = None
        self.stdout_buffer: List[str] = []
        self._stdout_task: Optional[asyncio.Task] = None

    async def start(self):
        await self._start_persistent_octave()

    async def stop(self):
        if self.proc:
            try:
                self.proc.terminate()
                await asyncio.wait_for(self.proc.wait(), timeout=3.0)
            except Exception:
                try:
                    self.proc.kill()
                except Exception:
                    pass
        if self._stdout_task:
            self._stdout_task.cancel()

    async def run_code(self, code: str, timeout: Optional[float] = 30.0) -> ExecutionResult:
        start_ts = time.time()
        script_name = f"_run_{int(start_ts*1000)}.m"
        script_path = self.workspace_path / script_name
        script_path.write_text(code, encoding="utf-8")
        
        if self.proc and self.proc.stdin:
            script_posix = script_path.as_posix().replace("'", "''")
            marker = f"__UNILAB_DONE_{uuid.uuid4().hex}__"
            start_marker = f"::UNILAB::START::{marker}"
            end_marker = f"::UNILAB::END::{marker}"

            wrapper = (
                f"disp('{start_marker}');\n"
                f"try\n"
                f"  source('{script_posix}');\n"
                f"catch err\n"
                f"  disp(['::ERR::', err.message]);\n"
                f"end\n"
                f"disp('{end_marker}');\n"
            )

            self.stdout_buffer.clear()
            try:
                self.proc.stdin.write(wrapper.encode())
                await self.proc.stdin.drain()
            except Exception as e:
                return ExecutionResult(False, "", str(e), 1, time.time() - start_ts)

            deadline = time.time() + (timeout or 30.0)
            seen_end = False
            collected_lines = []
            while time.time() < deadline:
                while self.stdout_buffer:
                    line = self.stdout_buffer.pop(0)
                    collected_lines.append(line)
                    if end_marker in line:
                        seen_end = True
                        break
                if seen_end:
                    break
                await asyncio.sleep(0.05)

            out_text = "\n".join(collected_lines)
            plots = []
            for line in collected_lines:
                if "::SAVED::" in line:
                    p = line.split("::SAVED::", 1)[1].strip()
                    plots.append(p)
            
            rc = 0 if not any(l.startswith("::ERR::") for l in collected_lines) else 1
            vars_snapshot = await self.fetch_variables()
            
            return ExecutionResult(
                success=(rc == 0),
                stdout=out_text,
                stderr="",
                return_code=rc,
                duration_s=time.time() - start_ts,
                variables_snapshot=vars_snapshot,
                plots=plots
            )
        else:
            # Fallback to ephemeral process
            proc2 = await asyncio.create_subprocess_shell(
                f"octave -qf {script_path.name}",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=str(self.workspace_path)
            )
            try:
                out_b, err_b = await asyncio.wait_for(proc2.communicate(), timeout=timeout or 30.0)
            except asyncio.TimeoutError:
                proc2.kill()
                out_b, err_b = await proc2.communicate()
            
            return ExecutionResult(
                success=(proc2.returncode == 0),
                stdout=out_b.decode(errors="ignore"),
                stderr=err_b.decode(errors="ignore"),
                return_code=proc2.returncode or 1,
                duration_s=time.time() - start_ts
            )

    async def fetch_variables(self) -> Dict[str, Any]:
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
        res = await self.run_code(wrapper, timeout=10.0)
        if "::VARS::" not in res.stdout:
            return {}
        payload = res.stdout.split("::VARS::", 1)[1].strip()
        try:
            decoded = json.loads(payload)
            result = {}
            for k, v in decoded.items():
                cls = v.get("class", "unknown")
                size = v.get("size", None)
                val = v.get("value", None)
                preview = val
                if isinstance(preview, list) and len(preview) > 50:
                    preview = preview[:50]
                shape = tuple(size) if isinstance(size, list) else None
                result[k] = {"name": k, "dtype": cls, "shape": shape, "preview": preview}
            return result
        except:
            return {}

    async def _start_persistent_octave(self) -> None:
        octave_exe = self._find_octave_executable()
        
        def _try_start(exe_path: str):
            args = [exe_path, "--interactive", "--quiet", "--no-init-file"]
            creationflags = 0
            if platform.system().lower().startswith("win"):
                creationflags = _subprocess.CREATE_NO_WINDOW
            return asyncio.create_subprocess_exec(
                *args,
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.STDOUT,
                cwd=str(self.workspace_path),
                creationflags=creationflags
            )

        self.proc = await _try_start(octave_exe)
        await asyncio.sleep(0.15)
        
        if self.proc.returncode is not None:
            # Launcher logic omitted for brevity, but should be here in a full impl
            pass

        self._stdout_task = asyncio.create_task(self._read_output())

    async def _read_output(self):
        assert self.proc and self.proc.stdout
        while True:
            line = await self.proc.stdout.readline()
            if not line:
                break
            self.stdout_buffer.append(line.decode(errors="ignore").rstrip("\n"))

    def _find_octave_executable(self) -> str:
        if self.config.octave_cmd:
            return self.config.octave_cmd
        for name in ["octave", "octave-cli", "octave.exe", "octave-cli.exe"]:
            found = shutil.which(name)
            if found: return found
        # Simplified for now
        return "octave"
