import numpy as np
import matplotlib.pyplot as plt
import os
import io
import time
import pathlib
import scipy.signal as signal
from scipy.fft import fft as scipy_fft, ifft as scipy_ifft, fftshift as scipy_fftshift, ifftshift as scipy_ifftshift

def unilab_fft(x): return scipy_fft(x)
def unilab_ifft(x): return scipy_ifft(x)
def unilab_fftshift(x): return scipy_fftshift(x)
def unilab_ifftshift(x): return scipy_ifftshift(x)

def _unilab_vec(x):
    """Converts a potential 2D matrix (1xN or Nx1) to a 1D vector for Scipy functions."""
    if isinstance(x, np.ndarray):
        if x.ndim == 2:
            if x.shape[0] == 1:
                return x[0]
            if x.shape[1] == 1:
                return x[:, 0]
    return x

def unilab_filter(b, a, x): return signal.lfilter(_unilab_vec(b), _unilab_vec(a), x)
def unilab_filtfilt(b, a, x): return signal.filtfilt(_unilab_vec(b), _unilab_vec(a), x)
def unilab_butter(*args, **kwargs):
    args = [_unilab_vec(a) for a in args]
    kwargs = {k: _unilab_vec(v) for k, v in kwargs.items()}
    return signal.butter(*args, **kwargs)

def unilab_cheby1(*args, **kwargs):
    args = [_unilab_vec(a) for a in args]
    kwargs = {k: _unilab_vec(v) for k, v in kwargs.items()}
    return signal.cheby1(*args, **kwargs)

def unilab_cheby2(*args, **kwargs):
    args = [_unilab_vec(a) for a in args]
    kwargs = {k: _unilab_vec(v) for k, v in kwargs.items()}
    return signal.cheby2(*args, **kwargs)

def unilab_ellip(*args, **kwargs):
    args = [_unilab_vec(a) for a in args]
    kwargs = {k: _unilab_vec(v) for k, v in kwargs.items()}
    return signal.ellip(*args, **kwargs)

def unilab_tf(num, den): return signal.TransferFunction(_unilab_vec(num), _unilab_vec(den))

def unilab_tf2ss(num, den):
    return signal.tf2ss(_unilab_vec(num), _unilab_vec(den))

def unilab_ss2tf(A, B, C, D, iu=0):
    return signal.ss2tf(A, B, C, D, input=iu)

def unilab_ss(A, B, C, D): return signal.StateSpace(A, B, C, D)

def unilab_ssdata(sys):
    if not isinstance(sys, signal.StateSpace):
        sys = sys.to_ss()
    return sys.A, sys.B, sys.C, sys.D

def unilab_series(sys1, sys2):
    s1 = sys1 if isinstance(sys1, signal.TransferFunction) else sys1.to_tf()
    s2 = sys2 if isinstance(sys2, signal.TransferFunction) else sys2.to_tf()
    num = np.convolve(s1.num, s2.num)
    den = np.convolve(s1.den, s2.den)
    return signal.TransferFunction(num, den)

def unilab_feedback(sys1, sys2=None, sign=-1):
    if sys2 is None:
        sys2 = signal.TransferFunction([1], [1])
    s1 = sys1 if isinstance(sys1, signal.TransferFunction) else sys1.to_tf()
    s2 = sys2 if isinstance(sys2, signal.TransferFunction) else sys2.to_tf()
    num = np.convolve(s1.num, s2.den)
    den_part1 = np.convolve(s1.den, s2.den)
    den_part2 = np.convolve(s1.num, s2.num)
    max_len = max(len(den_part1), len(den_part2))
    d1 = np.pad(den_part1, (max_len - len(den_part1), 0))
    d2 = np.pad(den_part2, (max_len - len(den_part2), 0))
    if sign < 0:
        den = d1 + d2
    else:
        den = d1 - d2
    return signal.TransferFunction(num, den)

def unilab_rlocus(sys):
    s = sys if isinstance(sys, signal.TransferFunction) else sys.to_tf()
    num = s.num
    den = s.den
    # Use a more balanced gain range for visibility
    gains = np.logspace(-2, 3, 500)
    all_roots = []
    for k in gains:
        poly_num = k * num
        max_len = max(len(den), len(poly_num))
        p1 = np.pad(den, (max_len - len(den), 0))
        p2 = np.pad(poly_num, (max_len - len(poly_num), 0))
        all_roots.append(np.roots(p1 + p2))
    
    all_roots = np.array(all_roots)
    
    # Track roots to maintain branch continuity
    tracked = np.zeros_like(all_roots)
    tracked[0] = all_roots[0]
    for i in range(1, len(all_roots)):
        prev = tracked[i-1]
        curr = all_roots[i]
        new_row = np.zeros_like(curr)
        used_curr = set()
        for j in range(len(prev)):
            best_dist = float('inf')
            best_idx = 0
            for k_idx in range(len(curr)):
                if k_idx in used_curr: continue
                dist = np.abs(curr[k_idx] - prev[j])
                if dist < best_dist:
                    best_dist = dist
                    best_idx = k_idx
            new_row[j] = curr[best_idx]
            used_curr.add(best_idx)
        tracked[i] = new_row

    plt.clf()
    # High-contrast colors for terminal
    colors = ['#0000FF', '#008000', '#FF0000', '#800080', '#FFA500', '#00CED1']
    for i in range(tracked.shape[1]):
        plt.plot(np.real(tracked[:, i]), np.imag(tracked[:, i]), 
                 color=colors[i % len(colors)], linewidth=10)
    
    ol_poles = np.roots(den)
    ol_zeros = np.roots(num)
    plt.plot(np.real(ol_poles), np.imag(ol_poles), 'rx', markersize=25, markeredgewidth=8, label='Poles')
    if len(ol_zeros) > 0:
        plt.plot(np.real(ol_zeros), np.imag(ol_zeros), 'bo', markersize=25, markeredgewidth=8, label='Zeros')
    
    plt.axhline(0, color='black', lw=2)
    plt.axvline(0, color='black', lw=2)
    
    # Add S-plane grid (constant damping and natural frequency)
    xlim = plt.xlim()
    ylim = plt.ylim()
    max_r = 1.5 * max(max(abs(xlim[0]), abs(xlim[1])), max(abs(ylim[0]), abs(ylim[1])))
    
    # Damping ratio lines
    zeta_vals = [0.2, 0.4, 0.6, 0.8, 0.9]
    for z in zeta_vals:
        angle = np.pi - np.arccos(z)
        plt.plot([0, max_r*np.cos(angle)], [0, max_r*np.sin(angle)], 'k:', alpha=0.2, linewidth=1.5)
        plt.plot([0, max_r*np.cos(angle)], [0, -max_r*np.sin(angle)], 'k:', alpha=0.2, linewidth=1.5)
        
    # Natural frequency circles
    wn_vals = np.linspace(0, max_r, 6)[1:]
    for w in wn_vals:
        circle = plt.Circle((0, 0), w, color='k', fill=False, linestyle=':', alpha=0.2, linewidth=1.5)
        plt.gca().add_artist(circle)

    plt.title('Root Locus', fontweight='bold', fontsize=26)
    plt.xlabel('Real Axis', fontweight='bold', fontsize=20)
    plt.ylabel('Imaginary Axis', fontweight='bold', fontsize=20)
    plt.grid(True, linestyle='--', alpha=0.5, linewidth=2)
    plt.legend(loc='upper right', fontsize=14, framealpha=0.8)
    
    # Smarter axis scaling for terminal
    plt.axis('tight')
    xlim = plt.xlim()
    ylim = plt.ylim()
    # Ensure some padding
    xr = xlim[1] - xlim[0]
    yr = ylim[1] - ylim[0]
    if xr < 0.2 * yr:
        center = (xlim[0] + xlim[1]) / 2
        plt.xlim(center - 0.25 * yr, center + 0.25 * yr)
    elif yr < 0.2 * xr:
        center = (ylim[0] + ylim[1]) / 2
        plt.ylim(center - 0.25 * xr, center + 0.25 * xr)
    
    plt.axis('equal')
    _unilab_refresh_graph()
    return tracked, gains

def unilab_zpk(z, p, k): return signal.ZerosPolesGain(_unilab_vec(z), _unilab_vec(p), k)

def unilab_step(sys, T=None): 
    t, y = signal.step(sys, T=_unilab_vec(T) if T is not None else None)
    return t, y

def unilab_impulse(sys, T=None): 
    t, y = signal.impulse(sys, T=_unilab_vec(T) if T is not None else None)
    return t, y

def unilab_lsim(sys, U, T): 
    t, y, x = signal.lsim(sys, _unilab_vec(U), _unilab_vec(T))
    return t, y

def unilab_bode(sys, w=None): 
    w, mag, phase = signal.bode(sys, w=_unilab_vec(w) if w is not None else None)
    return w, mag, phase

def unilab_freqfreqz(b, a, worN=None):
    w, h = signal.freqz(_unilab_vec(b), _unilab_vec(a), worN=worN)
    return w, h

def unilab_conv(a, v, mode='full'):
    return signal.convolve(_unilab_vec(a), _unilab_vec(v), mode=mode)

def unilab_xcorr(a, v=None, mode='full'):
    if v is None: v = a
    return signal.correlate(_unilab_vec(a), _unilab_vec(v), mode=mode)

def unilab_pwelch(x, fs=1.0):
    f, Pxx = signal.welch(_unilab_vec(x), fs=fs)
    return f, Pxx

def _poly_to_str(coeffs, var='s'):
    n = len(coeffs) - 1
    terms = []
    for i, c in enumerate(coeffs):
        p = n - i
        if c == 0: continue
        
        if abs(c) == 1 and p > 0:
            c_str = '' if c > 0 else '-'
        else:
            if float(c).is_integer():
                c_str = f'{int(c)}'
            else:
                c_str = f'{c:.4g}'
        
        if p == 0:
            if float(c).is_integer():
                terms.append(f'{int(c)}')
            else:
                terms.append(f'{c:.4g}')
        elif p == 1:
            terms.append(f'{c_str}{var}')
        else:
            terms.append(f'{c_str}{var}^{p}')
            
    if not terms: return '0'
    
    res = terms[0]
    for t in terms[1:]:
        if t.startswith('-'):
            res += ' - ' + t[1:]
        else:
            res += ' + ' + t
    return res

def _format_transfer_function(sys):
    num_str = _poly_to_str(sys.num)
    den_str = _poly_to_str(sys.den)
    width = max(len(num_str), len(den_str)) + 2
    
    line = '-' * width
    num_pad = ' ' * ((width - len(num_str)) // 2)
    den_pad = ' ' * ((width - len(den_str)) // 2)
    
    return f'{num_pad}{num_str}\n{line}\n{den_pad}{den_str}'

def _format_zpk(sys):
    def format_roots(roots):
        if len(roots) == 0: return ''
        terms = []
        for r in roots:
            if r == 0:
                terms.append('s')
            else:
                r_val = float(r) if np.isreal(r) else r
                if isinstance(r_val, float):
                    if r_val > 0:
                        terms.append(f'(s - {r_val:.4g})')
                    else:
                        terms.append(f'(s + {abs(r_val):.4g})')
                else:
                    # Complex root
                    re = r_val.real
                    im = r_val.imag
                    sign = '+' if im >= 0 else '-'
                    terms.append(f'(s - ({re:.4g} {sign} {abs(im):.4g}j))')
        return ''.join(terms)

    z_str = format_roots(sys.zeros)
    p_str = format_roots(sys.poles)
    k = sys.gain
    k_str = f'{k:.4g}' if not float(k).is_integer() else f'{int(k)}'
    
    num_str = f'{k_str}{z_str}' if z_str else k_str
    if z_str and not k_str.endswith('-'):
        # Add * if k is not 1 or -1 for clarity, or just keep it simple
        if k_str != '1' and k_str != '-1':
             num_str = f'{k_str}{z_str}' # Already have this
        elif k_str == '-1':
             num_str = f'-{z_str}'
        else:
             num_str = z_str
    
    den_str = p_str if p_str else '1'
        
    width = max(len(num_str), len(den_str)) + 2
    line = '-' * width
    num_pad = ' ' * ((width - len(num_str)) // 2)
    den_pad = ' ' * ((width - len(den_str)) // 2)
    
    return f'{num_pad}{num_str}\n{line}\n{den_pad}{den_str}'

def _format_ss(sys):
    def matrix_to_str(mat, name):
        if mat.ndim == 1:
            mat = mat.reshape(1, -1)
        lines = []
        for row in mat:
            row_str = '  '.join([f'{val:g}' for val in row])
            lines.append(f'    [{row_str}]')
        return f'{name} =\n' + '\n'.join(lines)

    return f"{matrix_to_str(sys.A, 'A')}\n\n{matrix_to_str(sys.B, 'B')}\n\n{matrix_to_str(sys.C, 'C')}\n\n{matrix_to_str(sys.D, 'D')}"

def _format_value(val):
    if isinstance(val, signal.TransferFunction):
        return _format_transfer_function(val)
    if isinstance(val, signal.ZerosPolesGain):
        return _format_zpk(val)
    if isinstance(val, signal.StateSpace):
        return _format_ss(val)
    if hasattr(val, '__module__') and 'sympy' in val.__module__:
        import sympy
        try:
            return sympy.pretty(val, use_unicode=True)
        except:
            return str(val)
    return str(val)

def disp(x):
    print(_format_value(x))


def clc():
    os.system('cls' if os.name == 'nt' else 'clear')

def whos():
    """Lists variables in the current workspace."""
    pass

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
        formatted = _format_value(val)
        if '\n' in formatted:
            print(f"{name} =\n\n{formatted}\n")
        else:
            print(f"{name} =\n   {formatted}\n")

def unilab_print_and_save_ans(expr, val):
    global ans
    ans = val
    if val is not None and not _should_suppress_output(val):
        formatted = _format_value(val)
        if '\n' in formatted:
            print(f"ans =\n\n{formatted}\n")
        else:
            print(f"ans =\n   {formatted}\n")
    return val

def unilab_call(obj, *args):
    if callable(obj):
        return obj(*args)
    if len(args) == 0: return obj
    
    # Handle array/list indexing
    if len(args) == 1:
        idx = args[0]
        if isinstance(obj, np.ndarray):
            # Logical indexing
            if isinstance(idx, np.ndarray) and idx.dtype == bool:
                res = obj[idx.flatten() if obj.ndim == 1 else idx]
                if res.size == 1: return res.item()
                return res
                
            flat = obj.flatten()
            if isinstance(idx, (int, np.integer, float, np.floating)): return flat[int(idx)-1]
            if isinstance(idx, (list, np.ndarray, slice)): 
                res = flat[np.asarray(idx).astype(int) - 1] if not isinstance(idx, slice) else flat[idx]
                if isinstance(res, np.ndarray) and res.size == 1: return res.item()
                return res
        if isinstance(obj, (list, tuple)):
            if isinstance(idx, (int, np.integer, float, np.floating)): return obj[int(idx)-1]
            
    processed = []
    for i in args:
        if isinstance(i, (int, np.integer, float, np.floating)):
            processed.append(int(i)-1)
        elif isinstance(i, np.ndarray) and i.dtype == bool:
            processed.append(i.flatten() if i.ndim > 1 else i)
        else:
            processed.append(i)
            
    res = obj[tuple(processed)]
    
    # If the result is an array but we indexed with multiple values, 
    # try to keep it 2D if the original was 2D and we sliced.
    if isinstance(res, np.ndarray) and isinstance(obj, np.ndarray) and obj.ndim >= 2:
        if res.ndim == 1:
            # If we took a column, make it Mx1. If we took a row, make it 1xN.
            # Heuristic: if first arg was a slice and second was int, it's a column.
            if isinstance(args[0], (slice, str)) and isinstance(args[1], (int, np.integer, float, np.floating)):
                res = res.reshape(-1, 1)
            elif isinstance(args[0], (int, np.integer, float, np.floating)) and isinstance(args[1], (slice, str)):
                res = res.reshape(1, -1)
                
    if isinstance(res, np.ndarray) and res.size == 1:
        return res.item()
    return res

def unilab_mul(a, b):
    if np.isscalar(a) and np.isscalar(b): return a * b
    try:
        res = np.dot(a, b)
        if isinstance(res, np.ndarray) and res.size == 1:
            return res.item()
        return res
    except: 
        res = a * b
        if isinstance(res, np.ndarray) and res.size == 1:
            return res.item()
        return res

def unilab_div(a, b):
    if np.isscalar(a) and np.isscalar(b): return a / b
    try: 
        res = np.linalg.solve(np.atleast_2d(b).T, np.atleast_2d(a).T).T
        if isinstance(res, np.ndarray) and res.size == 1:
            return res.item()
        return res
    except: 
        res = a / b
        if isinstance(res, np.ndarray) and res.size == 1:
            return res.item()
        return res

def unilab_pow(a, b):
    if np.isscalar(a) and np.isscalar(b): return a ** b
    try: 
        res = np.linalg.matrix_power(a, b)
        if isinstance(res, np.ndarray) and res.size == 1:
            return res.item()
        return res
    except: 
        res = a ** b
        if isinstance(res, np.ndarray) and res.size == 1:
            return res.item()
        return res

def unilab_and(a, b): return np.logical_and(a, b)
def unilab_or(a, b): return np.logical_or(a, b)

def unilab_eq(a, b):
    if _is_symbolic(a) or _is_symbolic(b):
        import sympy
        return sympy.Eq(a, b)
    return a == b

def unilab_ne(a, b):
    if _is_symbolic(a) or _is_symbolic(b):
        import sympy
        return sympy.Ne(a, b)
    return a != b

def unilab_lt(a, b):
    if _is_symbolic(a) or _is_symbolic(b):
        import sympy
        return a < b # SymPy supports this for symbolic expr
    return a < b

def unilab_gt(a, b):
    if _is_symbolic(a) or _is_symbolic(b):
        import sympy
        return a > b
    return a > b

def unilab_le(a, b):
    if _is_symbolic(a) or _is_symbolic(b):
        import sympy
        return a <= b
    return a <= b

def unilab_ge(a, b):
    if _is_symbolic(a) or _is_symbolic(b):
        import sympy
        return a >= b
    return a >= b

def unilab_get(obj, attr):
    if isinstance(obj, dict): return obj.get(attr)
    return getattr(obj, attr)

def unilab_set(obj, val, *args):
    if len(args) == 1:
        idx = args[0]
        # Flatten boolean masks for consistent indexing
        if isinstance(idx, np.ndarray) and idx.dtype == bool:
            idx_adj = idx.flatten()
        else:
            idx_adj = int(idx)-1 if isinstance(idx, (int, np.integer, float, np.floating)) else idx
            
        if isinstance(obj, np.ndarray):
            if obj.ndim == 1: 
                obj[idx_adj] = val
            elif obj.ndim == 2:
                if obj.shape[0] == 1: obj[0, idx_adj] = val
                elif obj.shape[1] == 1: 
                    # If idx_adj is a flattened boolean mask, it must be used correctly
                    if isinstance(idx_adj, np.ndarray) and idx_adj.dtype == bool:
                        obj[idx_adj.reshape(obj.shape[0], obj.shape[1])] = val
                    else:
                        obj[idx_adj, 0] = val
                else: 
                    if isinstance(idx_adj, np.ndarray) and idx_adj.dtype == bool:
                        obj[idx_adj.reshape(obj.shape)] = val
                    else:
                        obj.flat[idx_adj] = val
            return obj
        obj[idx_adj] = val
    elif len(args) > 1:
        processed = [int(i)-1 if isinstance(i, (int, np.integer, float, np.floating)) else i for i in args]
        obj[tuple(processed)] = val
    return obj

def unilab_matrix_concat(*rows):
    if not rows: return np.array([])

    # If it's a single string, return it (MATLAB char array)
    if len(rows) == 1 and isinstance(rows[0], str):
        return rows[0]

    # If a single list or array is passed, it represents a single row (or horizontal concat)
    if len(rows) == 1 and isinstance(rows[0], (list, np.ndarray)):
        items = rows[0]
        # Check for MATLAB-style string concatenation ['abc', 'def'] -> 'abcdef'
        if all(isinstance(r, (str, np.str_)) for r in items):
            return "".join(str(r) for r in items)

        # If any item is an array, we must horizontally stack them
        if any(isinstance(r, np.ndarray) for r in items):
            try:
                processed = [np.atleast_2d(r) for r in items]
                # If they are rows, hstack them. If they have same rows, hstack.
                # In UniLab [X, Y] where X and Y are matrices usually means horizontal concat.
                return np.hstack(processed)
            except:
                # Fallback to standard array creation
                return np.array(items, dtype=object)

        return np.atleast_2d(items)

    try:
        # Multi-row concatenation [A; B]
        processed_rows = []
        for r in rows:
            if isinstance(r, (list, np.ndarray)):
                if isinstance(r, list) and any(isinstance(item, np.ndarray) for item in r):
                    # Handle mixed row [X, 1, 2]
                    p_row = np.hstack([np.atleast_2d(item) for item in r])
                    processed_rows.append(p_row)
                else:
                    processed_rows.append(np.atleast_2d(r))
            elif isinstance(r, str):
                processed_rows.append(np.atleast_2d(list(r)))
            else:
                processed_rows.append(np.atleast_2d([r]))

        return np.vstack(processed_rows)
    except:
        # Fallback
        if all(isinstance(r, (str, np.str_)) for r in rows):
            return "".join(str(r) for r in rows)
        return np.array(rows, dtype=object)
def unilab_nargin_sum(gen):
    import builtins
    return builtins.sum(gen)

def unilab_cell_concat(*args):
    res = []
    for a in args:
        if isinstance(a, list): res.extend(a)
        else: res.append(a)
    return res

def cell(*args):
    if len(args) == 0: return np.empty((0, 0), dtype=object)
    if len(args) == 1:
        if isinstance(args[0], (list, tuple, np.ndarray)):
            shape = tuple(int(i) for i in args[0])
        else:
            shape = (int(args[0]), int(args[0]))
    else:
        shape = tuple(int(i) for i in args)
    return np.full(shape, None, dtype=object)

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

def find(condition):
    if isinstance(condition, np.ndarray):
        return np.where(condition)[0] + 1
    return np.array([1]) if condition else np.array([])

def norm(x, ord=None):
    return np.linalg.norm(x, ord=ord)

def argmin(x, axis=None):
    return np.argmin(x, axis=axis) + 1

def argmax(x, axis=None):
    return np.argmax(x, axis=axis) + 1

def argsort(x, axis=-1):
    return np.argsort(x, axis=axis) + 1

def syms(*names):
    if len(names) == 1 and isinstance(names[0], str) and ' ' in names[0]:
        names = names[0].split()
    
    import sympy
    import inspect
    frame = inspect.currentframe().f_back
    
    # Filter out empty names
    names = [n for n in names if str(n).strip()]
    
    if not names:
        return None
        
    symbols = sympy.symbols(names)
    
    if len(names) == 1:
        # symbols will be a single symbol if names was a string, 
        # but if names was a list it might be a tuple.
        res = symbols[0] if isinstance(symbols, (list, tuple)) else symbols
        frame.f_globals[str(names[0])] = res
        return res
    else:
        for name, sym in zip(names, symbols):
            frame.f_globals[str(name)] = sym
        return symbols

def simplify(expr):
    return sympy.simplify(expr)

def expand(expr):
    return sympy.expand(expr)

def factor(expr):
    return sympy.factor(expr)

def solve(eq, *args, **kwargs):
    import sympy
    return sympy.solve(eq, *args, **kwargs)

def subs(expr, *args):
    if not hasattr(expr, 'subs'):
        return expr
    
    if len(args) == 2:
        old, new = args
        # Handle MATLAB style: subs(expr, [x, y], [1, 2])
        if isinstance(old, (list, np.ndarray)) and isinstance(new, (list, np.ndarray)):
            if len(old) == len(new):
                # Convert to list of tuples for SymPy
                subs_list = list(zip(old, new))
                return expr.subs(subs_list)
    
    return expr.subs(*args)

def diff(x, *args, **kwargs):
    if hasattr(x, 'diff') or isinstance(x, sympy.Basic):
        return sympy.diff(x, *args, **kwargs)
    return np.diff(x, *args, **kwargs)

def unilab_int(expr, *args):
    import sympy
    if not isinstance(expr, sympy.Basic):
        # Fallback for numerical integration if it's an array
        pass
        
    if len(args) == 0:
        # try to find variable
        free_symbols = getattr(expr, 'free_symbols', set())
        var = sympy.Symbol('x') if not free_symbols else sorted(free_symbols, key=lambda x: x.name)[0]
        return sympy.integrate(expr, var)
    
    # args could be (var) or (var, a, b)
    return sympy.integrate(expr, args)

def limit(expr, var, value, direction='both'):
    import sympy
    return sympy.limit(expr, var, value, direction)

def taylor(expr, var, point=0, order=6):
    import sympy
    return sympy.series(expr, var, point, order)

def unilab_laplace(f, t=None, s=None):
    import sympy
    if t is None:
        # Try to find 't' in the expression
        free_symbols = getattr(f, 'free_symbols', set())
        t = sympy.Symbol('t') if not free_symbols else sorted(free_symbols, key=lambda x: x.name)[0]
    if s is None:
        s = sympy.Symbol('s')
    
    res = sympy.laplace_transform(f, t, s, noconds=True)
    return res

def unilab_ilaplace(F, s=None, t=None):
    import sympy
    if s is None:
        free_symbols = getattr(F, 'free_symbols', set())
        s = sympy.Symbol('s') if not free_symbols else sorted(free_symbols, key=lambda x: x.name)[0]
    if t is None:
        t = sympy.Symbol('t')
    
    res = sympy.inverse_laplace_transform(F, s, t)
    return res

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
def _is_symbolic(x):
    return hasattr(x, '__module__') and 'sympy' in x.__module__

def abs(x):
    if _is_symbolic(x):
        import sympy
        return sympy.Abs(x)
    return np.abs(x)

def round(x): return np.round(x)
def floor(x):
    if _is_symbolic(x):
        import sympy
        return sympy.floor(x)
    return np.floor(x)

def ceil(x):
    if _is_symbolic(x):
        import sympy
        return sympy.ceil(x)
    return np.ceil(x)

def fix(x): return np.trunc(x)
def rem(x, y): return np.remainder(x, y)
def sign(x): return np.sign(x)

def sin(x):
    """Sine of argument in radians."""
    if _is_symbolic(x):
        import sympy
        return sympy.sin(x)
    return np.sin(x)

def cos(x):
    """Cosine of argument in radians."""
    if _is_symbolic(x):
        import sympy
        return sympy.cos(x)
    return np.cos(x)

def tan(x):
    """Tangent of argument in radians."""
    if _is_symbolic(x):
        import sympy
        return sympy.tan(x)
    return np.tan(x)

def exp(x):
    """Exponential."""
    if _is_symbolic(x):
        import sympy
        return sympy.exp(x)
    return np.exp(x)

def log(x):
    """Natural logarithm."""
    if _is_symbolic(x):
        import sympy
        return sympy.log(x)
    return np.log(x)

def sqrt(x):
    """Square root."""
    if _is_symbolic(x):
        import sympy
        return sympy.sqrt(x)
    return np.sqrt(x)

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
    return np.random.randn(*args) if args else np.random.randn()

def randi(imax, *args):
    """Random integers from 1 to imax."""
    if not args:
        return np.random.randint(1, int(imax) + 1)
    if len(args) == 1 and isinstance(args[0], (list, tuple, np.ndarray)):
        size = tuple(int(i) for i in args[0])
    else:
        size = tuple(int(i) for i in args)
    return np.random.randint(1, int(imax) + 1, size=size)

def diag(v, k=0):
    if isinstance(v, np.ndarray) and v.ndim == 2:
        if v.shape[0] == 1 or v.shape[1] == 1:
            return np.diag(v.flatten(), k)
    return np.diag(v, k)

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
        original_title = ax.get_title()
        original_xlabel = ax.get_xlabel()
        original_ylabel = ax.get_ylabel()
        
        meta = {
            "title": original_title,
            "xlabel": original_xlabel,
            "ylabel": original_ylabel,
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
        
        # Temporarily hide text to avoid pixelation in ASCII view
        ax.set_title('')
        ax.set_xlabel('')
        ax.set_ylabel('')
        legend = ax.get_legend()
        if legend: legend.set_visible(False)
        
        plt.savefig("graph.jpg", format='jpg', bbox_inches='tight')
        
        # Restore original state
        ax.set_title(original_title)
        ax.set_xlabel(original_xlabel)
        ax.set_ylabel(original_ylabel)
        if legend: legend.set_visible(True)

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
    """
    Plot vectors or matrices.
    Example:
        x = 0:0.1:10;
        y = sin(x);
        plot(x, y);
    """
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

def plot_nn(layers, title="Neural Network Architecture"):
    """Plots a neural network architecture."""
    from backend.ml.visualizers.nn_vis import plot_neural_network
    res = plot_neural_network(layers, title=title)
    return res

def plot_neural_network(layers, title="Neural Network Architecture"):
    """Alias for plot_nn."""
    return plot_nn(layers, title=title)

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
            
        target_w = min(width or 100, term_cols - 4)
        target_h = int(target_w * (im.height / im.width) * 0.5)
        if target_h < 20: target_h = 20
        if target_h > 50: target_h = 50
        
        # Resize
        img = im.resize((target_w, target_h), Image.Resampling.LANCZOS)
        pixels = img.load()
        
        # ASCII density ramp
        ramp = " .:-=+*#%@MB"
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
                
                # Apply TrueColor to the character
                if luma < 250:
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

def unilab_iter(x):
    """Iterates over a UniLab object (columns for 2D arrays)."""
    if isinstance(x, np.ndarray):
        if x.ndim <= 1:
            return iter(x)
        # Iterate over columns (MATLAB style)
        return (x[:, i] if x.shape[0] > 1 else x[0, i] for i in range(x.shape[1]))
    return iter(x)

def struct(*args):
    """Creates a UniLab structure (dictionary)."""
    res = {}
    if len(args) == 0:
        return res
    
    # Handle struct('field1', val1, 'field2', val2, ...)
    for i in range(0, len(args), 2):
        if i+1 < len(args):
            res[args[i]] = args[i+1]
    return res
