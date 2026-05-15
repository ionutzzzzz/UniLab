import asyncio
import sys
import os
import io
import time
import numpy as np
from contextlib import redirect_stdout, redirect_stderr
from backend.core.core import MatlabTranspiler
import backend.core.runtime as runtime

class TranspilerEngine:
    def __init__(self, workspace_path):
        self.workspace_path = workspace_path
        self.transpiler = MatlabTranspiler()
        self.globals = {
            'np': np,
            '__builtins__': __builtins__,
        }
        # Inject runtime functions
        for name in dir(runtime):
            if not name.startswith('_'):
                self.globals[name] = getattr(runtime, name)

    async def run_code(self, code, timeout=30):
        start_ts = time.time()
        try:
            python_code = self.transpiler.transpile(code)
            # Use sys.__stdout__ to bypass any redirects
            print(f"DEBUG Transpiled Python:\n{python_code}\n", file=sys.__stdout__)
            
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
            except Exception as e:
                success = False
                err.write(str(e))
            finally:
                os.chdir(old_cwd)
            
            duration = time.time() - start_ts
            return {
                'success': success,
                'stdout': out.getvalue(),
                'stderr': err.getvalue(),
                'duration_s': duration,
                'variables': self._get_variables()
            }
        except Exception as e:
            return {
                'success': False,
                'stdout': '',
                'stderr': f"Transpilation Error: {str(e)}",
                'duration_s': time.time() - start_ts,
                'variables': {}
            }

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
