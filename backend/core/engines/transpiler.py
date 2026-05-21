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
        
        # Set initial CWD to sample folder in web mode
        if os.environ.get('UNILAB_WEB_MODE') == '1':
            project_root = pathlib.Path(__file__).resolve().parents[3]
            sample_dir = project_root / 'sample'
            self.cwd = sample_dir if sample_dir.exists() else self.workspace_path
        else:
            self.cwd = self.workspace_path

        self.search_paths = [self.cwd, self.workspace_path]
        
        # Add libraries to search path
        backend_dir = pathlib.Path(__file__).resolve().parents[2]
        libs_dir = backend_dir / "libraries"
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
            'inf': np.inf,
            'Inf': np.inf,
            'nan': np.nan,
            'NaN': np.nan,
            'pi': np.pi,
            'eps': np.finfo(float).eps,
            'i': 1j,
            'j': 1j,
            'realmax': np.finfo(float).max,
            'realmin': np.finfo(float).tiny,
            'true': True,
            'false': False,
            'struct': runtime.unilab_struct,
        })
        
        # Inject runtime functions
        for name in dir(runtime):
            if not name.startswith('_'):
                self.globals[name] = getattr(runtime, name)
        
        # Ensure builtins don't shadow runtime functions
        self.globals['abs'] = runtime.unilab_abs
        self.globals['round'] = runtime.round
        self.globals['floor'] = runtime.floor
        self.globals['ceil'] = runtime.ceil
        self.globals['max'] = runtime.max
        self.globals['min'] = runtime.min
        self.globals['sum'] = runtime.sum
        
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
        stripped_code = code.strip().rstrip(';')
        
        # Ensure we are in the correct directory for this session
        old_cwd = os.getcwd()
        os.chdir(self.cwd)
        
        # Set context-safe workspace path for the runtime
        from ..runtime import unilab_workspace_ctx
        token = unilab_workspace_ctx.set(str(self.workspace_path))
        
        try:
            # --- Shell Command Handling ---
            import subprocess
            import shlex
            
            parts = stripped_code.split()
            if not parts:
                return ExecutionResult(True, "", "", 0, 0.0, self._get_variables(), [])
                
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

            # 2. Handle 'ls', 'pwd', 'dir', 'mkdir', 'rm', 'cp', 'mv', 'cat'
            if cmd in ('ls', 'dir', 'pwd', 'mkdir', 'rm', 'cp', 'mv', 'cat') or stripped_code.startswith('!'):
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

            # Auto-help: if user types a single function name without () or args
            if stripped_code and re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', stripped_code):
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
                
                # Command-like functions should be executed, not helped
                is_command = stripped_code.lower() in ('whos', 'clc', 'list_libraries')
                
                if is_func and not is_var and not is_command:
                    return await self._get_help(stripped_code)

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
                
                # Re-verify critical constants are available
                critical_constants = {
                    'pi': np.pi,
                    'inf': np.inf,
                    'Inf': np.inf,
                    'nan': np.nan,
                    'NaN': np.nan,
                    'eps': np.finfo(float).eps,
                    'i': 1j,
                    'j': 1j,
                    'realmax': np.finfo(float).max,
                    'realmin': np.finfo(float).tiny,
                }
                self.globals.update(critical_constants)
                
                # Prepare execution environment
                out = io.StringIO()
                err = io.StringIO()
                
                success = True
                try:
                    # We use a custom globals dict to persist state between runs in the same session
                    with redirect_stdout(out), redirect_stderr(err):
                        exec(python_code, self.globals)
                    
                    # If code changed directory, update persistent CWD
                    self.cwd = pathlib.Path(os.getcwd()).resolve()
                    
                    # Save workspace after successful execution
                    self._save_workspace()
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
                    render_func = self.globals.get('render_image_terminal')

                    # Deduplicate: only keep the last update for each figure number in this execution.
                    # This prevents intermediate plots (e.g. from plot(), then title(), then xlabel())
                    # from being displayed as separate images.
                    plot_markers = {}
                    for idx in plot_indices:
                        line = stdout_lines[idx]
                        parts = line.split("::GRAPHICAL_PLOT::", 1)[1].split("::FIG::")
                        filename = parts[0].strip()

                        fig_info = parts[1].split("::VER::") if len(parts) > 1 else ["default"]
                        fig_num = fig_info[0].strip()
                        fig_ver = fig_info[1].strip() if len(fig_info) > 1 else "1"

                        # Key by fig_num to only keep the final state of each figure
                        plot_markers[fig_num] = (idx, filename)

                    final_render_indices = {v[0] for v in plot_markers.values()}

                    import base64
                    # Sort markers by their original index to maintain chronological order
                    sorted_markers = sorted(plot_markers.items(), key=lambda x: x[1][0])

                    for fig_num, (idx, filename) in sorted_markers:
                        plots.append(filename)
                        data_3d_entry = None

                        if os.environ.get('UNILAB_WEB_MODE') == '1':
                            # Try workspace then CWD
                            p = self.workspace_path / filename
                            if not p.exists(): p = self.cwd / filename

                            if p.exists():
                                try:
                                    b64 = base64.b64encode(p.read_bytes()).decode('utf-8')
                                    plot_data_b64.append(f"data:image/png;base64,{b64}")
                                except Exception as e:
                                    print(f"Base64 conversion error for {filename}: {e}")

                        # Check for 3D data sidecar
                        if filename:
                            data3d_filename = os.path.splitext(filename)[0] + '.3d.json'
                            data3d_path = self.workspace_path / data3d_filename
                            if not data3d_path.exists(): data3d_path = self.cwd / data3d_filename

                            if data3d_path.exists():
                                try:
                                    with open(str(data3d_path), 'r') as f:
                                        data_3d_entry = json.load(f)
                                except Exception as e:
                                    print(f"Error loading 3D data sidecar {data3d_filename}: {e}")

                        plot_3d_data.append(data_3d_entry)

                    # Clean up stdout markers
                    for idx in plot_indices:
                        if idx in final_render_indices and render_func and os.environ.get('UNILAB_WEB_MODE') != '1':
                            line = stdout_lines[idx]
                            filename = line.split("::GRAPHICAL_PLOT::", 1)[1].split("::FIG::")[0].strip()
                            p = self.workspace_path / filename
                            if not p.exists(): p = self.cwd / filename
                            render_out = render_func(str(p))
                            stdout_lines[idx] = render_out if render_out else ""
                        else:
                            stdout_lines[idx] = ""

                return ExecutionResult(
                    success=success,
                    stdout="\n".join(l for l in stdout_lines if l or l == ""),
                    stderr=err.getvalue(),
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
        BUILTINS = ['disp', 'sin', 'cos', 'tan', 'exp', 'log', 'sqrt', 'pi', 'eye', 'zeros', 'ones', 'cell', 'median', 'quantile', 'var', 'std', 'num2str', 'mat2str', 'sprintf', 'plot', 'scatter_plot', 'hist_plot', 'plot_matrix', 'title', 'xlabel', 'ylabel', 'grid', 'hold', 'clf', 'length', 'size', 'reshape', 'numel', 'unique', 'inv', 'det', 'eig', 'svd', 'linspace', 'logspace', 'meshgrid', 'randperm', 'abs', 'round', 'floor', 'ceil', 'fix', 'rem', 'mod', 'syms', 'factorial', 'randn', 'rand', 'diag', 'plot_nn', 'inf', 'Inf', 'nan', 'NaN', 'eps', 'i', 'j', 'realmax', 'realmin']
        
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
            for path in self.search_paths:
                if path.exists():
                    for p in path.glob('*.m'):
                        m_files.add(p.stem)
            
            all_symbols = KEYWORDS + BUILTINS + workspace_vars + list(m_files)
            return sorted([w for w in all_symbols if w.startswith(text)])

    def _get_variables(self):
        vars_snap = {}
        for k, v in self.globals.items():
            if k.startswith('_') or k in dir(runtime) or k == 'np' or k == 'ans' and v is None:
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
            elif hasattr(v, '__len__') and not isinstance(v, (str, dict)):
                size_str = f"1x{len(v)}"
                shape_list = [1, len(v)]
            else:
                size_str = "1x1"
                shape_list = [1, 1]
                
            # Determine Bytes
            try:
                if hasattr(v, 'nbytes'):
                    bytes_count = int(v.nbytes)
                else:
                    bytes_count = sys.getsizeof(v)
            except:
                bytes_count = 0

            preview = str(v)
            if isinstance(v, np.ndarray) and v.size > 50:
                preview = str(v.flatten()[:50]) + "..."
            
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
