import numpy as np
import matplotlib.pyplot as plt
import os

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

# Plot export helper
def save_plot(filename):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    plt.savefig(filename)
    print(f"::SAVED::{filename}")

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
