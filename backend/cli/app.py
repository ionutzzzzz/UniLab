import asyncio
import argparse
import pathlib
import sys
import os
import re
import faulthandler
import time
from typing import Optional, Dict, Any, List

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

import numpy as np

try:
    faulthandler.enable()
except Exception:
    pass

# Setup paths to ensure we can import core modules
current_dir = pathlib.Path(__file__).resolve().parent
project_root = current_dir.parent.parent # Project root is two levels up from backend/cli/app.py
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

try:
    import readline
except ImportError:
    readline = None

from backend.core.unilab_core import UniLabCore
from backend.core.models import BackendConfig

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

def print_error(msg: str):
    """Prints a message in pastel red to stdout."""
    print(f"\x1b[38;2;255;105;97mError: {msg}\x1b[0m", file=sys.stderr)

def print_warning(msg: str):
    """Prints a message in pastel yellow to stdout."""
    print(f"\x1b[38;2;253;253;150mWarning: {msg}\x1b[0m")

class BrailleCanvas:
    """A high-resolution canvas using Braille characters (2x4 dots per character)."""
    def __init__(self, char_width, char_height):
        self.char_width = char_width
        self.char_height = char_height
        self.width = char_width * 2
        self.height = char_height * 4
        self.dots = np.zeros((self.height, self.width), dtype=bool)
        self.colors = {} # (char_x, char_y) -> ansi_color

    def set_dot(self, x, y, color=None):
        if 0 <= x < self.width and 0 <= y < self.height:
            self.dots[int(y), int(x)] = True
            if color:
                cx, cy = int(x // 2), int(y // 4)
                self.colors[(cx, cy)] = color

    def get_char(self, cx, cy):
        # Braille dot mapping:
        # 1 4
        # 2 5
        # 3 6
        # 7 8
        val = 0
        for dy in range(4):
            for dx in range(2):
                if 0 <= cy*4+dy < self.height and 0 <= cx*2+dx < self.width:
                    if self.dots[cy*4+dy, cx*2+dx]:
                        mask = 0
                        if dx == 0:
                            if dy == 0: mask = 1
                            elif dy == 1: mask = 2
                            elif dy == 2: mask = 4
                            elif dy == 3: mask = 64
                        else:
                            if dy == 0: mask = 8
                            elif dy == 1: mask = 16
                            elif dy == 2: mask = 32
                            elif dy == 3: mask = 128
                        val |= mask
        
        if val == 0: return " "
        char = chr(0x2800 + val)
        color = self.colors.get((cx, cy))
        return f"{color}{char}\x1b[0m" if color else char

def render_ascii_plots():
    """Renders all current matplotlib figures as Ultra-High-Quality Braille/Unicode art."""
    try:
        import matplotlib.pyplot as plt
        import matplotlib.patches
        import shutil
        
        # Access runtime for its ASCII plotting utilities
        try:
            from backend.core import runtime
        except ImportError:
            try:
                from core import runtime
            except ImportError:
                return

        fignums = plt.get_fignums()
        if not fignums:
            return

        term_size = shutil.get_terminal_size((80, 24))
        
        def get_ansi_color(m_color):
            if not m_color: return ""
            import matplotlib.colors as mcolors
            try:
                rgb = mcolors.to_rgb(m_color)
                r, g, b = rgb
                if r > 0.8 and g > 0.8 and b > 0.8: return "\x1b[97m"
                if r > 0.5 and g < 0.3 and b < 0.3: return "\x1b[91m"
                if r < 0.3 and g > 0.5 and b < 0.3: return "\x1b[92m"
                if r < 0.3 and g < 0.3 and b > 0.5: return "\x1b[94m"
                if r > 0.5 and g > 0.5 and b < 0.3: return "\x1b[93m"
                if r > 0.5 and g < 0.3 and b > 0.5: return "\x1b[95m"
                if r < 0.3 and g > 0.5 and b > 0.5: return "\x1b[96m"
            except: pass
            return ""

        for fig_num in fignums:
            fig = plt.figure(fig_num)
            axes = fig.get_axes()
            if not axes: continue

            num_axes = len(axes)
            can_side_by_side = num_axes > 1 and term_size.columns > 140
            
            fig_title = f"UniLab Figure {fig_num}"
            print(f"\n\x1b[1;35m{fig_title.center(term_size.columns)}\x1b[0m")

            for ax_idx, ax in enumerate(axes):
                title = ax.get_title()
                xlabel = ax.get_xlabel()
                ylabel = ax.get_ylabel()
                
                width = min(120, term_size.columns - 25)
                height = min(40, term_size.lines - 12)
                
                images = ax.get_images()
                if images:
                    print(f"\n\x1b[1;36m{title.center(width + 12)}\x1b[0m")
                    for img in images:
                        data = img.get_array()
                        m_min, m_max = np.min(data), np.max(data)
                        if m_max == m_min: m_max += 1
                        
                        ramp = " .:-=+*#%@"
                        res = [" " * 11 + "┌" + "─" * width + "┐"]
                        for r in range(height):
                            row = " " * 11 + "│"
                            orig_r = int(r * data.shape[0] / height)
                            for c in range(width):
                                orig_c = int(c * data.shape[1] / width)
                                val = data[orig_r, orig_c]
                                ratio = (val - m_min) / (m_max - m_min)
                                char = ramp[int(ratio * (len(ramp) - 1))]
                                if ratio < 0.2: color = "\x1b[34m"
                                elif ratio < 0.4: color = "\x1b[36m"
                                elif ratio < 0.6: color = "\x1b[32m"
                                elif ratio < 0.8: color = "\x1b[33m"
                                else: color = "\x1b[31m"
                                row += f"{color}{char}\x1b[0m"
                            res.append(row + "│")
                        res.append(" " * 11 + "└" + "─" * width + "┘")
                        print("\n".join(res))
                    continue

                b_canvas = BrailleCanvas(width, height)
                xmin, xmax = ax.get_xlim()
                ymin, ymax = ax.get_ylim()
                
                grid_on = False
                try: grid_on = ax.xaxis._gridOnMajor or ax.yaxis._gridOnMajor
                except: pass
                
                char_grid = [[' ' for _ in range(width)] for _ in range(height)]
                if grid_on:
                    for tick in ax.get_xticks():
                        if xmin < tick < xmax:
                            px = int((tick - xmin) / (xmax - xmin) * (width - 1))
                            if 0 <= px < width:
                                for sy in range(height): char_grid[sy][px] = '\x1b[90m┆\x1b[0m'
                    for tick in ax.get_yticks():
                        if ymin < tick < ymax:
                            py = height - 1 - int((tick - ymin) / (ymax - ymin) * (height - 1))
                            if 0 <= py < height:
                                for sx in range(width):
                                    if char_grid[py][sx] == ' ': char_grid[py][sx] = '\x1b[90m┄\x1b[0m'

                series_stats = []

                for idx, line in enumerate(ax.get_lines()):
                    xdata, ydata = line.get_xdata(), line.get_ydata()
                    color = get_ansi_color(line.get_color())
                    lbl = line.get_label() or f"S{idx+1}"
                    
                    if len(ydata) > 0:
                        series_stats.append({
                            'label': lbl, 'color': color, 'marker': '⠿',
                            'max': np.max(ydata), 'min': np.min(ydata), 'mean': np.mean(ydata)
                        })

                    for i in range(len(xdata)):
                        bx = (xdata[i] - xmin) / (xmax - xmin) * (b_canvas.width - 1)
                        by = (b_canvas.height - 1) - (ydata[i] - ymin) / (ymax - ymin) * (b_canvas.height - 1)
                        
                        if line.get_linestyle() not in ('None', '', None) and i > 0:
                            px2 = (xdata[i-1] - xmin) / (xmax - xmin) * (b_canvas.width - 1)
                            py2 = (b_canvas.height - 1) - (ydata[i-1] - ymin) / (ymax - ymin) * (b_canvas.height - 1)
                            
                            dist = int(max(abs(bx - px2), abs(by - py2)) * 2) + 1
                            for step in range(dist):
                                f = step / dist
                                b_canvas.set_dot(px2 + f*(bx-px2), py2 + f*(by-py2), color)
                        else:
                            b_canvas.set_dot(bx, by, color)

                for idx, coll in enumerate(ax.collections):
                    color = get_ansi_color(coll.get_facecolor()[0] if len(coll.get_facecolor()) > 0 else None)
                    if hasattr(coll, 'get_offsets'):
                        for off in coll.get_offsets():
                            bx = (off[0] - xmin) / (xmax - xmin) * (b_canvas.width - 1)
                            by = (b_canvas.height - 1) - (off[1] - ymin) / (ymax - ymin) * (b_canvas.height - 1)
                            b_canvas.set_dot(bx, by, color)
                            b_canvas.set_dot(bx+1, by, color)
                            b_canvas.set_dot(bx, by+1, color)
                            b_canvas.set_dot(bx+1, by+1, color)

                print(f"\n\x1b[1;36m{title.center(width + 12)}\x1b[0m")
                y_label_mid = height // 2
                res = []
                for r in range(height):
                    prefix = "           "
                    char_edge = "│"
                    if r == 0: prefix, char_edge = f" {ymax:9.2f} ", "┐"
                    elif r == height - 1: prefix, char_edge = f" {ymin:9.2f} ", "┘"
                    elif r == y_label_mid and ylabel: prefix = f"{ylabel[:10]:>10} "
                    elif (height - 1 - r) % (height // 4 or 1) == 0:
                        val = ymin + (height - 1 - r) / (height - 1) * (ymax - ymin)
                        prefix, char_edge = f" {val:9.2f} ", "┤"
                    
                    line_chars = []
                    for c in range(width):
                        b_char = b_canvas.get_char(c, r)
                        if b_char == " ": line_chars.append(char_grid[r][c])
                        else: line_chars.append(b_char)
                    
                    res.append(f"{prefix}{char_edge}" + "".join(line_chars) + "│")
                
                bottom_line = "           └"
                for j in range(width): bottom_line += "┬" if j % (width // 4 or 1) == 0 else "─"
                res.append(bottom_line + "┘")
                
                x_vals = "            "
                for j in range(5):
                    pos = int(j/4 * (width - 1))
                    val_str = f"{xmin + j/4 * (xmax - xmin):.2f}"
                    padding = pos - (len(x_vals) - 12)
                    if padding > 0: x_vals += " " * padding + val_str
                res.append(x_vals)
                if xlabel: res.append(" " * (12 + width // 2 - len(xlabel) // 2) + f"\x1b[3m{xlabel}\x1b[0m")
                
                if series_stats:
                    print("\n".join(res))
                    print("\n" + " " * 12 + "\x1b[1mLegend & Statistics:\x1b[0m")
                    for s in series_stats:
                        print(f" " * 12 + f"{s['color']}{s['marker']}\x1b[0m {s['label']:12} | Min: {s['min']:.2f} | Max: {s['max']:.2f} | Mean: {s['mean']:.2f}")

            plt.close(fig)
    except Exception as e:
        pass

def show_plots():
    """Decides whether to show plots in a window or as ASCII in terminal."""
    try:
        import matplotlib
        import matplotlib.pyplot as plt
        if plt.get_fignums():
            if matplotlib.get_backend().lower() == 'agg':
                render_ascii_plots()
            else:
                plt.show()
    except Exception:
        pass

def update_m_file_cache():
    global _m_file_cache, _last_cache_update
    now = time.time()
    if now - _last_cache_update < 5:
        return
    
    m_files = set()
    try:
        for p in pathlib.Path('.').glob('*.m'):
            m_files.add(p.stem)
        
        libs_dir = project_root / "backend" / "libraries"
        if libs_dir.exists():
            for p in libs_dir.rglob('*.m'):
                m_files.add(p.stem)
    except OSError as e:
        print_warning(f"Could not update function cache: {e}")
    except Exception as e:
        print_warning(f"Unexpected error updating cache: {e}")
    
    _m_file_cache = list(m_files)
    _last_cache_update = now


async def run_UniLab_script(script_path: str, engine_name: str = "transpiler"):
    path = pathlib.Path(script_path)
    if not path.exists():
        print_error(f"Script '{script_path}' not found.")
        return

    workspace_root = pathlib.Path("./.console_workspaces/test_runs").resolve()
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
            show_plots()
        except Exception:
            pass
                
    except Exception as e:
        print_error(f"An unexpected error occurred during execution: {e}")
    finally:
        await core.stop()

async def run_console(engine_name: str = "transpiler", command: Optional[str] = None):
    try:
        workspace_root = pathlib.Path("./.console_workspaces").resolve()
        workspace_root.mkdir(exist_ok=True)
        # Verify write permission
        test_file = workspace_root / ".write_test"
        test_file.touch()
        test_file.unlink()
    except (OSError, PermissionError):
        workspace_root = (pathlib.Path.home() / ".unilab" / ".console_workspaces").resolve()
        try:
            workspace_root.mkdir(parents=True, exist_ok=True)
        except OSError as e:
            print_error(f"Could not create console workspace: {e}")
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
        session = await core.create_session(username="console_user", engine=engine_name)
    except Exception as e:
        print_error(f"Failed to create session: {e}")
        await core.stop()
        return

    history_file = workspace_root / ".unilab_history"
    if not command and readline:
        def unilab_completer(text, state):
            line = readline.get_line_buffer() if readline else ""
            stripped_line = line.lstrip()
            
            # Context-aware triggers for path completion
            path_commands = ('run ', 'cd ', 'ls ', 'dir ', 'mkdir ', 'rm ', 'cp ', 'mv ', '!', 'addpath(', 'load(', 'save(', 'export ')
            is_path_context = any(stripped_line.startswith(cmd) for cmd in path_commands) or '/' in text or '\\' in text or text.startswith('.')
            
            if is_path_context:
                import glob
                if (stripped_line.startswith('run ') or stripped_line.startswith('!')) and not text:
                    options = [f for f in glob.glob('*.m')]
                else:
                    options = glob.glob(text + '*')
                options = [f + '/' if pathlib.Path(f).is_dir() else f for f in options]
            else:
                options = []
                engine = core.engines.get(session.session_id)
                if engine and hasattr(engine, 'complete'):
                    options = engine.complete(text, line)
                
                if not options:
                    update_m_file_cache()
                    all_symbols = KEYWORDS + BUILTINS + workspace_vars + _m_file_cache
                    options = [w for w in all_symbols if w.startswith(text)]
            
            options = sorted(list(set(options)))
            if state < len(options):
                return options[state]
            return None

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
    
    try:
        
        is_tty = sys.stdin.isatty() and not command
        if is_tty:
            print("\n" + "="*60)
            print(" \U0001F9EA UniLab Interactive Console")
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
                                    show_plots()
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
                        show_plots()
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

def run_rust_cli(script_path: str):
    import subprocess
    path = pathlib.Path(script_path)
    if not path.exists():
        print_error(f"Script '{script_path}' not found.")
        return

    # Check for release binary first
    bin_paths = [
        project_root / "target" / "release" / "unilab_cli",
        project_root / "target" / "debug" / "unilab_cli",
        project_root / "backend" / "target" / "release" / "unilab_cli",
        project_root / "backend" / "target" / "debug" / "unilab_cli",
    ]
    
    executable = None
    for p in bin_paths:
        if p.exists() and os.access(p, os.X_OK):
            executable = p
            break
            
    if executable:
        print(f"Running compiled Rust CLI: {executable}")
        subprocess.run([str(executable), str(path)])
    else:
        print("Compiled Rust CLI binary not found. Running via 'cargo run'...")
        try:
            subprocess.run(["cargo", "run", "--release", "-p", "unilab_cli", "--", str(path)], cwd=str(project_root / "backend"))
        except FileNotFoundError:
            print_error("Neither compiled 'unilab_cli' binary nor 'cargo' command found.")

def main():
    parser = argparse.ArgumentParser(description="UniLab: Scientific Simulation & Modeling Platform")
    subparsers = parser.add_subparsers(dest="command", help="Commands")

    run_parser = subparsers.add_parser("run", help="Run a UniLab (.m) script")
    run_parser.add_argument("script", help="Path to the script file")
    run_parser.add_argument("--engine", default="rust", choices=["transpiler", "rust"], help="Execution engine to use")

    console_parser = subparsers.add_parser("console", help="Launch interactive console")
    console_parser.add_argument("--engine", default="rust", choices=["transpiler", "rust"], help="Execution engine to use")
    console_parser.add_argument("cmd_args", nargs=argparse.REMAINDER, help="Terminal command to execute (optional)")

    rust_cli_parser = subparsers.add_parser("rust-cli", help="Execute script using native Rust compiler")
    rust_cli_parser.add_argument("script", help="Path to the script file")

    if len(sys.argv) == 1:
        args = parser.parse_args(["console"])
    elif sys.argv[0].endswith("__main__.py") or "backend" in sys.argv[0]:
        # Handle python -m backend case
        args = parser.parse_args()
    else:
        args = parser.parse_args()

    try:
        if args.command == "run":
            asyncio.run(run_UniLab_script(args.script, args.engine))
        elif args.command == "console":
            cmd_str = " ".join(args.cmd_args) if args.cmd_args else None
            asyncio.run(run_console(args.engine, cmd_str))
        elif args.command == "rust-cli":
            run_rust_cli(args.script)
        else:
            parser.print_help()
    except KeyboardInterrupt:
        print("\nOperation cancelled.")
    except Exception as e:
        print_error(f"Fatal error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
