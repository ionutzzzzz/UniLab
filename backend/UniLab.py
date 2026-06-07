import asyncio
import argparse
import pathlib
import sys
import os

# Fix for Qt stability on some Linux distros
os.environ['GTK_MODULES'] = ''
os.environ['QT_QPA_PLATFORMTHEME'] = ''
os.environ['QT_STYLE_OVERRIDE'] = 'Fusion'

# Headless environment detection
if sys.platform.startswith('linux') and not os.environ.get('DISPLAY'):
    os.environ['QT_QPA_PLATFORM'] = 'offscreen'
    # Try to use a non-interactive matplotlib backend as well
    try:
        import matplotlib
        matplotlib.use('Agg')
    except:
        pass

import re
import faulthandler
faulthandler.enable()
import time
from typing import Optional

def highlight_syntax(code: str) -> str:
    """Applies TrueColor pastel ANSI color codes to UniLab/MATLAB syntax."""
    # Pastel RGB Colors
    PASTEL_PURPLE = "\x1b[38;2;191;148;228m" # Keywords
    PASTEL_CYAN   = "\x1b[38;2;137;207;240m" # Functions
    PASTEL_YELLOW = "\x1b[38;2;253;253;150m" # Strings
    PASTEL_GRAY   = "\x1b[38;2;169;169;169m" # Comments
    RESET = "\x1b[0m"

    keywords = r'\b(function|end|if|elseif|else|for|while|switch|case|otherwise|try|catch|global|clear|return|break|continue)\b'
    
    # Highlight comments
    if '%' in code:
        parts = code.split('%', 1)
        code = parts[0]
        comment = f"{PASTEL_GRAY}%{parts[1]}{RESET}"
    else:
        comment = ""
    
    # Highlight strings
    code = re.sub(r"('[^'\n]*')", f"{PASTEL_YELLOW}\\1{RESET}", code)
    
    # Highlight keywords
    code = re.sub(keywords, f"{PASTEL_PURPLE}\\1{RESET}", code)
    
    # Highlight functions calls
    code = re.sub(r'\b([a-zA-Z_][a-zA-Z0-9_]*)\s*(?=\()', f"{PASTEL_CYAN}\\1{RESET}", code)

    return code + comment

# Vocabulary for Tab Autocomplete
KEYWORDS = ['function', 'end', 'if', 'elseif', 'else', 'for', 'while', 'switch', 'case', 'otherwise', 'try', 'catch', 'global', 'clear', 'return', 'break', 'continue', 'export', 'run', 'exit', 'quit', 'list_libraries', 'whos', 'clc']
BUILTINS = [
    'disp', 'sin', 'cos', 'tan', 'tanh', 'relu', 'exp', 'log', 'sqrt', 'pi', 'eye', 'zeros', 'ones', 'cell', 
    'median', 'quantile', 'var', 'std', 'num2str', 'mat2str', 'sprintf', 
    'plot', 'scatter_plot', 'hist_plot', 'plot_matrix', 'title', 'xlabel', 'ylabel', 
    'grid', 'hold', 'clf', 'length', 'size', 'reshape', 'numel', 'unique', 
    'inv', 'det', 'eig', 'svd', 'linspace', 'logspace', 'meshgrid', 'randperm', 
    'abs', 'round', 'floor', 'ceil', 'fix', 'rem', 'mod', 'sum', 'prod', 'syms', 'factorial', 
    'randn', 'rand', 'diag', 'plot_nn', 'inf', 'Inf', 'nan', 'NaN', 'eps', 'i', 'j',
    'realmax', 'realmin', 'ode45', 'ode45_custom'
]
workspace_vars = []
_m_file_cache = []
_last_cache_update = 0

def print_error(msg: str):
    """Prints a message in pastel red to stdout."""
    print(f"\x1b[38;2;255;105;97mError: {msg}\x1b[0m", file=sys.stderr)

def print_warning(msg: str):
    """Prints a message in pastel yellow to stdout."""
    print(f"\x1b[38;2;253;253;150mWarning: {msg}\x1b[0m")

def update_m_file_cache():
    global _m_file_cache, _last_cache_update
    now = time.time()
    if now - _last_cache_update < 5: # Cache for 5 seconds
        return
    
    m_files = set()
    try:
        # Scan current directory
        for p in pathlib.Path('.').glob('*.m'):
            m_files.add(p.stem)
        
        # Scan libraries
        libs_dir = pathlib.Path(__file__).resolve().parent / "libraries"
        if libs_dir.exists():
            for p in libs_dir.rglob('*.m'):
                m_files.add(p.stem)
    except OSError as e:
        print_warning(f"Could not update function cache: {e}")
    except Exception as e:
        print_warning(f"Unexpected error updating cache: {e}")
    
    _m_file_cache = list(m_files)
    _last_cache_update = now

def unilab_completer(text, state):
    line = readline.get_line_buffer() if readline else ""
    stripped_line = line.lstrip()
    
    # Context-aware triggers for path completion
    path_commands = ('run ', 'cd ', 'ls ', 'dir ', 'mkdir ', 'rm ', 'cp ', 'mv ', '!', 'addpath(', 'load(', 'save(', 'export ')
    is_path_context = any(stripped_line.startswith(cmd) for cmd in path_commands) or '/' in text or '\\' in text or text.startswith('.')
    
    if is_path_context:
        import glob
        # Handle path completion
        search_text = text
        if (stripped_line.startswith('run ') or stripped_line.startswith('!')) and not text:
            # If nothing typed yet after 'run ', suggest all .m files
            options = [f for f in glob.glob('*.m')]
        else:
            options = glob.glob(text + '*')
            
        # Add trailing slash to directories for easier navigation
        options = [f + '/' if pathlib.Path(f).is_dir() else f for f in options]
    else:
        # Symbol completion
        update_m_file_cache()
        all_symbols = KEYWORDS + BUILTINS + workspace_vars + _m_file_cache
        options = [w for w in all_symbols if w.startswith(text)]
    
    options = sorted(list(set(options))) # Unique and sorted
    if state < len(options):
        return options[state]
    return None

# Setup paths to ensure we can import core modules
current_dir = pathlib.Path(__file__).resolve().parent
project_root = current_dir.parent if (current_dir / "core").exists() else current_dir
sys.path.insert(0, str(project_root))

try:
    import readline
except ImportError:
    readline = None

try:
    from backend.core.unilab_core import UniLabCore
    from backend.core.models import BackendConfig
except ImportError:
    try:
        from core.unilab_core import UniLabCore
        from core.models import BackendConfig
    except ImportError as e:
        print(f"Error: Could not import UniLabCore. Ensure you are in the project root.")
        print(f"Details: {e}")
        print("Please ensure all requirements are installed: pip install -r backend/requirements.txt")
        sys.exit(1)

async def run_UniLab_script(script_path: str, engine_name: str = "transpiler"):
    path = pathlib.Path(script_path)
    if not path.exists():
        print_error(f"Script '{script_path}' not found.")
        return

    workspace_root = pathlib.Path("./test_runs").resolve()
    try:
        workspace_root.mkdir(exist_ok=True)
    except OSError as e:
        print_error(f"Could not create test runs directory: {e}")
        return
    
    cfg = BackendConfig(
        workspace_root=workspace_root,
        use_docker=False
    )
    
    core = UniLabCore(cfg)
    try:
        await core.start()
    except Exception as e:
        print_error(f"Failed to start UniLabCore: {e}")
        return

    try:
        session = await core.create_session(username="script_user", engine=engine_name)
        
        try:
            code = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            print_error(f"Script '{path.name}' contains invalid UTF-8 characters.")
            return
        except OSError as e:
            print_error(f"Could not read script '{path.name}': {e}")
            return
        
        print(f"\n{'='*20} Executing: {path.name} {'='*20}")
        try:
            # Wrap execution in timeout to prevent hanging
            result = await asyncio.wait_for(core.run_code(session.session_id, code), timeout=60.0)
        except asyncio.TimeoutError:
            print_error(f"Execution of '{path.name}' timed out after 60s.")
            return
        
        print(f"\nStatus: {'SUCCESS' if result.success else 'FAILED'}")
        print(f"Duration: {result.duration_s:.4f}s")
        
        if result.stdout:
            print("\n[STDOUT]")
            print(result.stdout.strip())
            
        if result.stderr:
            print("\n[STDERR]")
            print(result.stderr.strip())
            
        if result.variables_snapshot:
            print("\n[Variables]")
            for name, info in result.variables_snapshot.items():
                shape_str = f" {info['shape']}" if info['shape'] else ""
                print(f"  {name:14} : {info['dtype']:10}{shape_str:12} = {info['preview']}")
        
        print(f"\n{'='*60}\n")
        
        try:
            import matplotlib.pyplot as plt
            if plt.get_fignums():
                plt.show()
        except Exception:
            pass
                
    except Exception as e:
        print_error(f"An unexpected error occurred during execution: {e}")
    finally:
        await core.stop()

async def run_console(engine_name: str = "transpiler", command: Optional[str] = None):
    global workspace_vars
    workspace_root = pathlib.Path("./console_workspaces").resolve()
    try:
        workspace_root.mkdir(exist_ok=True)
    except OSError as e:
        print_error(f"Could not create console workspace: {e}")
        return
    
    history_file = workspace_root / ".unilab_history"
    if not command and readline:
        try:
            if history_file.exists():
                readline.read_history_file(str(history_file))
            readline.set_history_length(1000)
            readline.set_completer(unilab_completer)
            # Custom delimiters: exclude / and \ to allow full path completion
            readline.set_completer_delims(' \t\n`~!@#$%^&*()-=+[]{}|;:\'",<>?')
            if 'libedit' in readline.__doc__:
                readline.parse_and_bind("bind ^I rl_complete")
            else:
                readline.parse_and_bind("tab: complete")
        except OSError as e:
            print_warning(f"Could not load history file: {e}")
        except Exception as e:
            print_warning(f"Unexpected error initializing readline: {e}")

    cfg = BackendConfig(
        workspace_root=workspace_root,
        use_docker=False
    )
    
    core = UniLabCore(cfg)
    try:
        await core.start()
    except Exception as e:
        print_error(f"Failed to start UniLabCore: {e}")
        return
    
    try:
        session = await core.create_session(username="console_user", engine=engine_name)
        
        is_tty = sys.stdin.isatty() and not command
        if is_tty:
            print("\n" + "="*60)
            print(f" \U0001F9EA UniLab Interactive Console")
            print(" Type 'exit' or 'quit' to close.")
            print(" Type 'list_libraries();' to explore toolboxes.")
            print("="*60 + "\n")
        
        while True:
            try:
                if command:
                    line = command
                else:
                    if is_tty:
                        line = input(">> ")
                    else:
                        line = sys.stdin.readline()
                        if not line:
                            break
                
                if line.strip().lower() in ('exit', 'quit', 'exit;', 'quit;'):
                    break
                
                if not line.strip():
                    if command: break
                    continue

                # Handle multi-line blocks
                first_word = line.strip().split()[0].lower() if line.strip().split() else ""
                if is_tty and (line.strip().endswith('...') or first_word in ('if', 'for', 'while', 'function', 'switch', 'try')):
                    buffer = [line.rstrip('.').rstrip()]
                    open_blocks = 1 if first_word in ('if', 'for', 'while', 'function', 'switch', 'try') else 0

                    while open_blocks > 0 or line.strip().endswith('...'):
                        sub_line = input("   ")
                        if not sub_line.strip() and not line.strip().endswith('...'):
                            break

                        buffer.append(sub_line)
                        line = sub_line

                        sub_first = sub_line.strip().split()[0].lower() if sub_line.strip().split() else ""
                        if sub_first in ('if', 'for', 'while', 'function', 'switch', 'try'):
                            open_blocks += 1
                        elif sub_first == 'end' or sub_line.strip().endswith('end'):
                            open_blocks -= 1

                    line = "\n".join(buffer)

                if line.strip().lower() in ('clc', 'clc;'):
                    os.system('cls' if os.name == 'nt' else 'clear')
                    if command: break
                    continue

                if is_tty:
                    sys.stdout.write(f"\033[F\033[K>> {highlight_syntax(line)}\n")
                    sys.stdout.flush()

                if line.strip().lower().startswith('export'):
                    parts = line.strip().rstrip(';').split()
                    fmt = 'json'
                    if len(parts) > 1:
                        fmt = parts[1].lower()
                    try:
                        path = await core.export_workspace(session.session_id, format=fmt)
                        print(f"Workspace exported to: {path}")
                    except Exception as e:
                        print_error(f"Export failed: {e}")
                    if command: break
                    continue

                if line.strip().lower().startswith('run '):
                    parts = line.strip().rstrip(';').split(None, 1)
                    if len(parts) > 1:
                        script_name = parts[1].strip()
                        if not script_name.endswith('.m'):
                            script_name += '.m'
                        
                        script_path = pathlib.Path(script_name)
                        if not script_path.exists():
                            # Try looking in the current workspace or common library paths
                            script_path = project_root / script_name
                            
                        if script_path.exists():
                            try:
                                script_code = script_path.read_text(encoding="utf-8")
                                print(f"\x1b[90mRunning script: {script_path.name}\x1b[0m")
                                result = await core.run_code(session.session_id, script_code)
                                
                                # Update variable cache
                                if result.variables_snapshot:
                                    workspace_vars = list(result.variables_snapshot.keys())
                                    
                                if result.stdout:
                                    print(result.stdout.rstrip())
                                if result.stderr:
                                    print(f"Error: {result.stderr.rstrip()}", file=sys.stderr)
                                    
                                try:
                                    import matplotlib.pyplot as plt
                                    if plt.get_fignums():
                                        plt.show()
                                except Exception:
                                    pass
                            except UnicodeDecodeError:
                                print_error(f"Script '{script_path.name}' contains invalid characters.")
                            except OSError as e:
                                print_error(f"Could not read script '{script_path.name}': {e}")
                            except Exception as e:
                                print_error(f"Error running script: {e}")
                        else:
                            print_error(f"Script '{script_name}' not found.")
                    
                    if command: break
                    continue

                if line.strip().startswith('!'):
                    os.system(line.strip()[1:])
                    if command: break
                    continue

                parts = line.strip().split()
                if parts:
                    cmd = parts[0].lower()
                    if cmd in ('ls', 'dir', 'pwd', 'mkdir', 'rm', 'cp', 'mv', 'cd', 'git', 'python', 'pip', 'npm', 'cat'):
                        if cmd == 'cd':
                            try:
                                if len(parts) > 1:
                                    os.chdir(parts[1])
                                else:
                                    print(os.getcwd())
                            except OSError as e:
                                print_error(f"cd failed: {e}")
                        elif cmd == 'cat':
                            if len(parts) > 1:
                                for file_arg in parts[1:]:
                                    try:
                                        file_path = pathlib.Path(file_arg)
                                        if file_path.exists() and file_path.is_file():
                                            content = file_path.read_text(encoding='utf-8', errors='replace')
                                            print(content.rstrip())
                                        else:
                                            print_error(f"cat: {file_arg}: No such file or directory")
                                    except Exception as e:
                                        print_error(f"cat failed: {e}")
                            else:
                                print_error("cat: missing file argument")
                        else:
                            os.system(line.strip())
                
                        if command: break
                        continue

                is_whos = line.strip().lower() in ('whos', 'whos;')
                exec_line = line
                if is_whos and not line.strip().endswith(';'):
                    exec_line = line.strip() + ';'
                
                try:
                    # Added a reasonable timeout for interactive commands
                    result = await asyncio.wait_for(core.run_code(session.session_id, exec_line), timeout=30.0)
                    
                    # Update variable cache for autocomplete
                    if result.variables_snapshot:
                        workspace_vars = list(result.variables_snapshot.keys())
                    
                    if result.stdout:
                        print(result.stdout.rstrip())
                    
                    if result.stderr:
                        print(f"Error: {result.stderr.rstrip()}", file=sys.stderr)
                    
                    if is_whos:
                        if result.variables_snapshot:
                            print("\nName           Size            Class")
                            print("-" * 45)
                            for name, info in result.variables_snapshot.items():
                                shape_str = str(info['shape']) if info['shape'] else "1x1"
                                dtype = info['dtype']
                                print(f"{name:14} {shape_str:15} {dtype}")
                            print("")
                            
                    try:
                        import matplotlib.pyplot as plt
                        if plt.get_fignums():
                            plt.show()
                    except Exception:
                        pass
                except asyncio.TimeoutError:
                    print_error("Command timed out after 30s.")
                except Exception as e:
                    print_error(f"Execution error: {e}")
                
                if command:
                    break

            except EOFError:
                break
            except KeyboardInterrupt:
                if command: break
                print("\nUse 'exit' to quit.")
            except Exception as e:
                print_error(f"Unexpected error in console loop: {e}")
                if command: break

    finally:
        if is_tty and readline:
            try:
                readline.write_history_file(str(history_file))
            except OSError as e:
                print_warning(f"Could not save history file: {e}")
        await core.stop()
        if is_tty:
            print("\nConsole closed.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="UniLab: Scientific Simulation & Modeling Platform")
    subparsers = parser.add_subparsers(dest="command", help="Commands")

    run_parser = subparsers.add_parser("run", help="Run a UniLab (.m) script")
    run_parser.add_argument("script", help="Path to the script file")

    console_parser = subparsers.add_parser("console", help="Launch interactive console")
    console_parser.add_argument("cmd_args", nargs=argparse.REMAINDER, help="Terminal command to execute (optional)")

    if len(sys.argv) == 1:
        args = parser.parse_args(["console"])
    else:
        args = parser.parse_args()

    try:
        if args.command == "run":
            asyncio.run(run_UniLab_script(args.script, "transpiler"))
        elif args.command == "console":
            cmd_str = " ".join(args.cmd_args) if args.cmd_args else None
            asyncio.run(run_console("transpiler", cmd_str))
        else:
            parser.print_help()
    except KeyboardInterrupt:
        print("\nOperation cancelled.")
    except Exception as e:
        print_error(f"Fatal error: {e}")
        sys.exit(1)
