import numpy as np
import matplotlib.pyplot as plt
import os
import scipy.signal as signal
from scipy.fft import fft, ifft

def disp(x):
    print(x)

def figure():
    return plt.figure()

def plot(*args, **kwargs):
    # Replicate MATLAB plot behavior
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
        # If obj is a vector (1, N) or (N, 1), and we have 1D index
        if isinstance(obj, np.ndarray) and (obj.shape[0] == 1 or obj.shape[1] == 1):
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
        if isinstance(obj, np.ndarray) and (obj.shape[0] == 1 or obj.shape[1] == 1):
            # Handle vector indexing
            flat_idx = idx
            if isinstance(idx, (int, np.integer, float, np.floating)):
                flat_idx = int(idx) - 1
            elif isinstance(idx, np.ndarray) and not np.issubdtype(idx.dtype, np.bool_):
                flat_idx = idx.flatten().astype(int) - 1
            
            # We need to be careful about shape when setting
            if obj.shape[0] == 1: # Row vector
                obj[0, flat_idx] = val
            else: # Column vector
                obj[flat_idx, 0] = val
            return obj

        if isinstance(idx, (int, np.integer, float, np.floating)):
            obj[int(idx)-1] = val
        else:
            obj[idx] = val
    elif len(args) > 1:
        processed = []
        for i in args:
            if isinstance(i, (int, np.integer, float, np.floating)):
                processed.append(int(i) - 1)
            else:
                processed.append(i)
        obj[tuple(processed)] = val
    return obj

# Matrix Analysis
def length(x):
    if hasattr(x, '__len__'):
        if isinstance(x, np.ndarray):
            return max(x.shape)
        return len(x)
    return 1

def size(x, dim=None):
    s = np.shape(x)
    if dim is not None:
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

# Linear Algebra
def inv(x):
    return np.linalg.inv(x)

def det(x):
    return np.linalg.det(x)

def eig(x):
    return np.linalg.eig(x)

def num2str(x):
    if isinstance(x, (np.ndarray, list)):
        return str(x)
    return str(x)

# Array Creation
def linspace(start, stop, n=100):
    return np.linspace(start, stop, n)

def logspace(start, stop, n=50):
    return np.logspace(start, stop, n)

# Other Math
def abs(x): return np.abs(x)
def round(x): return np.round(x)
def floor(x): return np.floor(x)
def ceil(x): return np.ceil(x)

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
