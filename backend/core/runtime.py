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

def max(x, axis=None):
    return np.max(x, axis=axis)

def min(x, axis=None):
    return np.min(x, axis=axis)

# Linear Algebra
def inv(x):
    return np.linalg.inv(x)

def det(x):
    return np.linalg.det(x)

def eig(x):
    return np.linalg.eig(x)

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
    return np.eye(n, m)

def zeros(n, m=1):
    return np.zeros((n, m))

def ones(n, m=1):
    return np.ones((n, m))

def rand(n, m=1):
    return np.random.rand(n, m)

def randn(n, m=1):
    return np.random.randn(n, m)
