import asyncio
import sys
import os
import io
import time
import pickle
import importlib.util
import pathlib
import numpy as np
from typing import Any, Dict, Optional
from contextlib import redirect_stdout, redirect_stderr
from ..core import UniLabTranspiler
from .. import runtime
from .base import BaseEngine
from ..models import ExecutionResult, SessionInfo

class AutoloadDict(dict):
    def __init__(self, engine, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.engine = engine
        self._loading = set()

    def __getitem__(self, key):
        if key not in self and key not in self._loading:
            self._loading.add(key)
            try:
                # Try to load the function from search paths
                for path in self.engine.search_paths:
                    m_file = path / f"{key}.m"
                    if m_file.exists():
                        try:
                            code = m_file.read_text(encoding="utf-8")
                            # We use a synchronous version of transpile here
                            python_code, _, _ = self.engine.transpiler.transpile(code)
                            # Execute in this dict
                            exec(python_code, self)
                            if key in self:
                                return super().__getitem__(key)
                        except Exception as e:
                            print(f"Autoloader error for {key}: {e}")
            finally:
                self._loading.remove(key)
        return super().__getitem__(key)

class TranspilerEngine(BaseEngine):
    def __init__(self, session: SessionInfo):
        super().__init__(session)
        self.transpiler = UniLabTranspiler()
        self.search_paths = [self.workspace_path]
        
        # Use our new AutoloadDict
        self.globals = AutoloadDict(self)
        self.globals.update({
            'np': np,
            '__builtins__': __builtins__,
            'addpath': self._add_path,
            'ans': None,
        })
        
        # Inject runtime functions
        for name in dir(runtime):
            if not name.startswith('_'):
                self.globals[name] = getattr(runtime, name)
        
        # Load custom packages from backend/packages
        self._load_custom_packages()
        
        # Load standard libraries from backend/libraries
        self._load_standard_libraries()
        
        # Load persistent workspace if it exists
        self._load_workspace()

    def _load_standard_libraries(self):
        current_dir = pathlib.Path(__file__).parent
        libs_dir = (current_dir / ".." / ".." / "libraries").resolve()
        
        if not libs_dir.exists():
            return

        for item in libs_dir.iterdir():
            if item.is_dir():
                if item not in self.search_paths:
                    self.search_paths.append(item)
                    # print(f"Added standard library path: {item.name}")

    def _add_path(self, path: str):
        p = pathlib.Path(path)
        if not p.is_absolute():
            p = (self.workspace_path / p).resolve()
        
        if p.exists() and p not in self.search_paths:
            self.search_paths.append(p)
            # print(f"Added path: {p}")

    def _load_custom_packages(self):
        # Determine the backend/packages path
        # Assuming this file is at backend/core/engines/transpiler.py
        current_dir = pathlib.Path(__file__).parent
        packages_dir = (current_dir / ".." / ".." / "packages").resolve()
        
        if not packages_dir.exists():
            return

        for item in packages_dir.iterdir():
            if item.is_dir() and (item / "__init__.py").exists():
                package_name = item.name
                try:
                    spec = importlib.util.spec_from_file_location(package_name, item / "__init__.py")
                    module = importlib.util.module_from_spec(spec)
                    spec.loader.exec_module(module)
                    self.globals[package_name] = module
                    # print(f"Loaded package: {package_name}")
                except Exception as e:
                    print(f"Failed to load package {package_name}: {e}")

    async def start(self):
        # Already initialized in __init__, but could add more here if needed
        pass

    async def stop(self):
        self._save_workspace()

    async def run_code(self, code: str, timeout: Optional[float] = 30.0) -> ExecutionResult:
        # Handle 'help topic' style calls specifically
        stripped_code = code.strip()
        if stripped_code.startswith('help'):
            parts = stripped_code.split()
            # Handle help() or help topic
            topic = None
            if len(parts) > 1:
                topic = parts[1].rstrip(';')
            elif '(' in stripped_code and ')' in stripped_code:
                # Handle help('topic') or help("topic")
                import re
                match = re.search(r"help\(['\"]?(\w+)['\"]?\)", stripped_code)
                if match:
                    topic = match.group(1)
            
            return await self._get_help(topic)

        start_ts = time.time()
        try:
            python_code, called_funcs, added_paths = self.transpiler.transpile(code)
            
            # Temporary add paths for resolution (from addpath calls in the code)
            for ap in added_paths:
                self._add_path(ap)
            
            # Re-verify critical runtime functions are in globals
            for name in dir(runtime):
                if not name.startswith('_'):
                    self.globals[name] = getattr(runtime, name)
            
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
            stdout_lines = stdout.splitlines()
            
            # Find all plot markers
            plot_indices = [i for i, line in enumerate(stdout_lines) if "::GRAPHICAL_PLOT::" in line]
            
            plots = []
            if plot_indices:
                # Keep track of which line we'll put the render on (the last one)
                render_target_idx = plot_indices[-1]
                for idx in plot_indices:
                    line = stdout_lines[idx]
                    p = line.split("::GRAPHICAL_PLOT::", 1)[1].strip()
                    plots.append(p)
                    
                    if idx == render_target_idx:
                        # Render the final version of the plot
                        full_path = self.workspace_path / p
                        render_func = self.globals.get('render_image_terminal')
                        if render_func:
                            render_out = render_func(str(full_path))
                            stdout_lines[idx] = render_out if render_out else ""
                        else:
                            stdout_lines[idx] = ""
                    else:
                        # Hide intermediate plot markers
                        stdout_lines[idx] = ""

            return ExecutionResult(
                success=success,
                stdout="\n".join(l for l in stdout_lines if l or l == ""),
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

    async def _get_help(self, topic: Optional[str]) -> ExecutionResult:
        start_ts = time.time()
        if not topic:
            help_text = "UniLab Help System\nType 'help <topic>' to learn more about a command or function.\nExamples: help plot, help linspace, help z_score"
            return ExecutionResult(True, help_text, "", 0, time.time() - start_ts, self._get_variables(), [])

        # 1. Search in runtime (Python functions)
        import backend.core.runtime as rt
        if hasattr(rt, topic):
            func = getattr(rt, topic)
            doc = getattr(func, '__doc__', None) or "No documentation available."
            help_text = f"Help for built-in function '{topic}':\n\n{doc}"
            return ExecutionResult(True, help_text, "", 0, time.time() - start_ts, self._get_variables(), [])

        # 2. Search in workspace/search paths for .m files
        for path in self.search_paths:
            m_file = path / f"{topic}.m"
            if m_file.exists():
                lines = m_file.read_text(encoding="utf-8").splitlines()
                help_lines = []
                for line in lines:
                    line_strip = line.strip()
                    if line_strip.startswith('function') or line_strip.startswith('%'):
                        help_lines.append(line)
                    elif line_strip and not line_strip.startswith('%'):
                        # Stop at first non-comment non-function line
                        break
                help_text = f"Help for function '{topic}' in {m_file}:\n\n" + "\n".join(help_lines)
                return ExecutionResult(True, help_text, "", 0, time.time() - start_ts, self._get_variables(), [])

        return ExecutionResult(False, "", f"Help topic '{topic}' not found.", 1, time.time() - start_ts, self._get_variables(), [])

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
