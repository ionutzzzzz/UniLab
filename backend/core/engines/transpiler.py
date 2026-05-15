import asyncio
import sys
import os
import io
import time
import pickle
import numpy as np
from typing import Any, Dict, Optional
from contextlib import redirect_stdout, redirect_stderr
from ..core import MatlabTranspiler
from .. import runtime
from .base import BaseEngine
from ..models import ExecutionResult, SessionInfo

class TranspilerEngine(BaseEngine):
    def __init__(self, session: SessionInfo):
        super().__init__(session)
        self.transpiler = MatlabTranspiler()
        self.globals = {
            'np': np,
            '__builtins__': __builtins__,
        }
        # Inject runtime functions
        for name in dir(runtime):
            if not name.startswith('_'):
                self.globals[name] = getattr(runtime, name)
        
        # Load persistent workspace if it exists
        self._load_workspace()

    async def start(self):
        # Already initialized in __init__, but could add more here if needed
        pass

    async def stop(self):
        self._save_workspace()

    async def run_code(self, code: str, timeout: Optional[float] = 30.0) -> ExecutionResult:
        start_ts = time.time()
        try:
            python_code = self.transpiler.transpile(code)
            
            # Prepare execution environment
            out = io.StringIO()
            err = io.StringIO()
            
            # Set current directory to workspace
            old_cwd = os.getcwd()
            os.chdir(self.workspace_path)
            
            success = True
            try:
                # We use a custom globals dict to persist state between runs in the same session
                with redirect_stdout(out), redirect_stderr(err):
                    exec(python_code, self.globals)
                
                # Save workspace after successful execution
                self._save_workspace()
            except Exception as e:
                success = False
                err.write(str(e))
            finally:
                os.chdir(old_cwd)
            
            duration = time.time() - start_ts
            stdout = out.getvalue()
            plots = []
            for line in stdout.splitlines():
                if "::SAVED::" in line:
                    p = line.split("::SAVED::", 1)[1].strip()
                    plots.append(p)

            return ExecutionResult(
                success=success,
                stdout=stdout,
                stderr=err.getvalue(),
                return_code=0 if success else 1,
                duration_s=duration,
                variables_snapshot=self._get_variables(),
                plots=plots
            )
        except Exception as e:
            return ExecutionResult(
                success=False,
                stdout='',
                stderr=f"Transpilation Error: {str(e)}",
                return_code=1,
                duration_s=time.time() - start_ts,
                variables_snapshot={},
                plots=[]
            )

    async def fetch_variables(self) -> Dict[str, Any]:
        return self._get_variables()

    def _get_variables(self):
        vars_snap = {}
        for k, v in self.globals.items():
            if k.startswith('_') or k in dir(runtime) or k == 'np':
                continue
            
            dtype = type(v).__name__
            shape = getattr(v, 'shape', None)
            preview = str(v)
            if isinstance(v, np.ndarray) and v.size > 50:
                preview = str(v.flatten()[:50]) + "..."
            
            vars_snap[k] = {
                'name': k,
                'dtype': dtype,
                'shape': shape,
                'preview': preview
            }
        return vars_snap

    def _save_workspace(self):
        save_path = self.workspace_path / ".unilab_workspace.pkl"
        vars_to_save = {}
        for k, v in self.globals.items():
            if k.startswith('_') or k in dir(runtime) or k == 'np' or k == '__builtins__':
                continue
            try:
                pickle.dumps(v)
                vars_to_save[k] = v
            except:
                continue
        
        with open(save_path, 'wb') as f:
            pickle.dump(vars_to_save, f)

    def _load_workspace(self):
        save_path = self.workspace_path / ".unilab_workspace.pkl"
        if save_path.exists():
            try:
                with open(save_path, 'rb') as f:
                    vars_loaded = pickle.load(f)
                    self.globals.update(vars_loaded)
            except:
                pass
