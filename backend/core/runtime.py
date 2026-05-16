import numpy as np
import matplotlib.pyplot as plt
import os
import io
import time
import pathlib
import scipy.signal as signal
from scipy.fft import fft, ifft
from backend.ml.visualizers.nn_vis import plot_neural_network

def disp(x):
    print(x)

def clc():
    os.system('cls' if os.name == 'nt' else 'clear')

def _should_suppress_output(val):
    if val is None: return True
    try:
        # Check if it's a matplotlib object or a list/tuple of them
        module = getattr(type(val), '__module__', '')
        if module.startswith('matplotlib.'): return True
        if isinstance(val, (list, tuple)) and len(val) > 0:
            module0 = getattr(type(val[0]), '__module__', '')
            if module0.startswith('matplotlib.'): return True
    except:
        pass
    return False

def unilab_print_var(name, val):
    if not _should_suppress_output(val):
        print(f"{name} =\n   {val}\n")

def unilab_print_and_save_ans(expr, val):
    global ans
    ans = val
    if val is not None and not _should_suppress_output(val):
        print(f"ans =\n   {val}\n")
    return val

def unilab_call(obj, *args):
    if callable(obj):
        return obj(*args)
    if len(args) == 0: return obj
    if len(args) == 1:
        idx = args[0]
        if isinstance(obj, np.ndarray):
            flat = obj.flatten()
            if isinstance(idx, (int, np.integer, float, np.floating)): return flat[int(idx)-1]
            if isinstance(idx, (list, np.ndarray, slice)): return flat[np.asarray(idx).astype(int) - 1] if not isinstance(idx, slice) else flat[idx]
        if isinstance(obj, (list, tuple)):
            if isinstance(idx, (int, np.integer, float, np.floating)): return obj[int(idx)-1]
    processed = [int(i)-1 if isinstance(i, (int, np.integer, float, np.floating)) else i for i in args]
    return obj[tuple(processed)]

def unilab_mul(a, b):
    if np.isscalar(a) and np.isscalar(b): return a * b
    try: return np.dot(a, b)
    except: return a * b

def unilab_div(a, b):
    if np.isscalar(a) and np.isscalar(b): return a / b
    try: return np.linalg.solve(np.atleast_2d(b).T, np.atleast_2d(a).T).T
    except: return a / b

def unilab_pow(a, b):
    if np.isscalar(a) and np.isscalar(b): return a ** b
    try: return np.linalg.matrix_power(a, b)
    except: return a ** b

def unilab_and(a, b): return np.logical_and(a, b)
def unilab_or(a, b): return np.logical_or(a, b)

def unilab_get(obj, attr):
    if isinstance(obj, dict): return obj.get(attr)
    return getattr(obj, attr)

def unilab_set(obj, val, *args):
    if len(args) == 1:
        idx = args[0]
        idx_adj = int(idx)-1 if isinstance(idx, (int, np.integer, float, np.floating)) else idx
        if isinstance(obj, np.ndarray):
            if obj.ndim == 1: obj[idx_adj] = val
            elif obj.ndim == 2:
                if obj.shape[0] == 1: obj[0, idx_adj] = val
                elif obj.shape[1] == 1: obj[idx_adj, 0] = val
                else: obj.flat[idx_adj] = val
            return obj
        obj[idx_adj] = val
    elif len(args) > 1:
        processed = [int(i)-1 if isinstance(i, (int, np.integer, float, np.floating)) else i for i in args]
        obj[tuple(processed)] = val
    return obj

def unilab_matrix_concat(*rows):
    if not rows: return np.array([])
    
    # If a single list or array is passed, use its elements
    if len(rows) == 1 and isinstance(rows[0], (list, np.ndarray)) and not isinstance(rows[0], str):
        rows = rows[0]
        
    try:
        # Check for MATLAB-style string concatenation ['abc', 'def'] -> 'abcdef'
        if all(isinstance(r, (str, np.str_)) for r in rows):
            return "".join(str(r) for r in rows)
        
        processed_rows = []
        for r in rows:
            if isinstance(r, (list, np.ndarray)): processed_rows.append(np.asarray(r))
            elif isinstance(r, str): processed_rows.append(np.asarray(list(r)))
            else: processed_rows.append(np.asarray([r]))
            
        if len(processed_rows) == 1: 
            if isinstance(rows[0], str): return rows[0]
            return processed_rows[0]
            
        return np.vstack(processed_rows)
    except:
        if all(isinstance(r, (str, np.str_)) for r in rows): return "".join(str(r) for r in rows)
        return np.array(rows)

def unilab_nargin_sum(gen):
    import builtins
    return builtins.sum(gen)

def unilab_cell_concat(*args):
    res = []
    for a in args:
        if isinstance(a, list): res.extend(a)
        else: res.append(a)
    return res

def factorial(n):
    from math import factorial as f
    if isinstance(n, (np.ndarray, list)): return np.array([f(int(i)) for i in n])
    return f(int(n))

def mod(x, y): return np.mod(x, y)

import sympy
def isempty(x):
    if x is None: return True
    if isinstance(x, np.ndarray): return x.size == 0
    if hasattr(x, '__len__'): return len(x) == 0
    return False

def syms(*names):
    if len(names) == 1 and isinstance(names[0], str) and ' ' in names[0]: names = names[0].split()
    return sympy.symbols(names)

def length(x):
    if hasattr(x, '__len__'):
        if isinstance(x, np.ndarray): return max(np.shape(x))
        return len(x)
    return 1

def size(x, dim=None):
    s = np.shape(x)
    if len(s) == 0: s = (1, len(x)) if isinstance(x, (str, bytes)) else (1, 1)
    elif len(s) == 1: s = (1, s[0])
    if dim is not None: return s[dim-1] if dim <= len(s) else 1
    return s

def numel(x):
    if isinstance(x, np.ndarray): return x.size
    if hasattr(x, '__len__'): return len(x)
    return 1

def reshape(x, *args):
    if len(args) == 1 and isinstance(args[0], (list, tuple, np.ndarray)):
        return np.reshape(x, args[0])
    return np.reshape(x, args)

def sum(x, axis=None): return np.sum(x, axis=axis)
def mean(x, axis=None): return np.mean(x, axis=axis)
def min(*args, axis=None):
    if len(args) == 1: return np.min(args[0], axis=axis)
    return np.minimum(*args)
def max(*args, axis=None):
    if len(args) == 1: return np.max(args[0], axis=axis)
    return np.maximum(*args)

def sort(x, axis=None):
    if axis is None:
        if isinstance(x, np.ndarray) and x.ndim == 2: axis = 1 if x.shape[0] == 1 else 0
        else: axis = 0
    return np.sort(x, axis=axis)

def unique(x): return np.unique(x)
def inv(x): return np.linalg.inv(x)
def det(x): return np.linalg.det(x)
def eig(x): return np.linalg.eig(x)
def svd(x):
    U, S, Vh = np.linalg.svd(x)
    return U, np.diag(S), Vh.T

def linspace(start, stop, n=100): return np.linspace(start, stop, int(n))
def logspace(start, stop, n=50): return np.logspace(start, stop, int(n))
def meshgrid(x, y=None): return np.meshgrid(x, y if y is not None else x)
def randperm(n): return np.random.permutation(int(n)) + 1
def abs(x): return np.abs(x)
def round(x): return np.round(x)
def floor(x): return np.floor(x)
def ceil(x): return np.ceil(x)
def fix(x): return np.trunc(x)
def rem(x, y): return np.remainder(x, y)
def sin(x): return np.sin(x)
def cos(x): return np.cos(x)
def tan(x): return np.tan(x)
def exp(x): return np.exp(x)
def log(x): return np.log(x)
def sqrt(x): return np.sqrt(x)
def pi(): return np.pi

def eye(n, m=None): return np.eye(int(n), int(m) if m is not None else int(n))
def zeros(*args): 
    if len(args) == 1 and isinstance(args[0], (list, tuple, np.ndarray)): return np.zeros(args[0])
    return np.zeros(args)
def ones(*args): 
    if len(args) == 1 and isinstance(args[0], (list, tuple, np.ndarray)): return np.ones(args[0])
    return np.ones(args)
def median(x, axis=None): return np.median(x, axis=axis)
def quantile(x, q, axis=None): return np.percentile(x, q * 100, axis=axis)
def var(x, axis=None): return np.var(x, axis=axis)
def std(x, axis=None): return np.std(x, axis=axis)

def rand(*args):
    if len(args) == 1 and isinstance(args[0], (list, tuple, np.ndarray)): return np.random.rand(*args[0])
    return np.random.rand(*args)

def randn(*args):
    if len(args) == 1 and isinstance(args[0], (list, tuple, np.ndarray)): return np.random.randn(*args[0])
    return np.random.randn(*args)

def diag(v, k=0): return np.diag(v, k)

def num2str(x, precision=None):
    if precision is not None:
        return f"{x:.{precision}f}"
    return str(x)

def mat2str(x):
    if isinstance(x, np.ndarray):
        return str(x).replace('\n', ';')
    return str(x)

def sprintf(fmt, *args):
    # MATLAB uses % for formatting, similar to Python's old style
    # but we need to handle the case where fmt contains MATLAB-style formatters
    try:
        return fmt % args
    except:
        return fmt # Fallback

def _unilab_refresh_graph():
    try:
        import json
        ax = plt.gca()
        
        # Check if grid is on (safer way)
        grid_on = False
        try:
            grid_on = ax.xaxis._grid_on_major or ax.yaxis._grid_on_major
        except:
            try:
                grid_on = any(line.get_visible() for line in ax.xaxis.get_gridlines())
            except: pass

        # Extract metadata for ASCII overlay
        meta = {
            "title": ax.get_title(),
            "xlabel": ax.get_xlabel(),
            "ylabel": ax.get_ylabel(),
            "xmin": float(ax.get_xlim()[0]),
            "xmax": float(ax.get_xlim()[1]),
            "ymin": float(ax.get_ylim()[0]),
            "ymax": float(ax.get_ylim()[1]),
            "legend": [t.get_text() for t in ax.get_legend().get_texts()] if ax.get_legend() else [],
            "grid": grid_on
        }
        with open("graph_meta.json", "w") as f:
            json.dump(meta, f)

        # High-impact styling with a Pastel Aesthetic
        plt.rcParams.update({
            'axes.prop_cycle': plt.cycler(color=['#A8D8EA', '#AA96DA', '#FCBAD3', '#FFFFD2', '#FF8080', '#BAE1FF']),
            'axes.linewidth': 1.5, 
            'axes.edgecolor': '#555555',
            'grid.color': '#DDDDDD',
            'grid.linestyle': '--',
            'grid.linewidth': 0.8,
            'lines.linewidth': 4.0,
            'font.size': 20,
            'font.weight': 'bold',
            'figure.facecolor': 'white',
            'axes.facecolor': '#FAFAFA',
            'axes.labelweight': 'bold',
            'axes.titleweight': 'bold',
            'xtick.labelsize': 16,
            'ytick.labelsize': 16,
            'legend.fontsize': 16,
            'figure.dpi': 120
        })
        fig = plt.gcf()
        fig.set_size_inches(12, 8)
        plt.tight_layout()
        plt.savefig("graph.jpg", format='jpg', bbox_inches='tight')
        print(f"::GRAPHICAL_PLOT::graph.jpg")
    except Exception as e: print(f"Error saving graph: {e}")

_unilab_hold = False

def hold(state='on'):
    global _unilab_hold
    _unilab_hold = (state == 'on' or state == True or state == 1)

def clf():
    plt.clf()
    _unilab_refresh_graph()

def plot(*args, **kwargs):
    # Intercept 'grid' argument from args if it's a 'Name', Value pair
    args_list = list(args)
    grid_state = kwargs.pop('grid', None)
    
    i = 0
    while i < len(args_list) - 1:
        if isinstance(args_list[i], str) and args_list[i].lower() == 'grid':
            grid_state = args_list[i+1]
            args_list.pop(i)
            args_list.pop(i)
            continue
        i += 1
    
    if not _unilab_hold:
        plt.clf()
        
    res = plt.plot(*args_list, **kwargs)
    if grid_state is not None:
        plt.grid(grid_state == 'on' or grid_state == True or grid_state == 1)
    _unilab_refresh_graph()
    return res

def unilab_ascii_plot(y, x=None, height=20, width=60, plot_type='line'):
    try:
        if x is None or (isinstance(x, (list, np.ndarray)) and len(x) == 0):
            if isinstance(y, (list, np.ndarray)):
                x = np.arange(len(y))
            else:
                x = np.arange(1)
                y = [y]
        
        y = np.asarray(y).flatten()
        x = np.asarray(x).flatten()
        
        if y.size == 0: return ""
        
        # Filter out NaNs/Infs
        mask = np.isfinite(x) & np.isfinite(y)
        x = x[mask]
        y = y[mask]
        
        if y.size == 0: return ""

        xmin, xmax = np.min(x), np.max(x)
        ymin, ymax = np.min(y), np.max(y)
        
        if xmax == xmin: xmax += 1
        if ymax == ymin: ymax += 1
        
        height = int(height) if height and height > 0 else 20
        width = int(width) if width and width > 0 else 60
        
        canvas = [[' ' for _ in range(width)] for _ in range(height)]
        
        def set_pixel(cx, cy, char):
            if 0 <= cx < width and 0 <= cy < height:
                canvas[cy][cx] = char

        for i in range(len(x)):
            px = int((x[i] - xmin) / (xmax - xmin) * (width - 1))
            py = int((y[i] - ymin) / (ymax - ymin) * (height - 1))
            py = height - 1 - py
            
            if plot_type == 'line' and i > 0:
                prev_px = int((x[i-1] - xmin) / (xmax - xmin) * (width - 1))
                prev_py = height - 1 - int((y[i-1] - ymin) / (ymax - ymin) * (height - 1))
                
                dx = abs(px - prev_px)
                dy = abs(py - prev_py)
                sx = 1 if prev_px < px else -1
                sy = 1 if prev_py < py else -1
                err = dx - dy
                
                cx, cy = prev_px, prev_py
                while True:
                    set_pixel(cx, cy, '*')
                    if cx == px and cy == py: break
                    e2 = 2 * err
                    if e2 > -dy:
                        err -= dy
                        cx += sx
                    if e2 < dx:
                        err += dx
                        cy += sy
            elif plot_type == 'scatter':
                set_pixel(px, py, 'o')
            elif plot_type == 'bar':
                bar_top = py
                bar_bottom = height - 1 - int((0 - ymin) / (ymax - ymin) * (height - 1))
                bar_bottom = max(0, min(height - 1, bar_bottom))
                
                start = min(bar_top, bar_bottom)
                end = max(bar_top, bar_bottom)
                for sy in range(start, end + 1):
                    set_pixel(px, sy, '#')
            elif plot_type == 'stem':
                set_pixel(px, py, 'o')
                zero_y = height - 1 - int((0 - ymin) / (ymax - ymin) * (height - 1))
                zero_y = max(0, min(height - 1, zero_y))
                step = 1 if py < zero_y else -1
                for sy in range(py + step, zero_y + step, step):
                    set_pixel(px, sy, '|')
            elif plot_type == 'stairs' and i > 0:
                prev_px = int((x[i-1] - xmin) / (xmax - xmin) * (width - 1))
                prev_py = height - 1 - int((y[i-1] - ymin) / (ymax - ymin) * (height - 1))
                
                # Draw horizontal then vertical
                for cx in range(min(prev_px, px), max(prev_px, px) + 1):
                    set_pixel(cx, prev_py, '*')
                for cy in range(min(prev_py, py), max(prev_py, py) + 1):
                    set_pixel(px, cy, '*')
            elif plot_type == 'area':
                set_pixel(px, py, '*')
                zero_y = height - 1 - int((0 - ymin) / (ymax - ymin) * (height - 1))
                zero_y = max(0, min(height - 1, zero_y))
                for sy in range(min(py, zero_y), max(py, zero_y) + 1):
                    set_pixel(px, sy, '.')
            else:
                set_pixel(px, py, '*')

        res = []
        res.append(f" {ymax:8.2f} |" + "".join(canvas[0]) + "|")
        for i in range(1, height - 1):
            res.append(f"          |" + "".join(canvas[i]) + "|")
        res.append(f" {ymin:8.2f} |" + "".join(canvas[height-1]) + "|")
        res.append("           +" + "-" * width + "+")
        
        xmin_str = f"{xmin:.2f}"
        xmax_str = f"{xmax:.2f}"
        middle_space = " " * (width - len(xmin_str) - len(xmax_str))
        res.append("            " + xmin_str + middle_space + xmax_str)
        
        return "\n".join(res)
    except Exception as e:
        return f"Error generating ASCII plot: {e}"

def unilab_ascii_heatmap(M, height=15, width=40):
    try:
        M = np.asarray(M)
        if M.size == 0: return ""
        
        m_min, m_max = np.min(M), np.max(M)
        if m_max == m_min: m_max += 1
        
        # Simple manual resize (nearest neighbor)
        orig_h, orig_w = M.shape
        res_h, res_w = int(height), int(width)
        
        ramp = " .:-=+*#%@"
        res = ["+" + "-" * res_w + "+"]
        for r in range(res_h):
            row = "|"
            orig_r = int(r * orig_h / res_h)
            for c in range(res_w):
                orig_c = int(c * orig_w / res_w)
                val = M[orig_r, orig_c]
                idx = int((val - m_min) / (m_max - m_min) * (len(ramp) - 1))
                row += ramp[max(0, min(len(ramp)-1, idx))]
            row += "|"
            res.append(row)
        res.append("+" + "-" * res_w + "+")
        return "\n".join(res)
    except Exception as e:
        return f"Error generating ASCII heatmap: {e}"

def _terminal_plot(y, x=None, height=None, width=None, type='line', **kwargs):
    """HD Terminal Plotting with High-Contrast Styling."""
    grid_state = kwargs.pop('grid', True)
    
    if x is None or (isinstance(x, (list, np.ndarray)) and len(x) == 0):
        if isinstance(y, (list, np.ndarray)):
            x = np.arange(len(y))
        else:
            x = np.arange(1)
            y = [y]
            
    plt.figure(figsize=(10, 6))
    if type == 'line':
        plt.plot(x, y, linewidth=5.0)
    elif type == 'area':
        plt.fill_between(x, y, alpha=0.4)
        plt.plot(x, y, linewidth=3.0)
    elif type == 'stairs':
        plt.step(x, y, where='mid', linewidth=5.0)
    elif type == 'scatter':
        plt.scatter(x, y, s=150)
    elif type == 'bar':
        plt.bar(x, y, width=0.8, color='tab:blue', edgecolor='black', linewidth=1.5)
    elif type == 'stem':
        markerline, stemlines, baseline = plt.stem(x, y)
        plt.setp(stemlines, 'linewidth', 3)
        plt.setp(markerline, 'markersize', 10)
    elif type == 'box':
        plt.boxplot(y, patch_artist=True, boxprops=dict(linewidth=3), medianprops=dict(linewidth=3))
    
    plt.grid(grid_state == 'on' or grid_state == True or grid_state == 1, linestyle='--', alpha=0.6, linewidth=1.5)
    _unilab_refresh_graph()
    plt.close()

def _terminal_heatmap(M):
    """HD Heatmap optimized for terminal grids."""
    plt.figure(figsize=(10, 6))
    plt.imshow(M, cmap='magma', interpolation='nearest')
    plt.colorbar()
    _unilab_refresh_graph()
    plt.close()

def scatter(*args, **kwargs):
    res = plt.scatter(*args, **kwargs); _unilab_refresh_graph(); return res
def bar(*args, **kwargs):
    res = plt.bar(*args, **kwargs); _unilab_refresh_graph(); return res
def hist(*args, **kwargs):
    res = plt.hist(*args, **kwargs); _unilab_refresh_graph(); return res
def title(t): plt.title(t, fontweight='bold', fontsize=22); _unilab_refresh_graph()
def xlabel(l): plt.xlabel(l, fontweight='bold', fontsize=18); _unilab_refresh_graph()
def ylabel(l): plt.ylabel(l, fontweight='bold', fontsize=18); _unilab_refresh_graph()
def grid(state='on'):
    plt.grid(state == 'on' or state == True or state == 1, linewidth=1.5); _unilab_refresh_graph()

def _scatter_plot(x, y, t=None):
    plt.clf()
    plt.scatter(x, y, s=100, alpha=0.6)
    if t: plt.title(t, fontweight='bold', fontsize=22)
    _unilab_refresh_graph()

def _hist_plot(data, bins=10, t=None):
    plt.clf()
    plt.hist(data, bins=bins, alpha=0.7, edgecolor='white')
    if t: plt.title(t, fontweight='bold', fontsize=22)
    _unilab_refresh_graph()

def _plot_matrix(M, t=None):
    plt.clf()
    plt.imshow(M, cmap='viridis', interpolation='nearest')
    plt.colorbar()
    if t: plt.title(t, fontweight='bold', fontsize=22)
    _unilab_refresh_graph()

def render_image_terminal(img_path, width=None):
    import os
    import json
    from PIL import Image, ImageOps, ImageEnhance, ImageFilter
    from ..utils.terminal_graphics import get_terminal_graphics
    
    env = os.environ
    force_fallback = env.get("UNILAB_FORCE_FALLBACK", "0") == "1"
    
    # Try high-resolution graphics if modern terminal is detected
    if not force_fallback:
        high_res = get_terminal_graphics(img_path)
        if high_res:
            return f"\n\x1b[1;34m[ Graphical Plot View ]\x1b[0m\n{high_res}\n"

    try:
        # Load metadata if available
        meta_path = os.path.join(os.path.dirname(img_path), "graph_meta.json")
        meta = {}
        if os.path.exists(meta_path):
            try:
                with open(meta_path, "r") as f:
                    meta = json.load(f)
            except: pass

        # Open and convert to RGB to preserve colors
        im = Image.open(img_path).convert('RGB')
        
        # Crop to the actual data area
        grayscale = ImageOps.grayscale(im)
        box_im = ImageOps.invert(grayscale).point(lambda p: 255 if p > 50 else 0)
        bbox = box_im.getbbox()
        if bbox:
            im = im.crop(bbox)

        # Pre-process
        im = ImageEnhance.Contrast(im).enhance(1.5)
        
        # Determine terminal size
        try: term_cols = os.get_terminal_size().columns
        except: term_cols = 80
            
        target_w = min(width or 80, term_cols - 16)
        target_h = int(target_w * (im.height / im.width) * 0.55)
        if target_h < 15: target_h = 15
        if target_h > 40: target_h = 40
        
        # Resize
        img = im.resize((target_w, target_h), Image.Resampling.LANCZOS)
        pixels = img.load()
        
        # ASCII density ramp
        ramp = " .:-=+*#%@"
        ramp_len = len(ramp)

        grid_data = []
        for y in range(target_h):
            row = ""
            for x in range(target_w):
                r, g, b = pixels[x, y]
                # Calculate luminance for character selection
                luma = 0.299*r + 0.587*g + 0.114*b
                idx = int((255 - luma) * (ramp_len - 1) / 255)
                char = ramp[idx]
                
                # Apply TrueColor to the character if it's not basically white
                if luma < 240:
                    row += f"\x1b[38;2;{r};{g};{b}m{char}\x1b[0m"
                else:
                    row += " "
            grid_data.append(row)

        # Reconstruct with Overlay
        res = ["\n\x1b[1;36m[ Pastel Colored Plot ]\x1b[0m"]
        
        title_str = meta.get("title", "")
        if title_str:
            res.append(" " * 15 + f"\x1b[1m{title_str.center(target_w)}\x1b[0m")

        # Y-Axis formatting
        ymax = f"{meta.get('ymax', 1.0):.2f}"
        ymin = f"{meta.get('ymin', 0.0):.2f}"
        y_val_w = max(len(ymax), len(ymin))
        
        ylabel_text = meta.get("ylabel", "")
        ylabel_padded = ylabel_text.center(target_h)
        
        for i, row in enumerate(grid_data):
            yl = ylabel_padded[i] if i < len(ylabel_padded) else " "
            if i == 0:
                prefix = f"{yl} {ymax:>{y_val_w}} |"
            elif i == target_h - 1:
                prefix = f"{yl} {ymin:>{y_val_w}} |"
            else:
                prefix = f"{yl} {' ':>{y_val_w}} |"
            
            res.append(f"{prefix}{row}|")

        # X-Axis formatting
        xmin = f"{meta.get('xmin', 0.0):.2f}"
        xmax = f"{meta.get('xmax', 1.0):.2f}"
        xaxis_line = " " * (y_val_w + 3) + "+" + "-" * target_w + "+"
        res.append(xaxis_line)
        
        # X-Axis values
        xvals = f"{xmin}{xmax:>{target_w + 1 - len(xmin)}}"
        res.append(" " * (y_val_w + 3) + xvals)
        
        xlabel_text = meta.get("xlabel", "")
        if xlabel_text:
            res.append(" " * (y_val_w + 3) + f"\x1b[3m{xlabel_text.center(target_w)}\x1b[0m")

        legend = meta.get("legend", [])
        if legend:
            res.append("\n" + " " * (y_val_w + 3) + "\x1b[1mLegend:\x1b[0m " + ", ".join(legend))

        return "\n".join(res)
        
    except Exception as e:
        return f"\n\x1b[1;31m[ Render failed: {e} ]\x1b[0m\n"

def list_libraries():
    import pathlib
    print("-" * 50 + "\n🧪 UniLab Toolbox Explorer\n" + "-" * 50)
    libs_dir = pathlib.Path(__file__).resolve().parent.parent / "libraries"
    for item in sorted(libs_dir.iterdir()):
        if item.is_dir() and not item.name.startswith("__"):
            funcs = sorted([f.stem for f in item.glob("*.m")])
            if funcs:
                print(f"  > {item.name}:")
                line = "    "
                for i, f in enumerate(funcs):
                    if len(line) + len(f) + 2 > 80: print(line); line = "    "
                    line += f + (", " if i < len(funcs) - 1 else "")
                print(line)
    print("\n" + "-" * 50)

def unilab_clear_workspace(g):
    keys_to_keep = {'np', 'plt', 'os', 'signal', 'fft', 'ifft', '__builtins__'}
    import backend.core.runtime as rt
    for name in dir(rt):
        if not name.startswith('_'): keys_to_keep.add(name)
    to_remove = [k for k in g if k not in keys_to_keep and not k.startswith('__')]
    for k in to_remove: del g[k]
