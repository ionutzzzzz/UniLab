import numpy as np
import matplotlib.pyplot as plt
import os
import io
import time
import pathlib
import scipy.signal as signal
from scipy.fft import fft, ifft

def disp(x):
    print(x)

def clc():
    os.system('cls' if os.name == 'nt' else 'clear')

def unilab_print_var(name, val):
    print(f"{name} =\n   {val}\n")

def unilab_print_and_save_ans(expr, val):
    global ans
    ans = val
    if val is not None:
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
    try: return np.dot(a, b)
    except: return a * b

def unilab_div(a, b):
    try: return np.linalg.solve(np.atleast_2d(b).T, np.atleast_2d(a).T).T
    except: return a / b

def unilab_pow(a, b):
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
    try:
        processed_rows = []
        for r in rows:
            if isinstance(r, (list, np.ndarray)): processed_rows.append(np.asarray(r))
            else: processed_rows.append(np.asarray([r]))
        if len(processed_rows) == 1: return processed_rows[0]
        return np.vstack(processed_rows)
    except: return np.array(rows)

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

def _unilab_refresh_graph():
    try:
        # High-impact styling for maximum clarity in character-based terminals
        plt.rcParams.update({
            'axes.linewidth': 3.0, 
            'lines.linewidth': 7.0, # Extra thick lines for block rendering
            'font.size': 22,
            'font.weight': 'bold',
            'figure.facecolor': 'white',
            'axes.facecolor': 'white',
            'axes.labelweight': 'bold',
            'axes.titleweight': 'bold',
            'xtick.labelsize': 16,
            'ytick.labelsize': 16,
            'legend.fontsize': 16,
            'figure.dpi': 100
        })
        fig = plt.gcf()
        fig.set_size_inches(12.8, 7.2)
        plt.tight_layout()
        plt.savefig("graph.png", format='png', bbox_inches='tight', dpi=100)
        print(f"::GRAPHICAL_PLOT::graph.png")
    except Exception as e: print(f"Error saving graph: {e}")

def plot(*args, **kwargs):
    res = plt.plot(*args, **kwargs)
    _unilab_refresh_graph()
    return res

def terminal_plot(y, x=None, height=None, width=None, type='line'):
    """HD Terminal Plotting with High-Contrast Styling."""
    if x is None or (isinstance(x, (list, np.ndarray)) and len(x) == 0):
        if isinstance(y, (list, np.ndarray)):
            x = np.arange(len(y))
        else:
            x = np.arange(1)
            y = [y]
            
    plt.figure(figsize=(12.8, 7.2))
    if type == 'line':
        plt.plot(x, y, linewidth=7.0)
    elif type == 'area':
        plt.fill_between(x, y, alpha=0.4)
        plt.plot(x, y, linewidth=5.0)
    elif type == 'stairs':
        plt.step(x, y, where='mid', linewidth=7.0)
    elif type == 'scatter':
        plt.scatter(x, y, s=200)
    elif type == 'bar':
        plt.bar(x, y, width=0.8, color='tab:blue', edgecolor='black', linewidth=2)
    elif type == 'stem':
        markerline, stemlines, baseline = plt.stem(x, y)
        plt.setp(stemlines, 'linewidth', 4)
        plt.setp(markerline, 'markersize', 12)
    elif type == 'box':
        plt.boxplot(y, patch_artist=True, boxprops=dict(linewidth=4), medianprops=dict(linewidth=4))
    
    plt.grid(True, linestyle='--', alpha=0.8, linewidth=2.0)
    _unilab_refresh_graph()
    plt.close()

def terminal_heatmap(M):
    """HD Heatmap optimized for terminal grids."""
    plt.figure(figsize=(12.8, 7.2))
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
def title(t): plt.title(t, fontweight='bold', fontsize=26); _unilab_refresh_graph()
def xlabel(l): plt.xlabel(l, fontweight='bold', fontsize=22); _unilab_refresh_graph()
def ylabel(l): plt.ylabel(l, fontweight='bold', fontsize=22); _unilab_refresh_graph()
def grid(state='on'):
    plt.grid(state == 'on' or state == True, linewidth=2.0); _unilab_refresh_graph()

def render_image_terminal(img_path, width=None):
    import os
    from PIL import Image, ImageOps, ImageEnhance, ImageFilter
    
    env = os.environ
    force_fallback = env.get("UNILAB_FORCE_FALLBACK", "0") == "1"
    is_ssh = any(k in env for k in ("SSH_CLIENT", "SSH_TTY", "SSH_CONNECTION"))
    
    try:
        im = Image.open(img_path)
        
        # If not SSH and not forced, we can try binary protocols (Kitty/iTerm)
        # But for this user's preference, we prioritize the sharp ASCII look.
        
        # High-Density Braille ASCII Rendering Engine
        # This provides 2x4 "pixels" per character cell.
        img = im.convert('L') # Grayscale for edge detection
        img = ImageOps.invert(img) # Invert so lines are "on"
        img = ImageEnhance.Contrast(img).enhance(2.0)
        img = img.filter(ImageFilter.FIND_EDGES)
        img = ImageEnhance.Sharpness(img).enhance(4.0)
        
        # Binarize the image for crisp characters
        img = img.point(lambda p: 255 if p > 100 else 0)
        
        try: term_cols = os.get_terminal_size().columns
        except: term_cols = 100
            
        target_w = min(width or 120, term_cols - 4)
        # Each Braille char is 2px wide, 4px high
        target_h = int(target_w * (img.height / img.width) * 0.5)
        
        img = img.resize((target_w * 2, target_h * 4), Image.Resampling.NEAREST)
        pixels = img.load()
        
        res = ["\n[ Graphical Plot Preview ]", "+" + "-" * target_w + "+"]
        
        # Braille Unicode mapping
        # Each character covers a 2x4 pixel area
        for y in range(0, target_h * 4, 4):
            line = ["|"]
            for x in range(0, target_w * 2, 2):
                code = 0
                # Braille dot mapping:
                # 1 8
                # 2 16
                # 4 32
                # 64 128
                if pixels[x, y]: code |= 1
                if pixels[x, y+1]: code |= 2
                if pixels[x, y+2]: code |= 4
                if pixels[x+1, y]: code |= 8
                if pixels[x+1, y+1]: code |= 16
                if pixels[x+1, y+2]: code |= 32
                if pixels[x, y+3]: code |= 64
                if pixels[x+1, y+3]: code |= 128
                
                if code == 0:
                    line.append(" ")
                else:
                    line.append(chr(0x2800 + code))
            line.append("|")
            res.append("".join(line))
            
        res.append("+" + "-" * target_w + "+")
        return "\n".join(res)
        
    except Exception as e:
        return f"\n[ Render failed: {e} ]\n"

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
