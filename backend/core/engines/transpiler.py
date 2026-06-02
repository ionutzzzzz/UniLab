import asyncio
import sys
import os
import io
import json
import time
import re
import pickle
import importlib.util
import pathlib
import linecache
import numpy as np
from typing import Any, Dict, Optional
from contextlib import redirect_stdout, redirect_stderr
from ..transpiler_core import UniLabTranspiler
from .. import runtime
from .base import BaseEngine
from ..models import ExecutionResult, SessionInfo

class AutoloadDict(dict):
    def __init__(self, engine, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.engine = engine
        self._loading = set()

    def __setitem__(self, key, value):
        super().__setitem__(key, value)
        if not key.startswith('_') and key not in self._loading:
            # print(f"DEBUG: Variable set: {key}")
            self.engine._trigger_workspace_changed()

    def __delitem__(self, key):
        super().__delitem__(key)
        if not key.startswith('_'):
            # print(f"DEBUG: Variable deleted: {key}")
            self.engine._trigger_workspace_changed()

    def __getitem__(self, key):
        try:
            hash(key)
        except TypeError:
            # If the key is not hashable (like a numpy array), it can't be a valid variable name lookup
            # that we would want to auto-load. Just let the standard dict handle it (which will likely raise KeyError).
            return super().__getitem__(key)

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

                            # Register in linecache to support inspect/nargout
                            filename = str(m_file)
                            linecache.cache[filename] = (
                                len(python_code),
                                None,
                                [line + '\n' for line in python_code.splitlines()],
                                filename
                            )

                            # Execute in the engine's globals to ensure all builtins/constants are available
                            exec(compile(python_code, filename, 'exec'), self.engine.globals)
                            if key in self.engine.globals:
                                return self.engine.globals[key]
                        except Exception as e:
                            print(f"Autoloader error for {key}: {e}")
            finally:
                self._loading.remove(key)

        return super().__getitem__(key)


class TranspilerEngine(BaseEngine):
    def __init__(self, session: SessionInfo):
        super().__init__(session)
        self.transpiler = UniLabTranspiler()
        self.on_workspace_changed = None
        self._workspace_changed_timer = None
        self._runtime_names = set(dir(runtime))
        self._last_ws_update = 0
        
        # Set initial CWD to sample folder in web mode
        if os.environ.get('UNILAB_WEB_MODE') == '1':
            # backend/core/engines/transpiler.py -> Project Root
            project_root = pathlib.Path(__file__).resolve().parents[3]
            sample_dir = project_root / 'sample'
            self.cwd = sample_dir if sample_dir.exists() else self.workspace_path
        else:
            self.cwd = self.workspace_path

        self.search_paths = [self.cwd, self.workspace_path]
        
        # Add libraries to search path
        backend_dir = pathlib.Path(__file__).resolve().parents[2]
        libs_dir = backend_dir / "stdlib" / "libraries"
        if libs_dir.exists():
            for lib_subdir in libs_dir.iterdir():
                if lib_subdir.is_dir() and not lib_subdir.name.startswith("__"):
                    self.search_paths.append(lib_subdir)
        
        # Use our new AutoloadDict
        self.globals = AutoloadDict(self)
        self.globals.update({
            'np': np,
            '__builtins__': __builtins__,
            'addpath': self._add_path,
            'ans': None,
            'i': 1j,
            'j': 1j,
        })
        
        # Inject runtime functions and constants (inf, nan, true, false, etc.)
        for name in dir(runtime):
            if not name.startswith('_'):
                self.globals[name] = getattr(runtime, name)
        
        # Ensure builtins don't shadow runtime functions
        self.globals['abs'] = runtime.unilab_abs
        self.globals['round'] = runtime.round
        self.globals['floor'] = runtime.floor
        self.globals['ceil'] = runtime.ceil
        self.globals['max'] = runtime.unilab_max
        self.globals['min'] = runtime.unilab_min
        self.globals['sum'] = runtime.unilab_sum
        self.globals['mean'] = runtime.unilab_mean
        self.globals['any'] = runtime.unilab_any
        self.globals['all'] = runtime.unilab_all
        self.globals['prod'] = runtime.unilab_prod
        self.globals['eig'] = runtime.unilab_eig
        self.globals['xcorr'] = runtime.unilab_xcorr
        self.globals['ode45'] = runtime.ode45
        
        # Load custom packages from backend/stdlib/packages
        self._load_custom_packages()
        
        # Load standard libraries from backend/stdlib/libraries
        self._load_standard_libraries()
        
        # Load persistent workspace if it exists
        self._load_workspace()

    def _trigger_workspace_changed(self):
        """Triggers a workspace update notification with rate-limiting."""
        if not self.on_workspace_changed:
            return

        # Simple rate limiting for real-time updates: 100ms
        now = time.time()
        if hasattr(self, '_last_ws_update') and now - self._last_ws_update < 0.1:
            return
        self._last_ws_update = now

        try:
            vars_snap = self._get_variables()
            if asyncio.iscoroutinefunction(self.on_workspace_changed):
                try:
                    loop = asyncio.get_running_loop()
                    # Use a trailing-edge timer or just fire-and-forget for async
                    loop.create_task(self.on_workspace_changed(vars_snap))
                except RuntimeError:
                    pass
            else:
                # FFI/Sync callback - call immediately
                self.on_workspace_changed(vars_snap)
        except Exception as e:
            # Silent failure for notification errors
            pass

    def _load_standard_libraries(self):
        # backend/core/engines/transpiler.py -> backend/stdlib/libraries
        current_dir = pathlib.Path(__file__).parent
        libs_dir = (current_dir / ".." / ".." / "stdlib" / "libraries").resolve()
        
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
        # Determine the backend/stdlib/packages path
        # Assuming this file is at backend/core/engines/transpiler.py
        current_dir = pathlib.Path(__file__).parent
        packages_dir = (current_dir / ".." / ".." / "stdlib" / "packages").resolve()
        
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
        stripped_code = code.strip().rstrip(';')
        if not stripped_code:
            return ExecutionResult(True, "", "", 0, 0.0, self._get_variables(), [])
        
        # Ensure we are in the correct directory for this session
        old_cwd = os.getcwd()
        os.chdir(self.cwd)
        
        # Set context-safe workspace path for the runtime
        from ..runtime import unilab_workspace_ctx, unilab_update_ctx
        token = unilab_workspace_ctx.set(str(self.workspace_path))
        update_token = unilab_update_ctx.set(lambda: self._trigger_workspace_changed())
        
        try:
            # --- Shell Command Handling ---
            import subprocess
            import shlex
            
            parts = stripped_code.split()
            cmd = parts[0].lower()
            
            # 1. Handle 'cd' (Directory Persistence)
            if cmd == 'cd':
                try:
                    target_dir = parts[1] if len(parts) > 1 else str(self.workspace_path)
                    os.chdir(target_dir)
                    # Persist the change
                    self.cwd = pathlib.Path(os.getcwd()).resolve()
                    return ExecutionResult(True, str(self.cwd), "", 0, 0.0, self._get_variables(), [])
                except Exception as e:
                    return ExecutionResult(False, "", str(e), 1, 0.0, self._get_variables(), [])

            # 2. Handle common shell commands or '!' prefix
            SHELL_COMMANDS = ('ls', 'dir', 'pwd', 'mkdir', 'rm', 'cp', 'mv', 'cat', 'git', 'python', 'python3', 'pip', 'pip3', 'npm', 'node', 'grep', 'curl', 'wget', 'chmod', 'chown', 'ssh', 'scp', 'apt', 'apt-get', 'brew', 'cargo')
            if cmd in SHELL_COMMANDS or stripped_code.startswith('!'):
                try:
                    exec_cmd = stripped_code[1:] if stripped_code.startswith('!') else stripped_code
                    proc = subprocess.run(shlex.split(exec_cmd), capture_output=True, text=True, timeout=timeout)
                    return ExecutionResult(
                        proc.returncode == 0,
                        proc.stdout,
                        proc.stderr,
                        proc.returncode,
                        0.0,
                        self._get_variables(),
                        []
                    )
                except Exception as e:
                    return ExecutionResult(False, "", str(e), 1, 0.0, self._get_variables(), [])

            # 3. Handle 'run' command (recursive execution)
            if cmd == 'run' and len(parts) > 1:
                script_name = parts[1]
                if not script_name.endswith('.m'): script_name += '.m'
                script_path = pathlib.Path(script_name)
                
                # Try relative to CWD, then workspace, then parent (project root)
                if not script_path.exists():
                    script_path = self.cwd / script_name
                if not script_path.exists():
                    script_path = self.workspace_path / script_name
                if not script_path.exists():
                    # Fallback to absolute project root
                    root = pathlib.Path(__file__).resolve().parents[3]
                    script_path = root / script_name

                if script_path.exists():
                    try:
                        script_code = script_path.read_text(encoding="utf-8")
                        # Restore CWD before recursive call to let it handle its own chdir
                        os.chdir(old_cwd)
                        return await self.run_code(script_code, timeout=timeout)
                    except Exception as e:
                        return ExecutionResult(False, "", f"Error running script: {e}", 1, 0.0, self._get_variables(), [])
                else:
                    return ExecutionResult(False, "", f"Script '{script_name}' not found.", 1, 0.0, self._get_variables(), [])

            # 4. Handle 'clc' (Clear)
            if cmd == 'clc':
                return ExecutionResult(True, "::CLEAR_TERMINAL::", "", 0, 0.0, self._get_variables(), [])

            if stripped_code.startswith('help'):
                parts = stripped_code.split()
                # Handle help() or help topic
                topic = None
                if len(parts) > 1:
                    topic = parts[1].rstrip(';')
                elif '(' in stripped_code and ')' in stripped_code:
                    # Handle help('topic') or help("topic")
                    match = re.search(r"help\(['\"]?(\w+)['\"]?\)", stripped_code)
                    if match:
                        topic = match.group(1)
                
                return await self._get_help(topic)

            # Auto-help / Auto-call for commands
            if stripped_code and re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', stripped_code):
                is_command = stripped_code.lower() in ('whos', 'clc', 'list_libraries', 'exit', 'quit', 'clear')
                
                if is_command:
                    if stripped_code.lower() != 'clear': # clear handled by transpiler as statement
                        code = stripped_code + "()"
                else:
                    # 1. Check if it exists as a function in runtime or search paths
                    is_func = False
                    if hasattr(runtime, stripped_code) and not stripped_code.startswith('_'):
                        is_func = True
                    if not is_func:
                        for path in self.search_paths:
                            if (path / f"{stripped_code}.m").exists():
                                is_func = True
                                break
                    
                    # 2. Check if it's ALREADY a variable in globals (and not just a function pointer)
                    is_var = False
                    if stripped_code in self.globals:
                        val = self.globals[stripped_code]
                        if not callable(val) or isinstance(val, np.ndarray):
                            is_var = True
                    
                    if is_func and not is_var:
                        return await self._get_help(stripped_code)

            start_ts = time.time()
            try:
                try:
                    python_code, called_funcs, added_paths = self.transpiler.transpile(code)
                except Exception as te:
                    # Fallback: try running as shell command if it looks like one (single line, no special MATLAB chars)
                    if '\n' not in stripped_code and not any(c in stripped_code for c in '()[]{}='):
                        try:
                            # Use shlex to safely split, check if first part is an executable
                            test_parts = shlex.split(stripped_code)
                            if test_parts:
                                import shutil
                                if shutil.which(test_parts[0]):
                                    proc = subprocess.run(test_parts, capture_output=True, text=True, timeout=timeout)
                                    return ExecutionResult(proc.returncode == 0, proc.stdout, proc.stderr, proc.returncode, time.time()-start_ts, self._get_variables(), [])
                        except:
                            pass
                    raise te

                # Temporary add paths for resolution (from addpath calls in the code)
                for ap in added_paths:
                    self._add_path(ap)
                
                # Re-verify critical runtime functions and constants are in globals
                for name in dir(runtime):
                    if not name.startswith('_'):
                        self.globals[name] = getattr(runtime, name)
                
                # Prepare execution environment
                out = io.StringIO()
                err = io.StringIO()
                
                success = True
                try:
                    # Register in linecache to support inspect/nargout
                    # Use a descriptive pseudo-filename if real one not available
                    filename = os.environ.get('UNILAB_CURRENT_SCRIPT', '<unilab_script>')
                    linecache.cache[filename] = (
                        len(python_code),
                        None,
                        [line + '\n' for line in python_code.splitlines()],
                        filename
                    )

                    # We use a custom globals dict to persist state between runs in the same session
                    with redirect_stdout(out), redirect_stderr(err):
                        exec(compile(python_code, filename, 'exec'), self.globals)
                    
                    # If code changed directory, update persistent CWD
                    self.cwd = pathlib.Path(os.getcwd()).resolve()
                    
                    # Save workspace after successful execution
                    self._save_workspace()

                    # Final workspace update push
                    self._trigger_workspace_changed()
                except NameError as ne:
                    success = False
                    var_name = str(ne).split("'")[1] if "'" in str(ne) else "unknown"
                    err.write(f"Could not recognise command or function '{var_name}'")
                except Exception as e:
                    success = False
                    # For other errors, show a cleaner message if possible, or the last line of traceback
                    import traceback
                    err.write(traceback.format_exc())
                
                duration = time.time() - start_ts
                stdout = out.getvalue()
                stdout_lines = stdout.splitlines()
                
                # Find all plot markers
                plot_indices = [i for i, line in enumerate(stdout_lines) if "::GRAPHICAL_PLOT::" in line]

                plots = []
                plot_data_b64 = []
                plot_3d_data = []

                if plot_indices:
                    # Deduplicate for rendering: only keep the last update for each figure number
                    # to be returned in the 'plots' list and base64 data.
                    # But we must DELETE ALL files.
                    final_plot_markers = {}
                    all_plot_files = []
                    
                    for idx in plot_indices:
                        line = stdout_lines[idx]
                        parts = line.split("::GRAPHICAL_PLOT::", 1)[1].split("::FIG::")
                        filename = parts[0].strip()

                        fig_info = parts[1].split("::VER::") if len(parts) > 1 else ["default"]
                        fig_num = fig_info[0].strip()
                        
                        final_plot_markers[fig_num] = (idx, filename)
                        all_plot_files.append((idx, filename))

                    final_render_indices = {v[0] for v in final_plot_markers.values()}
                    import base64
                    
                    # Process and delete files
                    for idx, filename in all_plot_files:
                        is_final = idx in final_render_indices
                        p = self.workspace_path / filename
                        if not p.exists(): p = self.cwd / filename
                        
                        data_3d_entry = None
                        
                        # Handle metadata/3D data sidecar (always look for it)
                        base_name = os.path.splitext(filename)[0]
                        for ext in ['.json', '.3d.json']:
                            meta_path = self.workspace_path / (base_name + ext)
                            if not meta_path.exists(): meta_path = self.cwd / (base_name + ext)
                            
                            if meta_path.exists():
                                try:
                                    if is_final:
                                        with open(str(meta_path), 'r') as f:
                                            data_3d_entry = json.load(f)
                                    
                                    if os.environ.get('UNILAB_WEB_MODE') == '1':
                                        meta_path.unlink()
                                except Exception as e:
                                    print(f"Error handling metadata sidecar {meta_path}: {e}")
                        
                        if is_final:
                            plots.append(filename)
                            plot_3d_data.append(data_3d_entry)

                        if p.exists():
                            try:
                                if is_final and os.environ.get('UNILAB_WEB_MODE') == '1':
                                    b64 = base64.b64encode(p.read_bytes()).decode('utf-8')
                                    plot_data_b64.append(f"data:image/png;base64,{b64}")
                                
                                if os.environ.get('UNILAB_WEB_MODE') == '1':
                                    p.unlink()
                            except Exception as e:
                                print(f"Error unlinking plot file {p}: {e}")

                    # Clean up stdout markers
                    render_func = self.globals.get('render_image_terminal')
                    for idx in plot_indices:
                        if idx in final_render_indices and render_func and os.environ.get('UNILAB_WEB_MODE') != '1':
                            # In CLI mode, we don't delete yet because render_func might need it
                            # Actually, render_func usually prints to terminal.
                            pass
                        stdout_lines[idx] = ""

                return ExecutionResult(
                    success=success,
                    stdout="\n".join(l for l in stdout_lines if l or l == "").replace("\\n", "\n"),
                    stderr=err.getvalue().replace("\\n", "\n"),
                    return_code=0 if success else 1,
                    duration_s=duration,
                    variables_snapshot=self._get_variables(),
                    plots=plots,
                    extra={"plot_data_b64": plot_data_b64, "plot_3d_data": plot_3d_data}
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
        finally:
            os.chdir(old_cwd)

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
                help_text = f"\n".join(help_lines)
                return ExecutionResult(True, help_text, "", 0, time.time() - start_ts, self._get_variables(), [])

        return ExecutionResult(False, "", f"Help topic '{topic}' not found.", 1, time.time() - start_ts, self._get_variables(), [])

    async def fetch_variables(self) -> Dict[str, Any]:
        return self._get_variables()

    def complete(self, text: str, line: str) -> list[str]:
        """Provides autocomplete suggestions for symbols and paths."""
        stripped_line = line.lstrip()
        
        # Keywords and Builtins from UniLab.py logic
        KEYWORDS = ['function', 'end', 'if', 'elseif', 'else', 'for', 'while', 'switch', 'case', 'otherwise', 'try', 'catch', 'global', 'clear', 'return', 'break', 'continue', 'export', 'run', 'exit', 'quit', 'list_libraries', 'whos', 'clc']
        BUILTINS = ['disp', 'error', 'sin', 'cos', 'tan', 'exp', 'log', 'sqrt', 'pi', 'eye', 'zeros', 'ones', 'cell', 'median', 'quantile', 'var', 'std', 'num2str', 'mat2str', 'sprintf', 'plot', 'scatter_plot', 'hist_plot', 'plot_matrix', 'title', 'xlabel', 'ylabel', 'grid', 'hold', 'clf', 'length', 'size', 'reshape', 'numel', 'unique', 'inv', 'det', 'eig', 'svd', 'linspace', 'logspace', 'meshgrid', 'randperm', 'abs', 'round', 'floor', 'ceil', 'fix', 'rem', 'mod', 'syms', 'factorial', 'randn', 'rand', 'diag', 'plot_nn', 'inf', 'Inf', 'nan', 'NaN', 'eps', 'i', 'j', 'realmax', 'realmin', 'fill', 'xlim', 'ylim']
        
        # Context-aware triggers for path completion
        path_commands = ('run ', 'cd ', 'ls ', 'dir ', 'mkdir ', 'rm ', 'cp ', 'mv ', '!', 'addpath(', 'load(', 'save(', 'export ', 'import ', 'pwd ', 'cat ')
        is_path_context = any(stripped_line.startswith(cmd) for cmd in path_commands) or '/' in text or '\\' in text or text.startswith('.')
        
        if is_path_context:
            # Strip leading/trailing quotes for path search
            clean_text = text.lstrip("'\"").rstrip("'\"")
            
            # Handle path completion relative to session CWD
            search_path = self.cwd
            if '/' in clean_text or '\\' in clean_text:
                dirname = os.path.dirname(clean_text)
                if dirname:
                    try:
                        # Handle both relative and absolute paths
                        potential_path = pathlib.Path(dirname)
                        if potential_path.is_absolute():
                            search_path = potential_path.resolve()
                        else:
                            search_path = (self.cwd / dirname).resolve()
                        text_prefix = os.path.basename(clean_text)
                    except Exception:
                        return []
                else:
                    text_prefix = clean_text
            else:
                text_prefix = clean_text

            if not search_path.exists() or not search_path.is_dir():
                return []

            results = []
            try:
                for f in search_path.iterdir():
                    if f.name.startswith(text_prefix):
                        rel_name = f.name
                        if f.is_dir():
                            rel_name += '/'
                        
                        # Reconstruct the completion string
                        if '/' in clean_text or '\\' in clean_text:
                            dirname = os.path.dirname(clean_text)
                            sep = '/' if '/' in clean_text else '\\'
                            completion = dirname + sep + rel_name
                        else:
                            completion = rel_name
                            
                        # If the original text had a quote, keep it if it was only at the start
                        if text.startswith("'") and not text.endswith("'"):
                            results.append("'" + completion)
                        elif text.startswith('"') and not text.endswith('"'):
                            results.append('"' + completion)
                        else:
                            results.append(completion)
            except Exception:
                pass
                
            return sorted(results)
        else:
            # Symbol completion
            vars_snapshot = self._get_variables()
            workspace_vars = list(vars_snapshot.keys())
            
            # M-file completions from search paths
            m_files = set()
            for path in self.engine.search_paths:
                if path.exists():
                    for p in path.glob('*.m'):
                        m_files.add(p.stem)
            
            all_symbols = KEYWORDS + BUILTINS + workspace_vars + list(m_files)
            return sorted([w for w in all_symbols if w.startswith(text)])

    def _get_variables(self):
        vars_snap = {}
        import types
        
        for k, v in self.globals.items():
            if k.startswith('_') or k in ('np', 'plt', 'ans', 'addpath'):
                continue
            
            # Skip core modules
            if isinstance(v, types.ModuleType):
                continue
                
            # Keep only user-defined functions or non-callable values
            if callable(v):
                # If it's a built-in runtime function, skip it
                if k in self._runtime_names:
                    continue
                # If it's a python builtin or np function, skip it
                mod_name = getattr(v, '__module__', '') or ''
                if mod_name == 'builtins' or 'numpy' in mod_name:
                    continue
                # If it doesn't have source code (compiled/builtin), likely not user-defined
                if not hasattr(v, '__code__'):
                    continue
            
            # Determine Class (MATLAB style)
            dtype = type(v).__name__
            if hasattr(v, 'dtype'):
                cls = v.dtype.name
            else:
                cls = dtype
                
            # MATLAB-ify class names
            if cls == 'float64': cls = 'double'
            elif cls == 'int64': cls = 'int'
            elif cls == 'str': cls = 'char'
            elif cls == 'bool': cls = 'logical'
            
            # Determine Size
            if hasattr(v, 'shape'):
                shape = v.shape
                if not shape: # Scalar array
                    size_str = "1x1"
                    shape_list = [1, 1]
                else:
                    size_str = 'x'.join(map(str, shape))
                    shape_list = list(shape)
            elif isinstance(v, (list, tuple)):
                size_str = f"1x{len(v)}"
                shape_list = [1, len(v)]
            else:
                size_str = "1x1"
                shape_list = [1, 1]
                
            # Determine Bytes (Optimized)
            try:
                if hasattr(v, 'nbytes'):
                    bytes_count = int(v.nbytes)
                else:
                    # sys.getsizeof is okay for simple types
                    bytes_count = sys.getsizeof(v)
            except:
                bytes_count = 0

            # Only generate preview if needed/asked, or keep it short
            preview = str(v)
            if len(preview) > 100:
                 preview = preview[:100] + "..."
            
            vars_snap[k] = {
                'name': k,
                'dtype': cls,
                'shape': shape_list,
                'preview': preview,
                'size': size_str,
                'bytes': bytes_count
            }
        return vars_snap

    def _save_workspace(self):
        # Ensure workspace directory exists before saving
        self.workspace_path.mkdir(parents=True, exist_ok=True)
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

    # Synchronous wrappers for FFI/C interop (calls async methods via asyncio.run)
    def run_code_sync(self, code: str, timeout: Optional[float] = 30.0) -> ExecutionResult:
        """Synchronous wrapper for async run_code method. For use with FFI bridges."""
        try:
            return asyncio.run(self.run_code(code, timeout))
        except RuntimeError as e:
            # If there's already an event loop, use it
            if "asyncio.run() cannot be called from a running event loop" in str(e):
                import nest_asyncio
                nest_asyncio.apply()
                return asyncio.run(self.run_code(code, timeout))
            raise

    def fetch_variables_sync(self) -> Dict[str, Any]:
        """Synchronous wrapper for async fetch_variables method."""
        try:
            return asyncio.run(self.fetch_variables())
        except RuntimeError:
            import nest_asyncio
            nest_asyncio.apply()
            return asyncio.run(self.fetch_variables())