import numpy as np
import matplotlib.pyplot as plt
import os
import scipy.signal as signal
from scipy.fft import fft, ifft

def disp(x):
    print(x)

def clc():
    # This is a stub, the actual implementation will be handled by the console/UI
    # by clearing the terminal screen.
    pass

def help(topic=None):
    # This is a stub. The engine or console will intercept this 
    # and provide documentation for the given topic.
    pass

def unilab_print_var(name, val):
    print(f"{name} =")
    print(f"   {val}\n")

def unilab_print_and_save_ans(name, val):
    # Only print if it's not a function call that might already print or if it returns something
    if val is not None:
        print(f"ans =")
        print(f"   {val}\n")
    return val

def figure():
    return plt.figure()

def plot(*args, **kwargs):
    # Replicate UniLab plot behavior
    # For now, just a wrapper around plt.plot
    res = plt.plot(*args, **kwargs)
    return res

def title(t):
    plt.title(t)

def xlabel(l):
    plt.xlabel(l)

def ylabel(l):
    plt.ylabel(l)

def grid(state):
    if state == 'on' or state is True:
        plt.grid(True)
    else:
        plt.grid(False)

def unilab_mul(a, b):
    # Handle matrix vs scalar multiplication
    if np.isscalar(a) or np.isscalar(b):
        return a * b
    try:
        return a @ b
    except ValueError:
        return a * b

def unilab_div(a, b):
    if np.isscalar(b):
        return a / b
    return np.linalg.solve(b.T, a.T).T # A / B is roughly A * inv(B)

def unilab_pow(a, b):
    if np.isscalar(a) and np.isscalar(b):
        return a ** b
    # Matrix power is more complex, but we'll simplify
    return np.power(a, b)

def unilab_or(a, b):
    if np.isscalar(a) and np.isscalar(b):
        return a or b
    return np.logical_or(a, b)

def unilab_and(a, b):
    if np.isscalar(a) and np.isscalar(b):
        return a and b
    return np.logical_and(a, b)

def unilab_call(obj, *args):
    if callable(obj):
        return obj(*args)
    
    if not hasattr(obj, '__getitem__'):
        return obj
    
    if len(args) == 0:
        return obj
        
    if len(args) == 1:
        idx = args[0]
        # If obj is a vector (1, N) or (N, 1) or (N,), and we have 1D index
        if isinstance(obj, np.ndarray):
            if obj.ndim == 1:
                if isinstance(idx, (int, np.integer, float, np.floating)):
                    return obj[int(idx)-1]
                # ... handle other types
            elif obj.ndim == 2 and (obj.shape[0] == 1 or obj.shape[1] == 1):
                # Flatten for indexing
                flat_obj = obj.flatten()
                if isinstance(idx, (int, np.integer, float, np.floating)):
                    return flat_obj[int(idx)-1]
                if isinstance(idx, (np.ndarray, list, slice)):
                    # Adjust 1-based indexing for arrays of integers/floats
                    if isinstance(idx, np.ndarray) and not np.issubdtype(idx.dtype, np.bool_):
                        return flat_obj[idx.flatten().astype(int) - 1]
                    if isinstance(idx, list) and len(idx) > 0 and isinstance(idx[0], (int, float)):
                        return flat_obj[np.array(idx).astype(int) - 1]
                    return flat_obj[idx]
        
        if isinstance(obj, list):
            if isinstance(idx, (int, np.integer, float, np.floating)):
                return obj[int(idx)-1]

        # Standard indexing
        if isinstance(idx, (int, np.integer, float, np.floating)):
            return obj[int(idx)-1]
        return obj[idx]

    # Multi-dimensional indexing
    processed = []
    for i in args:
        if isinstance(i, (int, np.integer, float, np.floating)):
            processed.append(int(i) - 1)
        else:
            processed.append(i)
    return obj[tuple(processed)]

def unilab_get(obj, attr):
    if isinstance(obj, dict):
        return obj.get(attr)
    return getattr(obj, attr)

def unilab_set(obj, val, *args):
    if len(args) == 1:
        idx = args[0]
        # Adjust 1-based index
        if isinstance(idx, (int, np.integer, float, np.floating)):
            idx_adj = int(idx) - 1
        elif isinstance(idx, (np.ndarray, list)):
            idx_adj = np.asarray(idx).astype(int) - 1
        else:
            idx_adj = idx

        if isinstance(obj, np.ndarray):
            if obj.ndim == 1:
                obj[idx_adj] = val
            elif obj.ndim == 2:
                if obj.shape[0] == 1: # Row vector
                    obj[0, idx_adj] = val
                elif obj.shape[1] == 1: # Column vector
                    obj[idx_adj, 0] = val
                else:
                    # Linear indexing in 2D array
                    obj.flat[idx_adj] = val
            else:
                obj.flat[idx_adj] = val
            return obj
        
        # Fallback for lists
        obj[idx_adj] = val
    elif len(args) > 1:
        processed = []
        for i in args:
            if isinstance(i, (int, np.integer, float, np.floating)):
                processed.append(int(i) - 1)
            else:
                processed.append(i)
        obj[tuple(processed)] = val
    return obj

def unilab_matrix_concat(*rows):
    if not rows:
        return np.array([])
    
    # Check if we are concatenating strings
    first_row = rows[0]
    if isinstance(first_row, (str, bytes)) or (isinstance(first_row, list) and len(first_row) > 0 and isinstance(first_row[0], (str, bytes))):
        # String concatenation
        res = ""
        for r in rows:
            if isinstance(r, list):
                for item in r:
                    res += str(item)
            else:
                res += str(r)
        return res

    # Standard matrix concatenation
    try:
        # Convert list of lists to numpy array
        processed_rows = []
        for r in rows:
            if isinstance(r, (list, np.ndarray)):
                processed_rows.append(np.asarray(r))
            else:
                processed_rows.append(np.asarray([r]))
        
        if len(processed_rows) == 1:
            row = processed_rows[0]
            return row
        
        return np.vstack(processed_rows)
    except:
        return np.array(rows)

def unilab_nargin_sum(gen):
    import builtins
    return builtins.sum(gen)

def unilab_cell_concat(*args):
    res = []
    for a in args:
        if isinstance(a, list):
            res.extend(a)
        else:
            res.append(a)
    return res

def nargin():
    # Placeholder: ideally should return actual count
    return 3

def whos():
    # This is a stub, the actual implementation will be handled by the engine
    # but we need it here to avoid 'name not defined' error during transpilation
    # if it's called as a function.
    pass

def factorial(n):
    from math import factorial as f
    if isinstance(n, (np.ndarray, list)):
        return np.array([f(int(i)) for i in n])
    return f(int(n))

def mod(x, y):
    return np.mod(x, y)

import sympy

def syms(*names):
    """Define symbolic variables."""
    if len(names) == 1 and isinstance(names[0], str) and ' ' in names[0]:
        names = names[0].split()
    
    symbols = sympy.symbols(names)
    if len(names) == 1:
        return symbols
    return symbols

def diff_sym(expr, var, n=1):
    """Symbolic differentiation."""
    return sympy.diff(expr, var, n)

def int_sym(expr, var, a=None, b=None):
    """Symbolic integration."""
    if a is None:
        return sympy.integrate(expr, var)
    return sympy.integrate(expr, (var, a, b))

def solve_sym(eq, var):
    """Solve symbolic equation eq == 0."""
    return sympy.solve(eq, var)

def simplify_sym(expr):
    """Simplify symbolic expression."""
    return sympy.simplify(expr)

def expand_sym(expr):
    """Expand symbolic expression."""
    return sympy.expand(expr)

def subs_sym(expr, old, new):
    """Substitute old with new in expr."""
    return expr.subs(old, new)

# Matrix Analysis
def length(x):
    if hasattr(x, '__len__'):
        if isinstance(x, np.ndarray):
            return max(x.shape)
        return len(x)
    return 1

def size(x, dim=None):
    s = np.shape(x)
    if len(s) == 0:
        if isinstance(x, (str, bytes)):
            s = (1, len(x))
        else:
            s = (1, 1)
    elif len(s) == 1:
        s = (1, s[0])
    
    if dim is not None:
        if dim > len(s): return 1
        return s[dim-1]
    return s

def sum(x, axis=None):
    return np.sum(x, axis=axis)

def mean(x, axis=None):
    return np.mean(x, axis=axis)

def std(x, axis=None):
    return np.std(x, axis=axis)

def var(x, axis=None):
    return np.var(x, axis=axis)

def median(x, axis=None):
    return np.median(x, axis=axis)

def quantile(x, q, axis=None):
    return np.quantile(x, q, axis=axis)

def max(*args, axis=None):
    if len(args) == 1:
        return np.max(args[0], axis=axis)
    return np.maximum(*args)

def min(*args, axis=None):
    if len(args) == 1:
        return np.min(args[0], axis=axis)
    return np.minimum(*args)

def sort(x, axis=-1):
    # Returns only sorted array for now to avoid tuple issues
    return np.sort(x, axis=axis)

def mode(x, axis=None):
    from scipy import stats
    import warnings
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        m = stats.mode(x, axis=axis, keepdims=True)
    return m.mode

def find(condition):
    return np.where(condition)[0] + 1

def unique(x):
    return np.unique(x)

def argsort(x, axis=-1):
    return np.argsort(x, axis=axis) + 1

def argmin(x, axis=None):
    return np.argmin(x, axis=axis) + 1

def argmax(x, axis=None):
    return np.argmax(x, axis=axis) + 1

def norm(x, ord=None):
    return np.linalg.norm(x, ord=ord)

def diag(x, k=0):
    return np.diag(x, k=k)

def isempty(x):
    if hasattr(x, 'size'):
        return x.size == 0
    return len(x) == 0

def isvector(x):
    if isinstance(x, np.ndarray):
        return x.ndim == 1 or (x.ndim == 2 and (x.shape[0] == 1 or x.shape[1] == 1))
    return isinstance(x, (list, tuple))

def ismatrix(x):
    if isinstance(x, np.ndarray):
        return x.ndim == 2
    return False

def any(x):
    return np.any(x)

def all(x):
    return np.all(x)

def reshape(x, *args):
    if len(args) == 1 and isinstance(args[0], (list, tuple, np.ndarray)):
        return np.reshape(x, tuple(int(i) for i in args[0]))
    return np.reshape(x, tuple(int(i) for i in args))

def repmat(x, *args):
    if len(args) == 1 and isinstance(args[0], (list, tuple, np.ndarray)):
        return np.tile(x, tuple(int(i) for i in args[0]))
    return np.tile(x, tuple(int(i) for i in args))

# Linear Algebra
def inv(x):
    return np.linalg.inv(x)

def det(x):
    return np.linalg.det(x)

def eig(x):
    return np.linalg.eig(x)

def svd(x):
    U, S, Vh = np.linalg.svd(x)
    return U, np.diag(S), Vh.T

def num2str(x):
    if isinstance(x, (np.ndarray, list)):
        return str(x)
    return str(x)

def strcmp(s1, s2):
    return s1 == s2

# Array Creation
def linspace(start, stop, n=100):
    return np.linspace(start, stop, n)

def logspace(start, stop, n=50):
    return np.logspace(start, stop, n)

def randperm(n):
    return np.random.permutation(n) + 1

# Other Math
def abs(x): return np.abs(x)
def round(x): return np.round(x)
def floor(x): return np.floor(x)
def ceil(x): return np.ceil(x)
def fix(x): return np.trunc(x)
def rem(x, y): return np.remainder(x, y)
def logical(x): return np.asarray(x, dtype=bool)

def rand(*args):
    if len(args) == 0:
        return np.random.rand()
    if len(args) == 1 and isinstance(args[0], (list, tuple, np.ndarray)):
        return np.random.rand(*tuple(int(i) for i in args[0]))
    return np.random.rand(*tuple(int(i) for i in args))

def randn(*args):
    if len(args) == 0:
        return np.random.randn()
    if len(args) == 1 and isinstance(args[0], (list, tuple, np.ndarray)):
        return np.random.randn(*tuple(int(i) for i in args[0]))
    return np.random.randn(*tuple(int(i) for i in args))

def real(x):
    return np.real(x)

# Signal Processing
def fft_plot(x, fs):
    n = len(x)
    yf = fft(x)
    xf = np.linspace(0.0, fs/2, n//2)
    plt.plot(xf, 2.0/n * np.abs(yf[0:n//2]))
    plt.grid()

def spectrogram(x, fs):
    f, t, Sxx = signal.spectrogram(x, fs)
    plt.pcolormesh(t, f, 10 * np.log10(Sxx))
    plt.ylabel('Frequency [Hz]')
    plt.xlabel('Time [sec]')

# Control Systems (Stubs)
def tf(num, den):
    return signal.TransferFunction(num, den)

def step(sys):
    t, y = signal.step(sys)
    plt.plot(t, y)
    plt.title("Step Response")
    plt.xlabel("Time (s)")
    plt.ylabel("Amplitude")

def impulse(sys):
    t, y = signal.impulse(sys)
    plt.plot(t, y)
    plt.title("Impulse Response")
    plt.xlabel("Time (s)")
    plt.ylabel("Amplitude")

# Plot export helper
def save_plot(filename):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    plt.savefig(filename)
    print(f"::SAVED::{filename}")

def terminal_plot(y, x=None, height=20, width=60):
    """Generate an ASCII plot in the terminal."""
    if x is None:
        x = np.arange(1, len(y) + 1)
    
    y = np.asarray(y)
    x = np.asarray(x)
    
    # Filter out NaNs/Infs
    mask = np.isfinite(y) & np.isfinite(x)
    y = y[mask]
    x = x[mask]
    
    if len(y) == 0:
        print("No data to plot.")
        return

    y_min, y_max = np.min(y), np.max(y)
    x_min, x_max = np.min(x), np.max(x)
    
    # Prevent division by zero
    if y_min == y_max: y_max += 1
    if x_min == x_max: x_max += 1

    # Initialize canvas
    canvas = [[' ' for _ in range(width)] for _ in range(height)]
    
    # Map points to grid
    for i in range(len(y)):
        col = int((x[i] - x_min) / (x_max - x_min) * (width - 1))
        row = height - 1 - int((y[i] - y_min) / (y_max - y_min) * (height - 1))
        canvas[row][col] = '*'

    # Draw plot
    print("-" * (width + 10))
    for r in range(height):
        # Y-axis labels
        if r == 0:
            label = f"{y_max:8.2f} |"
        elif r == height // 2:
            label = f"{(y_min+y_max)/2:8.2f} |"
        elif r == height - 1:
            label = f"{y_min:8.2f} |"
        else:
            label = " " * 8 + "|"
        
        print(f"{label}{''.join(canvas[r])}")
    
    print(" " * 9 + "-" * width)
    # X-axis labels
    x_labels = f"{x_min:<10.2f}{' '*(width-20)}{x_max:>10.2f}"
    print(" " * 9 + x_labels)
    print("-" * (width + 10))

# Workspace Management
def unilab_clear_workspace(g):
    # Identify keys to keep (injected at start)
    # This is a bit tricky, but we can assume anything starting with unilab_ or standard imports
    keys_to_keep = {'np', 'plt', 'os', 'signal', 'fft', 'ifft', '__builtins__'}
    # Also keep all functions defined in this file
    import backend.core.runtime as rt
    for name in dir(rt):
        if not name.startswith('_'):
            keys_to_keep.add(name)
    
    to_remove = [k for k in g if k not in keys_to_keep and not k.startswith('__')]
    for k in to_remove:
        del g[k]

def unilab_clear_variables(g, var_names):
    for name in var_names:
        if name in g:
            del g[name]

def list_libraries():
    """List all available libraries and their functions."""
    import pathlib
    import os
    
    current_file = pathlib.Path(__file__).resolve()
    # backend/core/runtime.py -> backend/libraries
    libraries_dir = current_file.parent.parent / "libraries"
    packages_dir = current_file.parent.parent / "packages"
    
    print("-" * 50)
    print("🧪 UniLab Toolbox Explorer")
    print("-" * 50)
    
    def scan_dir(base_dir, label):
        if not base_dir.exists():
            return
            
        print(f"\n[{label}]")
        for item in sorted(base_dir.iterdir()):
            if item.is_dir() and not item.name.startswith("__"):
                funcs = sorted([f.stem for f in item.glob("*.m")])
                if not funcs:
                    # Check for __init__.py if it's a python package
                    if (item / "__init__.py").exists():
                        funcs = ["(Python Package)"]
                
                if funcs:
                    print(f"  > {item.name}:")
                    # Print functions in a clean wrapped format
                    line = "    "
                    for i, f in enumerate(funcs):
                        if len(line) + len(f) + 2 > 80:
                            print(line)
                            line = "    "
                        line += f + (", " if i < len(funcs) - 1 else "")
                    print(line)

    scan_dir(libraries_dir, "Standard Libraries (.m)")
    scan_dir(packages_dir, "Custom Packages (.py)")
    print("\n" + "-" * 50)

# Built-in math functions
def sin(x): return np.sin(x)
def cos(x): return np.cos(x)
def tan(x): return np.tan(x)
def exp(x): return np.exp(x)
def log(x): return np.log(x)
def sqrt(x): return np.sqrt(x)
def pi(): return np.pi

def eye(n, m=None):
    if isinstance(n, (list, tuple, np.ndarray)):
        n = n[0]
    return np.eye(int(n), int(m) if m is not None else None)

def zeros(n, m=None):
    if m is None:
        if isinstance(n, (list, tuple, np.ndarray)):
            shape = tuple(int(i) for i in n)
            return np.zeros(shape)
        return np.zeros((int(n), 1))
    return np.zeros((int(n), int(m)))

def ones(n, m=None):
    if m is None:
        if isinstance(n, (list, tuple, np.ndarray)):
            shape = tuple(int(i) for i in n)
            return np.ones(shape)
        return np.ones((int(n), 1))
    return np.ones((int(n), int(m)))

def rand(n, m=None):
    if m is None:
        if isinstance(n, (list, tuple, np.ndarray)):
            shape = tuple(int(i) for i in n)
            return np.random.rand(*shape)
        return np.random.rand(int(n), 1)
    return np.random.rand(int(n), int(m))

def randn(n, m=None):
    if m is None:
        if isinstance(n, (list, tuple, np.ndarray)):
            shape = tuple(int(i) for i in n)
            return np.random.randn(*shape)
        return np.random.randn(int(n), 1)
    return np.random.randn(int(n), int(m))

def randi(high, n=1, m=None):
    high = int(np.asarray(high).item())
    if m is None:
        if isinstance(n, (list, tuple, np.ndarray)):
            shape = tuple(int(i) for i in n)
            return np.random.randint(1, high + 1, size=shape)
        return np.random.randint(1, high + 1, size=(int(n), 1))
    return np.random.randint(1, high + 1, size=(int(n), int(m)))

def cell(n, m=1):
    if isinstance(n, (list, tuple, np.ndarray)):
        size = 1
        for i in n: size *= int(i)
        return [None] * size
    return [None] * (int(n) * int(m))

def struct(*args):
    # MATLAB struct('field1', val1, 'field2', val2, ...)
    res = {}
    for i in range(0, len(args), 2):
        if i+1 < len(args):
            res[args[i]] = args[i+1]
    return res
