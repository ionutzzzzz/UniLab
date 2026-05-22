import numpy as np
import matplotlib.pyplot as plt
import os
import io
import time
import pathlib
import builtins
import inspect
import scipy.signal as signal
from contextvars import ContextVar
from scipy.fft import fft as scipy_fft, ifft as scipy_ifft, fftshift as scipy_fftshift, ifftshift as scipy_ifftshift
from backend.core.simulation.engine import unilab_simulate as simulate

# ContextVar for thread-safe session workspace path
unilab_workspace_ctx = ContextVar('unilab_workspace', default=None)

# Store for 3D plot data (fig_num -> {type, x, y, z})
_unilab_3d_data_store = {}

def uibutton(label, callback):
    """Adds a custom button to the current simulation window."""
    from backend.core.simulation.engine import _current_sim_window
    if _current_sim_window:
        layout = getattr(_current_sim_window, 'custom_layout', getattr(_current_sim_window, 'controls_layout', None))
        return _current_sim_window.add_custom_button(label, callback, layout=layout)
    return None

def uislider(label, min_v, max_v, init_v, callback):
    """Adds a custom slider to the current simulation window."""
    from backend.core.simulation.engine import _current_sim_window
    if _current_sim_window:
        layout = getattr(_current_sim_window, 'custom_layout', getattr(_current_sim_window, 'controls_layout', None))
        return _current_sim_window.add_custom_slider(label, min_v, max_v, init_v, callback, layout=layout)
    return None

def uicheckbox(label, initial_state, callback):
    """Adds a custom checkbox to the current simulation window."""
    from backend.core.simulation.engine import _current_sim_window
    if _current_sim_window:
        layout = getattr(_current_sim_window, 'custom_layout', getattr(_current_sim_window, 'controls_layout', None))
        return _current_sim_window.add_custom_checkbox(label, initial_state, callback, layout=layout)
    return None

def uidropdown(label, options, callback):
    """Adds a custom dropdown to the current simulation window."""
    from backend.core.simulation.engine import _current_sim_window
    if _current_sim_window:
        layout = getattr(_current_sim_window, 'custom_layout', getattr(_current_sim_window, 'controls_layout', None))
        return _current_sim_window.add_custom_dropdown(label, options, callback, layout=layout)
    return None

def uiedit(label, initial_text, callback):
    """Adds a custom text input to the current simulation window."""
    from backend.core.simulation.engine import _current_sim_window
    if _current_sim_window:
        layout = getattr(_current_sim_window, 'custom_layout', getattr(_current_sim_window, 'controls_layout', None))
        return _current_sim_window.add_custom_input(label, initial_text, callback, layout=layout)
    return None

def uilabel(label_id, initial_text):
    """Adds a custom label to the current simulation window."""
    from backend.core.simulation.engine import _current_sim_window
    if _current_sim_window:
        layout = getattr(_current_sim_window, 'custom_layout', getattr(_current_sim_window, 'controls_layout', None))
        return _current_sim_window.add_custom_label(label_id, initial_text, layout=layout)
    return None

def uiset(control_id, value):
    """Updates the value of a custom UI control."""
    from backend.core.simulation.engine import _current_sim_window
    if _current_sim_window:
        _current_sim_window.update_control_value(control_id, value)
    return None

def uitext(x, y, string, **kwargs):
    """Adds custom text to the current simulation plot."""
    from backend.core.simulation.engine import _current_sim_window
    if _current_sim_window and hasattr(_current_sim_window, 'ax'):
        return _current_sim_window.ax.text(x, y, str(string), **kwargs)
    return None

def uicontrols_clear():
    """Clears all custom UI controls from the current simulation window."""
    from backend.core.simulation.engine import _current_sim_window
    if _current_sim_window:
        layout = getattr(_current_sim_window, 'custom_layout', None)
        if layout:
            while layout.count():
                item = layout.takeAt(0)
                widget = item.widget()
                if widget: widget.deleteLater()
        _current_sim_window.custom_controls.clear()
    return None

def unilab_struct(*args, **kwargs):
    """Creates a UniLab struct (Python dictionary). Handles both keyword and name-value pairs."""
    res = {}
    res.update(kwargs)
    if len(args) >= 2 and isinstance(args[0], str):
        for i in range(0, len(args), 2):
            if i + 1 < len(args):
                res[args[i]] = args[i+1]
    elif len(args) == 1 and isinstance(args[0], dict):
        res.update(args[0])
    return res

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

# --- Standard UniLab Constants ---
inf = np.inf
Inf = np.inf
nan = np.nan
NaN = np.nan
pi = np.pi
eps = np.finfo(float).eps
i = 1j
j = 1j
realmax = np.finfo(float).max
realmin = np.finfo(float).tiny
true = True
false = False

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
    elif isinstance(sys2, (int, float, np.number)):
        sys2 = signal.TransferFunction([sys2], [1])
        
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
    # Handle empty T arrays - scipy.step requires None or non-empty array
    if T is not None and isinstance(T, np.ndarray) and T.size == 0:
        T = None
    elif T is not None and isinstance(T, list) and len(T) == 0:
        T = None
    elif T is not None:
        if isinstance(T, (int, float, np.integer, np.floating)):
            T = np.linspace(0, T, 1000)
        T = _unilab_vec(T)
    t, y = signal.step(sys, T=T)
    return t, y

def unilab_impulse(sys, T=None): 
    if T is not None:
        if isinstance(T, (int, float, np.integer, np.floating)):
            T = np.linspace(0, T, 1000)
        T = _unilab_vec(T)
    t, y = signal.impulse(sys, T=T)
    return t, y

def unilab_lsim(sys, U, T): 
    t, y, x = signal.lsim(sys, _unilab_vec(U), _unilab_vec(T))
    return t, y

def unilab_bode(sys, w=None): 
    w, mag, phase = signal.bode(sys, w=_unilab_vec(w) if w is not None else None)
    
    # Plotting for Bode
    if not _unilab_hold: 
        plt.cla()
        _unilab_update_fig_version()

    fig, (ax_mag, ax_phase) = plt.subplots(2, 1, figsize=(12, 10), sharex=True)
    
    ax_mag.semilogx(w, mag, linewidth=3)
    ax_mag.set_ylabel('Magnitude (dB)')
    ax_mag.grid(True, which='both', linestyle='--', alpha=0.5)
    ax_mag.set_title('Bode Plot')
    
    ax_phase.semilogx(w, phase, linewidth=3)
    ax_phase.set_ylabel('Phase (deg)')
    ax_phase.set_xlabel('Frequency (rad/s)')
    ax_phase.grid(True, which='both', linestyle='--', alpha=0.5)
    
    _unilab_refresh_graph()
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
    if hasattr(val, '__module__') and val.__module__ is not None and 'sympy' in val.__module__:
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
    # Find the user's workspace frame by going back until we are out of runtime.py
    frame = inspect.currentframe().f_back
    while frame and ('runtime.py' in frame.f_code.co_filename or 'inspect.py' in frame.f_code.co_filename):
        frame = frame.f_back
    
    if not frame:
        # Fallback to f_back if we can't find anything else
        frame = inspect.currentframe().f_back
    
    caller_globals = frame.f_globals
    
    variables = {}
    
    # Names we definitely want to hide (internal UniLab architecture and pre-populated constants)
    internal_names = {
        'np', 'plt', 'signal', 'unilab_workspace_ctx', '_unilab_3d_data_store',
        'unilab_simulate', 'simulate', 'scipy_fft', 'scipy_ifft', 'scipy_fftshift', 
        'scipy_ifftshift', 'builtins', 'inspect', 'io', 'os', 'pathlib', 'time',
        'UnilabEnd', 'unilab_end', 'UnilabHandle', 'UnilabCVPartition', 'ContextVar',
        'pi', 'inf', 'Inf', 'nan', 'NaN', 'eps', 'i', 'j', 'realmax', 'realmin', 
        'true', 'false', 'unilab_set', 'unilab_get', 'addpath', 'abs', 'stats', 'ml'
    }
    
    # Also hide anything that is defined in the runtime module itself
    runtime_names = set(dir(inspect.getmodule(whos)))
    for name, val in caller_globals.items():
        # Skip double-underscore internals
        if name.startswith('__'):
            continue
            
        # Skip names explicitly marked as internal or in runtime
        if name in internal_names or name in runtime_names:
            continue
            
        # Hide ans if it's None
        if name == 'ans' and val is None:
            continue
            
        # Skip modules and built-ins
        if inspect.ismodule(val) or inspect.isbuiltin(val):
            continue
            
        # Skip python functions unless they are wrapped handles or user-defined
        if inspect.isfunction(val):
            if name.startswith('unilab_'):
                continue
            # If it's a function from runtime, skip it
            try:
                mod = inspect.getmodule(val)
                if mod and 'runtime' in mod.__name__:
                    continue
            except:
                pass
        
        # Skip certain types that are part of the environment
        if isinstance(val, type) and (val.__module__ == 'builtins' or 'runtime' in val.__module__):
            continue

        variables[name] = val
    
    # Also check if 'ans' exists in caller_globals
    if 'ans' in caller_globals and caller_globals['ans'] is not None:
        variables['ans'] = caller_globals['ans']

    if not variables:
        return

    # Suppress ASCII output in web mode to allow rich HTML rendering
    if os.environ.get('UNILAB_WEB_MODE') == '1':
        return
        
    print(f"\n{'Name':<18} {'Size':<15} {'Bytes':<12} {'Class':<15}")
    print("-" * 60)
    
    for name in sorted(variables.keys()):
        val = variables[name]
        
        # Get size
        if hasattr(val, 'shape'):
            # Handle numpy arrays and similar
            shape = val.shape
            if not shape: # Scalar array
                size = "1x1"
            else:
                size = 'x'.join(map(str, shape))
        elif hasattr(val, '__len__') and not isinstance(val, (str, dict)):
            size = f"1x{len(val)}"
        else:
            size = "1x1"
            
        # Get bytes
        try:
            if hasattr(val, 'nbytes'):
                bytes_count = val.nbytes
            else:
                import sys
                bytes_count = sys.getsizeof(val)
        except:
            bytes_count = 0
            
        # Get class
        if hasattr(val, 'dtype'):
            cls = val.dtype.name
        else:
            cls = type(val).__name__
            
        # MATLAB-ify class names
        if cls == 'float64': cls = 'double'
        if cls == 'int64': cls = 'int'
        if cls == 'str': cls = 'char'
        if cls == 'bool': cls = 'logical'
            
        print(f"{name:<18} {size:<15} {bytes_count:<12} {cls:<15}")
    print("")

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

class UnilabEnd:
    def __init__(self, offset=0):
        self.offset = offset
    def __add__(self, other):
        return UnilabEnd(self.offset + other)
    def __sub__(self, other):
        return UnilabEnd(self.offset - other)
    def __radd__(self, other):
        return UnilabEnd(self.offset + other)
    def __repr__(self):
        return f"unilab_end{'' if self.offset == 0 else ('+' + str(self.offset) if self.offset > 0 else str(self.offset))}"

unilab_end = UnilabEnd()

def unilab_range(start, stop, step=1):
    if isinstance(start, UnilabEnd) or isinstance(stop, UnilabEnd):
        return slice(start, stop, step)
    # Standard numerical range
    return np.atleast_2d(np.arange(start, stop + step, step))


def _unilab_resolve_idx(idx, size):
    if isinstance(idx, UnilabEnd):
        return size + idx.offset - 1
    if idx is None: return None
    return int(idx) - 1

def _unilab_resolve_slice(slc, size):
    if not isinstance(slc, slice): return slc
    start = _unilab_resolve_idx(slc.start, size) if slc.start is not None else 0
    stop = _unilab_resolve_idx(slc.stop, size) + 1 if slc.stop is not None else size
    step = int(slc.step) if slc.step is not None else 1
    return slice(start, stop, step)

class UnilabHandle:
    def __init__(self, func):
        self.func = func
    def __call__(self, *args, **kwargs):
        return self.func(*args, **kwargs)
    def __repr__(self):
        return f"<function handle: {self.func}>"

def unilab_handle(func):
    if isinstance(func, UnilabHandle): return func
    return UnilabHandle(func)


def unilab_call_nargout(nargout, obj, *args, **kwargs):
    if callable(obj):
        if len(args) == 0 and len(kwargs) == 0 and isinstance(obj, UnilabHandle):
            return obj
            
        import builtins
        try:
            name = getattr(obj, '__name__', None)
            if name == 'abs' or obj == builtins.abs: return unilab_abs(*args, **kwargs)
            if name == 'round' or obj == builtins.round: return round(*args, **kwargs)
            if name == 'min' or obj == builtins.min: return min(*args, **kwargs)
            if name == 'max' or obj == builtins.max: return max(*args, **kwargs)
            if name == 'sum' or obj == builtins.sum: return sum(*args, **kwargs)
            if name == 'any' or obj == builtins.any: return any(*args, **kwargs)
            if name == 'all' or obj == builtins.all: return all(*args, **kwargs)
            if name == 'real' or obj == builtins.real: return real(*args, **kwargs)
            if name == 'imag' or obj == builtins.imag: return imag(*args, **kwargs)
        except: pass

        token = _unilab_nargout_ctx.set(nargout)
        try:
            res = obj(*args, **kwargs)
        finally:
            _unilab_nargout_ctx.reset(token)
            
        if isinstance(res, tuple):
            if nargout <= 1:
                return res[0] if res else None
            return res[:nargout]
        return res
    return unilab_call(obj, *args, **kwargs)

_unilab_nargout_ctx = ContextVar('unilab_nargout', default=None)

def unilab_call(obj, *args, **kwargs):
    if callable(obj):
        # Avoid auto-calling handles if no args given
        if len(args) == 0 and len(kwargs) == 0 and isinstance(obj, UnilabHandle):
            return obj
            
        # Handle built-in functions that might be passed (e.g. Python's abs vs UniLab's abs)
        import builtins
        # Check by name and identity to be absolutely sure
        try:
            name = getattr(obj, '__name__', None)
            if name == 'abs' or obj == builtins.abs: return unilab_abs(*args, **kwargs)
            if name == 'round' or obj == builtins.round: return round(*args, **kwargs)
            if name == 'min' or obj == builtins.min: return min(*args, **kwargs)
            if name == 'max' or obj == builtins.max: return max(*args, **kwargs)
            if name == 'sum' or obj == builtins.sum: return sum(*args, **kwargs)
            if name == 'any' or obj == builtins.any: return any(*args, **kwargs)
            if name == 'all' or obj == builtins.all: return all(*args, **kwargs)
            if name == 'real' or obj == builtins.real: return real(*args, **kwargs)
            if name == 'imag' or obj == builtins.imag: return imag(*args, **kwargs)
        except: pass

        return obj(*args, **kwargs)
    
    if len(args) == 0 and len(kwargs) == 0: return obj
    
    # Handle array/list/string indexing
    if len(args) == 1:
        idx = args[0]
        if isinstance(obj, np.ndarray):
            # Logical indexing
            if isinstance(idx, np.ndarray) and idx.dtype == bool:
                res = obj[idx.flatten() if obj.ndim == 1 else idx]
                if res.size == 1: return res.item()
                if res.ndim == 1:
                    if obj.ndim == 2 and obj.shape[1] == 1:
                        return res.reshape(-1, 1)
                    if obj.ndim == 2 and obj.shape[0] == 1:
                        return res.reshape(1, -1)
                return res
            
            if isinstance(idx, UnilabEnd):
                flat = obj.flatten()
                return flat[len(flat) + idx.offset - 1]
                
            flat = obj.flatten()
            if isinstance(idx, (int, np.integer, float, np.floating)): return flat[int(idx)-1]
            if isinstance(idx, (list, np.ndarray, slice)): 
                if isinstance(idx, slice):
                    if idx == slice(None): return flat.reshape(-1, 1)
                    res = flat[_unilab_resolve_slice(idx, flat.size)]
                else:
                    res = flat[np.asarray(idx).astype(int) - 1]
                if isinstance(res, np.ndarray) and res.size == 1: return res.item()
                if isinstance(res, np.ndarray) and res.ndim == 1: 
                    # Try to maintain orientation if original was column vector
                    if obj.ndim == 2 and obj.shape[1] == 1:
                        return res.reshape(-1, 1)
                    return res.reshape(1, -1)
                return res
        if isinstance(obj, (list, tuple, str)):
            if isinstance(idx, UnilabEnd):
                return obj[len(obj) + idx.offset - 1]
            if isinstance(idx, (int, np.integer, float, np.floating)): return obj[int(idx)-1]
            if isinstance(idx, slice): return obj[idx]
            if isinstance(idx, (list, np.ndarray)):
                indices = (np.asarray(idx).astype(int) - 1).tolist()
                res = [obj[i] for i in indices]
                return "".join(res) if isinstance(obj, str) else res
            
    processed = []
    for i, arg in enumerate(args):
        if isinstance(arg, UnilabEnd):
            processed.append(obj.shape[i] + arg.offset - 1)
        elif isinstance(arg, slice):
            processed.append(_unilab_resolve_slice(arg, obj.shape[i]))
        elif isinstance(arg, (int, np.integer, float, np.floating)):
            processed.append(int(arg)-1)
        elif isinstance(arg, (list, np.ndarray)) and not (isinstance(arg, np.ndarray) and arg.dtype == bool):
            arr_arg = np.asarray(arg)
            if arr_arg.ndim > 1 and (arr_arg.shape[0] == 1 or arr_arg.shape[1] == 1):
                processed.append(arr_arg.flatten().astype(int) - 1)
            else:
                processed.append(arr_arg.astype(int) - 1)
        elif isinstance(arg, np.ndarray) and arg.dtype == bool:
            processed.append(arg.flatten() if arg.ndim > 1 else arg)
        else:
            processed.append(arg)
            
    try:
        res = obj[tuple(processed)]
    except TypeError:
        if not hasattr(obj, '__getitem__'):
            # Scalar indexing
            res = np.atleast_2d(obj)[tuple(processed)]
        else:
            raise
    except (IndexError, ValueError):
        # Handle indexing into empty arrays gracefully if possible
        if isinstance(obj, np.ndarray) and obj.size == 0:
            return np.array([])
        raise
    
    # If the result is an array but we indexed with multiple values, 
    # try to keep it 2D if the original was 2D and we sliced.
    if isinstance(res, np.ndarray) and isinstance(obj, np.ndarray) and obj.ndim >= 2:
        if res.ndim == 1 and len(args) >= 2:
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
        # Matrix multiplication
        res = np.matmul(a, b)
        if isinstance(res, np.ndarray) and res.size == 1:
            return res.item()
        return res
    except: 
        res = a * b
        if isinstance(res, np.ndarray) and res.size == 1:
            return res.item()
        return res

def unilab_dot_mul(a, b):
    res = a * b
    if isinstance(res, np.ndarray) and res.size == 1:
        return res.item()
    return res

def unilab_div(a, b):
    if np.isscalar(a) and np.isscalar(b): return a / b
    try: 
        # Matrix right division: a / b  -> a * inv(b)
        res = np.linalg.solve(np.atleast_2d(b).T, np.atleast_2d(a).T).T
        if isinstance(res, np.ndarray) and res.size == 1:
            return res.item()
        return res
    except: 
        res = a / b
        if isinstance(res, np.ndarray) and res.size == 1:
            return res.item()
        return res

def unilab_dot_div(a, b):
    res = a / b
    if isinstance(res, np.ndarray) and res.size == 1:
        return res.item()
    return res

def unilab_ldiv(a, b):
    # Matrix left division: a \ b -> inv(a) * b
    if np.isscalar(a) and np.isscalar(b): return b / a
    try:
        res = np.linalg.solve(np.atleast_2d(a), np.atleast_2d(b))
        if isinstance(res, np.ndarray) and res.size == 1:
            return res.item()
        return res
    except:
        return b / a

def unilab_dot_ldiv(a, b):
    res = b / a
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

def unilab_dot_pow(a, b):
    res = np.power(a, b)
    if isinstance(res, np.ndarray) and res.size == 1:
        return res.item()
    return res

def unilab_and(a, b): return np.logical_and(a, b)
def unilab_or(a, b): return np.logical_or(a, b)

def all(a, axis=None):
    """MATLAB-compatible all() function that returns True if all elements are nonzero."""
    # Handle scalars and 0-d arrays
    if not isinstance(a, np.ndarray) or a.ndim == 0:
        return bool(a)
    result = np.all(a, axis=axis)
    # Return as Python scalar if 0-d array
    if isinstance(result, np.ndarray) and result.ndim == 0:
        return bool(result)
    return result

def any(a, axis=None):
    """MATLAB-compatible any() function that returns True if any element is nonzero."""
    # Handle scalars and 0-d arrays
    if not isinstance(a, np.ndarray) or a.ndim == 0:
        return bool(a)
    result = np.any(a, axis=axis)
    # Return as Python scalar if 0-d array
    if isinstance(result, np.ndarray) and result.ndim == 0:
        return bool(result)
    return result

def unilab_to_bool(val):
    """Convert values to boolean for use in if/while statements."""
    # Handle numpy arrays
    if isinstance(val, np.ndarray):
        if val.ndim == 0:  # 0-d array (scalar)
            return bool(val)
        elif val.size == 0:  # empty array
            return False
        elif val.size == 1:  # 1-element array
            return bool(val.item())
        else:  # multi-element array - use all() to match MATLAB behavior
            return np.all(val)
    # Handle standard Python types and numpy scalars
    return bool(val)

def unilab_eq(a, b):
    if _is_symbolic(a) or _is_symbolic(b):
        import sympy
        return sympy.Eq(a, b)
    return a == b

def isequal(a, b):
    """MATLAB-compatible isequal function."""
    if type(a) != type(b):
        # Special case for different numeric types that might be equivalent
        if isinstance(a, (int, float, np.number)) and isinstance(b, (int, float, np.number)):
            return a == b
        return False
    if isinstance(a, np.ndarray) or isinstance(b, np.ndarray):
        return np.array_equal(a, b)
    return a == b

def ischar(x):
    """MATLAB-compatible ischar function."""
    return isinstance(x, (str, bytes))

def iscell(x):
    """MATLAB-compatible iscell function."""
    return isinstance(x, (list, tuple)) or (isinstance(x, np.ndarray) and x.dtype == object)

def isnumeric(x):
    """MATLAB-compatible isnumeric function."""
    return isinstance(x, (int, float, complex, np.number, np.ndarray))

def lower(s):
    """MATLAB-compatible lower function."""
    if isinstance(s, str):
        return s.lower()
    if isinstance(s, (list, tuple)):
        return [lower(x) for x in s]
    if isinstance(s, np.ndarray) and s.dtype == object:
        vlower = np.vectorize(lower)
        return vlower(s)
    return s

def upper(s):
    """MATLAB-compatible upper function."""
    if isinstance(s, str):
        return s.upper()
    if isinstance(s, (list, tuple)):
        return [upper(x) for x in s]
    if isinstance(s, np.ndarray) and s.dtype == object:
        vupper = np.vectorize(upper)
        return vupper(s)
    return s

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
    if isinstance(obj, dict):
        if attr in obj: return obj[attr]
        # For dictionaries, return None but try to be helpful if it's a common attribute
        return obj.get(attr)
    try:
        return getattr(obj, attr)
    except AttributeError:
        # If attribute doesn't exist, return None instead of crashing
        # This matches MATLAB's behavior for some objects
        return None

def contour(*args, **kwargs):
    if len(args) > 0 and isinstance(args[0], str): return # skip figure name
    res = plt.contour(*args, **kwargs)
    _unilab_refresh_graph()
    return res

def histogram(*args, **kwargs):
    res = plt.hist(*args, **kwargs)
    _unilab_refresh_graph()
    return res

def log10(x): return np.log10(x)

def quiver(*args, **kwargs):
    fig = plt.gcf()
    if len(args) == 4 and fig.axes and fig.gca().name == '3d':
        # Force a new 2D subplot if we are currently in 3D but only have 4 args
        plt.clf()
        _unilab_update_fig_version()
    res = plt.quiver(*args, **kwargs)
    _unilab_refresh_graph()
    return res

def specgram(*args, **kwargs):
    # Ensure NFFT and other potential float args from UniLab are converted to int for matplotlib
    args = list(args)
    if len(args) > 0:
        x = args[0]
        if isinstance(x, np.ndarray):
            if x.ndim > 1 and (x.shape[0] == 1 or x.shape[1] == 1):
                args[0] = x.flatten()
        elif isinstance(x, list):
            args[0] = np.array(x).flatten()

    if len(args) > 1 and isinstance(args[1], (float, np.floating)):
        args[1] = int(args[1])
    res = plt.specgram(*args, **kwargs)
    _unilab_refresh_graph()
    return res

def unilab_set(obj, val, *args):
    if len(args) == 1 and isinstance(args[0], str):
        # Property set
        attr = args[0]
        try:
            setattr(obj, attr, val)
            return val
        except:
            if isinstance(obj, dict):
                obj[attr] = val
                return val
    
    if len(args) == 1:
        idx = args[0]
        # Flatten boolean masks for consistent indexing
        if isinstance(idx, np.ndarray) and idx.dtype == bool:
            idx_adj = idx.flatten()
        else:
            if isinstance(idx, UnilabEnd):
                idx_adj = len(obj.flatten()) + idx.offset - 1
            elif isinstance(idx, (list, np.ndarray)):
                idx_adj = np.asarray(idx).astype(int) - 1
            elif isinstance(idx, slice):
                idx_adj = _unilab_resolve_slice(idx, obj.size)
            else:
                idx_adj = int(idx)-1 if isinstance(idx, (int, np.integer, float, np.floating)) else idx
            
        if isinstance(obj, np.ndarray):
            v = val
            if isinstance(val, np.ndarray) and val.size == 1:
                v = val.item()
                
            # Handle automatic array expansion
            try:
                max_idx = np.max(idx_adj) if isinstance(idx_adj, (list, np.ndarray)) else (idx_adj.stop if isinstance(idx_adj, slice) and idx_adj.stop else idx_adj)
                if max_idx is not None and max_idx >= obj.size:
                    # Need to pad
                    pad_len = max_idx - obj.size + 1
                    # Pad along the longest dimension to maintain row/col vector shape
                    if obj.ndim == 2:
                        if obj.shape[0] == 1:
                            obj = np.pad(obj, ((0, 0), (0, pad_len)), mode='constant')
                        else:
                            obj = np.pad(obj, ((0, pad_len), (0, 0)), mode='constant')
                    else:
                        obj = np.pad(obj, (0, pad_len), mode='constant')
            except Exception:
                pass # Fallback to standard assignment if max_idx extraction fails
                
            try:
                obj.flat[idx_adj] = v
            except (IndexError, ValueError):
                if isinstance(idx_adj, (slice, list, np.ndarray)):
                    v_arr = np.asarray(v)
                    obj.flat[idx_adj] = v_arr.flatten() if v_arr.size > 1 else v_arr.item()
                else:
                    obj.flat[idx_adj] = v
            return obj
        try:
            obj[idx_adj] = val
        except TypeError:
            if not hasattr(obj, '__setitem__'):
                # Scalar set
                tmp_obj = np.atleast_2d(obj)
                if isinstance(idx_adj, (bool, np.bool_, np.ndarray)) and (not isinstance(idx_adj, np.ndarray) or idx_adj.dtype == bool):
                    tmp_obj[idx_adj] = val
                else:
                    tmp_obj.flat[idx_adj] = val
                return tmp_obj.item() if tmp_obj.size == 1 else tmp_obj
            raise
    elif len(args) > 1:
        processed = []
        for i, arg in enumerate(args):
            if isinstance(arg, UnilabEnd):
                processed.append(obj.shape[i] + arg.offset - 1)
            elif isinstance(arg, slice):
                processed.append(_unilab_resolve_slice(arg, obj.shape[i]))
            elif isinstance(arg, (int, np.integer, float, np.floating)):
                processed.append(int(arg)-1)
            elif isinstance(arg, (list, np.ndarray)) and not (isinstance(arg, np.ndarray) and arg.dtype == bool):
                arr_arg = np.asarray(arg)
                if arr_arg.ndim > 1 and (arr_arg.shape[0] == 1 or arr_arg.shape[1] == 1):
                    processed.append(arr_arg.flatten().astype(int) - 1)
                else:
                    processed.append(arr_arg.astype(int) - 1)
            elif isinstance(arg, np.ndarray) and arg.dtype == bool:
                processed.append(arg.flatten() if arg.ndim > 1 else arg)
            else:
                processed.append(arg)
        
        # Handle MATLAB-style orthogonal indexing for multiple array indices
        array_indices = [j for j, p in enumerate(processed) if isinstance(p, np.ndarray)]
        if len(array_indices) > 1:
            # Reshape 1D arrays to broadcast orthogonally (like np.ix_)
            # e.g., for 2D: first array becomes column vector, second becomes row vector
            for dim, idx_pos in enumerate(array_indices):
                if processed[idx_pos].ndim == 1:
                    new_shape = [1] * len(processed)
                    new_shape[idx_pos] = -1
                    processed[idx_pos] = processed[idx_pos].reshape(new_shape)
                    
        try:
            obj[tuple(processed)] = val
        except TypeError:
            if not hasattr(obj, '__setitem__'):
                # Promote to array to handle scalar indexing
                obj = np.atleast_2d(obj)
                return unilab_set(obj, val, *args)
            raise
        except ValueError:
            try:
                # Common case: assigning a column vector to a row slice or vice versa
                v_arr = np.asarray(val)
                target_shape = np.empty(obj.shape)[tuple(processed)].shape
                if v_arr.size == np.prod(target_shape):
                    obj[tuple(processed)] = v_arr.reshape(target_shape)
                else:
                    obj[tuple(processed)] = v_arr
            except:
                obj[tuple(processed)] = val
    return obj

def unilab_matrix_concat(*rows):
    if not rows: return np.empty((0, 0))

    # If it's a single string, return it (MATLAB char array)
    if len(rows) == 1 and isinstance(rows[0], str):
        return rows[0]

    # If a single list or array is passed, it represents a single row (or horizontal concat)
    if len(rows) == 1 and isinstance(rows[0], (list, np.ndarray)):
        items = rows[0]

        # If any item is an array (check this FIRST before string check)
        if builtins.any(isinstance(r, np.ndarray) for r in items):
            try:
                processed = []
                for r in items:
                    if isinstance(r, np.ndarray) and r.ndim == 1:
                        processed.append(r.reshape(-1, 1))
                    else:
                        processed.append(np.atleast_2d(r))
                # In UniLab [X, Y] where X and Y are matrices usually means horizontal concat.
                return np.hstack(processed)
            except:
                # Fallback to standard array creation
                return np.array(items, dtype=object)

        # Check for MATLAB-style string concatenation ['abc', 'def'] -> 'abcdef'
        if builtins.all(isinstance(r, (str, np.str_)) for r in items):
            return "".join(str(r) for r in items)

        return np.atleast_2d(items)

    try:
        # Multi-row concatenation [A; B]
        processed_rows = []
        for r in rows:
            if isinstance(r, (list, np.ndarray)):
                if isinstance(r, list) and builtins.any(isinstance(item, np.ndarray) for item in r):
                    # Handle mixed row [X, 1, 2]
                    # Filter out empty arrays that would cause hstack to have 0 columns if other parts have more
                    parts = [np.atleast_2d(item) for item in r]
                    if len(parts) > 1:
                        # If we have multiple parts, ignore those that are completely empty (0x0 or similar)
                        # but only if at least one part is NOT empty.
                        non_empty_parts = [p for p in parts if p.size > 0]
                        if non_empty_parts: parts = non_empty_parts
                    p_row = np.hstack(parts)
                    processed_rows.append(p_row)
                elif isinstance(r, list) and builtins.all(isinstance(item, (str, np.str_)) for item in r):
                    # Try numeric coercion for string lists
                    try:
                        numeric = [float(item) for item in r]
                        vals = [int(v) if v == int(v) else v for v in numeric]
                        processed_rows.append(np.atleast_2d(vals))
                    except (ValueError, TypeError):
                        processed_rows.append(np.atleast_2d(r))
                else:
                    processed_rows.append(np.atleast_2d(r))
            elif isinstance(r, str):
                processed_rows.append(np.atleast_2d(list(r)))
            else:
                processed_rows.append(np.atleast_2d([r]))

        # Filter out rows that are entirely empty IF there are non-empty rows
        if len(processed_rows) > 1:
            non_empty_rows = [row for row in processed_rows if row.size > 0]
            if non_empty_rows:
                # If non-empty rows have different column counts, this might still fail,
                # but it fixes the [ []; 2.0 ] case.
                processed_rows = non_empty_rows

        return np.vstack(processed_rows)
    except:
        # Fallback
        if builtins.all(isinstance(r, (str, np.str_)) for r in rows):
            return "".join(str(r) for r in rows)
        return np.array(rows, dtype=object)
def unilab_nargin_sum(gen):
    import builtins
    return builtins.sum(gen)

def unilab_get_nargout(for_call=True):
    val = _unilab_nargout_ctx.get()
    if val is not None:
        return val
    return 1

def unilab_process_varargout(outputs):
    """
    Processes the varargout from a function.
    If outputs is a tuple/list and the last element is the varargout cell array,
    it unpacks it.
    """
    if isinstance(outputs, (list, tuple)):
        # Check if the last element is a potential varargout (cell array/list)
        if len(outputs) > 0:
            last = outputs[-1]
            if isinstance(last, (list, np.ndarray)):
                res = list(outputs[:-1])
                if isinstance(last, np.ndarray):
                    res.extend(last.flatten().tolist())
                else:
                    res.extend(last)
                return tuple(res)
    elif isinstance(outputs, (list, np.ndarray)):
        # varargout was the only return
        if isinstance(outputs, np.ndarray):
            return tuple(outputs.flatten().tolist())
        return tuple(outputs)
    return outputs

def unilab_cell_concat(*rows):
    if not rows: return np.empty((0, 0), dtype=object)
    try:
        processed = [np.array(r, dtype=object) for r in rows]
        return np.vstack(processed)
    except:
        res = []
        for r in rows:
            if isinstance(r, list): res.extend(r)
            else: res.append(r)
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

def real(x): return np.real(x)
def imag(x): return np.imag(x)

def mod(x, y): return np.mod(x, y)

import sympy
def isempty(x):
    if x is None: return True
    if isinstance(x, np.ndarray): return x.size == 0
    if hasattr(x, '__len__'): return len(x) == 0
    return False

def isvector(x):
    if isinstance(x, np.ndarray):
        return x.ndim == 1 or (x.ndim == 2 and (x.shape[0] == 1 or x.shape[1] == 1))
    if isinstance(x, (list, tuple)):
        return True
    return False

def find(condition, k=None, direction='first'):
    if isinstance(condition, np.ndarray):
        indices = np.where(condition.flatten())[0] + 1
        if k is not None:
            k = int(k)
            if direction == 'first':
                indices = indices[:k]
            else:
                indices = indices[-k:]
        return indices
    return np.array([])

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
    # Skip any frames in this module (like unilab_call) to find the user workspace
    while frame and frame.f_globals.get('__name__') == __name__:
        frame = frame.f_back
    
    if not frame:
        # Fallback to f_back if we somehow lost the stack
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

def char(obj):
    return str(obj)

def magic(n):
    """Generates a magic square of order n."""
    n = int(n)
    if n < 3:
        if n == 1: return np.array([[1]])
        if n == 2: return np.array([[0,0],[0,0]]) # Not possible, return dummy
    
    # Odd order
    if n % 2 == 1:
        M = np.zeros((n, n), dtype=int)
        i, j = 0, n // 2
        for k in range(1, n*n + 1):
            M[i, j] = k
            next_i, next_j = (i - 1) % n, (j + 1) % n
            if M[next_i, next_j]:
                i = (i + 1) % n
            else:
                i, j = next_i, next_j
        return M
    
    # Even order (Simplified: only handled by returning zeros or using a library if available)
    # For now, return zeros for even n > 1 as it's more complex to implement
    return np.zeros((n, n), dtype=int)

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
    dir_map = {'both': '+-', 'left': '-', 'right': '+'}
    direction = dir_map.get(direction, direction)
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

def fprintf(*args):
    """
    MATLAB-compatible fprintf function.
    Supports file handles (1 for stdout, 2 for stderr) and standard formatting.
    """
    if not args: return
    fmt = args[0]
    import sys
    
    if isinstance(fmt, (int, float)):
        handle = int(fmt)
        if len(args) < 2: return
        fmt = args[1]
        args = args[2:]
        try:
            output = fmt % args if args else str(fmt)
        except:
            output = str(fmt)
        if handle == 2:
            sys.stderr.write(output)
            sys.stderr.flush()
        else:
            sys.stdout.write(output)
            sys.stdout.flush()
    else:
        args = args[1:]
        try:
            output = fmt % args if args else str(fmt)
        except:
            output = str(fmt)
        sys.stdout.write(output)
        sys.stdout.flush()

def clc():
    """Clear Command Window."""
    import os
    if os.environ.get('UNILAB_WEB_MODE') == '1':
        print('::CLEAR_TERMINAL::')
    else:
        os.system('cls' if os.name == 'nt' else 'clear')

def length(x):
    if hasattr(x, '__len__'):
        if isinstance(x, np.ndarray): return int(max(np.shape(x)) if x.size > 0 else 0)
        return len(x)
    return 1

def size(x, dim=None):
    try:
        s = np.shape(x)
    except:
        if isinstance(x, list):
            s = (len(x),)
        else:
            s = ()
            
    if len(s) == 0: s = (1, len(x)) if isinstance(x, (str, bytes, list)) else (1, 1)
    elif len(s) == 1: s = (1, s[0])
    
    if dim is not None: return s[dim-1] if dim <= len(s) else 1
    
    n = unilab_get_nargout()
    if n > 1:
        return tuple(s)
    return np.array([s]) if isinstance(s, tuple) else s

def numel(x):
    if isinstance(x, np.ndarray): return x.size
    if hasattr(x, '__len__'): return len(x)
    return 1

def reshape(x, *args):
    if len(args) == 1 and isinstance(args[0], (list, tuple, np.ndarray)):
        return np.reshape(x, args[0])
    return np.reshape(x, args)

def sum(x, axis=None):

    if axis is not None:

        # MATLAB is 1-based, NumPy is 0-based

        if isinstance(axis, (int, float)):

            axis = int(axis) - 1

    return np.sum(x, axis=axis)



def prod(x, axis=None):



    if axis is not None:



        if isinstance(axis, (int, float)):



            axis = int(axis) - 1



    return np.prod(x, axis=axis, dtype=np.float64)



def mean(x, axis=None):
    x_arr = np.asarray(x)
    if axis is None:
        # MATLAB-like behavior: mean along first non-singleton dimension
        if x_arr.ndim <= 1:
            return np.mean(x_arr)
        for i, d in enumerate(x_arr.shape):
            if d > 1:
                res = np.mean(x_arr, axis=i)
                # Keep orientation if it was a column vector or matrix
                if x_arr.ndim == 2 and i == 0:
                    return res.reshape(1, -1)
                return res
        return np.mean(x_arr)

    if isinstance(axis, (int, float)):
        axis = int(axis) - 1
    return np.mean(x_arr, axis=axis)


def min(*args, axis=None):
    if len(args) == 1:
        x_arr = np.asarray(args[0])
        if axis is None:
            if x_arr.ndim <= 1: axis = 0
            else:
                axis = 0
                for i, d in enumerate(x_arr.shape):
                    if d > 1: axis = i; break
        
        n = unilab_get_nargout()
        if n <= 1:
            res = np.min(x_arr, axis=axis)
            if x_arr.ndim == 2 and axis == 0: return res.reshape(1, -1)
            return res
        res = np.min(x_arr, axis=axis)
        idx = np.argmin(x_arr, axis=axis) + 1
        if x_arr.ndim == 2 and axis == 0:
            return res.reshape(1, -1), idx.reshape(1, -1)
        return res, idx
    return np.minimum(*args)

def max(*args, axis=None):
    if len(args) == 1:
        x_arr = np.asarray(args[0])
        if axis is None:
            if x_arr.ndim <= 1: axis = 0
            else:
                axis = 0
                for i, d in enumerate(x_arr.shape):
                    if d > 1: axis = i; break
        
        n = unilab_get_nargout()
        if n <= 1:
            res = np.max(x_arr, axis=axis)
            if x_arr.ndim == 2 and axis == 0: return res.reshape(1, -1)
            return res
        res = np.max(x_arr, axis=axis)
        idx = np.argmax(x_arr, axis=axis) + 1
        if x_arr.ndim == 2 and axis == 0:
            return res.reshape(1, -1), idx.reshape(1, -1)
        return res, idx
    return np.maximum(*args)

def sort(x, axis=None):
    if axis is None:
        if isinstance(x, np.ndarray) and x.ndim == 2: axis = 1 if x.shape[0] == 1 else 0
        else: axis = 0
    n = unilab_get_nargout()
    if n <= 1:
        return np.sort(x, axis=axis)
    return np.sort(x, axis=axis), np.argsort(x, axis=axis) + 1

def unique(x): return np.unique(x)
def inv(x): return np.linalg.inv(x)
def det(x): return np.linalg.det(x)
def eig(x):
    eigenvalues, eigenvectors = np.linalg.eig(x)
    return eigenvectors, np.diag(eigenvalues)
def svd(x):
    U, S, Vh = np.linalg.svd(x)
    return U, np.diag(S), Vh.T

def linspace(start, stop, n=100): return np.atleast_2d(np.linspace(start, stop, int(n)))
def logspace(start, stop, n=50): return np.atleast_2d(np.logspace(start, stop, int(n)))
def meshgrid(*args):
    """
    MATLAB-compatible meshgrid.
    Example:
        [X, Y] = meshgrid(x, y)
        [X, Y, Z] = meshgrid(x, y, z)
    """
    if not args:
        return []
    
    # Flatten vectors (1xN or Nx1) to 1D for numpy.meshgrid
    processed_args = [_unilab_vec(arg) for arg in args]
    
    if len(processed_args) == 1:
        # meshgrid(x) -> meshgrid(x, x)
        x = processed_args[0]
        return np.meshgrid(x, x)
    
    return np.meshgrid(*processed_args)
def randperm(n): return np.random.permutation(int(n)) + 1
def _is_symbolic(x):
    return hasattr(x, '__module__') and 'sympy' in x.__module__

def unilab_abs(*args):
    if not args: return 0.0
    x = args[0]
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

def tanh(x):
    """Hyperbolic tangent."""
    if _is_symbolic(x):
        import sympy
        return sympy.tanh(x)
    return np.tanh(x)

def atan(x):
    """Arctangent of argument in radians."""
    if _is_symbolic(x):
        import sympy
        return sympy.atan(x)
    return np.arctan(x)

def atan2(y, x):
    """Two-argument arctangent function. Returns angle in radians between -pi and pi."""
    if _is_symbolic(y) or _is_symbolic(x):
        import sympy
        return sympy.atan2(y, x)
    return np.arctan2(y, x)

def relu(x):
    """Rectified Linear Unit."""
    if _is_symbolic(x):
        import sympy
        return sympy.Max(0, x)
    return np.maximum(0, x)

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

def eye(n, m=None):
    if isinstance(n, (list, tuple, np.ndarray)):
        sz = np.asarray(n).flatten()
        if len(sz) >= 2:
            return np.eye(int(sz[0]), int(sz[1]))
        n = sz[0]
    return np.eye(int(n), int(m) if m is not None else int(n))
def zeros(*args): 
    if len(args) == 1 and isinstance(args[0], (list, tuple, np.ndarray)):
        shape = tuple(int(i) for i in np.asarray(args[0]).flatten())
        return np.zeros(shape)
    if not args: return np.zeros((1, 1))
    return np.zeros(tuple(int(i) for i in args))

def ones(*args): 
    if len(args) == 1 and isinstance(args[0], (list, tuple, np.ndarray)):
        shape = tuple(int(i) for i in np.asarray(args[0]).flatten())
        return np.ones(shape)
    if not args: return np.ones((1, 1))
    return np.ones(tuple(int(i) for i in args))
def median(x, axis=None): return np.median(x, axis=axis)
def quantile(x, q, axis=None): return np.percentile(x, q * 100, axis=axis)
def var(x, axis=None): return np.var(x, ddof=1, axis=axis)
def std(x, axis=None): return np.std(x, ddof=1, axis=axis)

class UnilabCVPartition:
    def __init__(self, n, method='HoldOut', p=0.3):
        self.n = n
        self.method = method
        self.p = p
        indices = np.random.permutation(n)
        if method.lower() == 'holdout':
            n_test = int(n * p)
            self.test_indices = indices[:n_test]
            self.train_indices = indices[n_test:]
        else:
            self.train_indices = indices
            self.test_indices = np.array([])

def cvpartition(n, method='HoldOut', p=0.3):
    return UnilabCVPartition(int(n), method, p)

def training(cv):
    mask = np.zeros(cv.n, dtype=bool)
    mask[cv.train_indices] = True
    return mask

def test(cv):
    mask = np.zeros(cv.n, dtype=bool)
    mask[cv.test_indices] = True
    return mask

def rng(seed=None, generator=None):
    """Control the random number generator."""
    if seed is not None:
        if isinstance(seed, (int, np.integer)):
            np.random.seed(int(seed))
        elif str(seed) == 'default':
            np.random.seed(0)
    return None

_tic_stack = []

def tic():
    """Start a stopwatch timer."""
    import time
    _tic_stack.append(time.time())

def toc():
    """Read the stopwatch timer."""
    import time
    if not _tic_stack:
        print("Error: toc called without a preceding tic.")
        return 0.0
    elapsed = time.time() - _tic_stack.pop()
    print(f"Elapsed time is {elapsed:.6f} seconds.")
    return elapsed

def rand(*args):
    if len(args) == 1 and isinstance(args[0], (list, tuple, np.ndarray)): 
        args = [int(a) for a in np.asarray(args[0]).flatten()]
        return np.random.rand(*args)
    args = [int(a) for a in args]
    return np.random.rand(*args) if args else np.random.rand()

def randn(*args):
    if len(args) == 1 and isinstance(args[0], (list, tuple, np.ndarray)):
        args = [int(a) for a in np.asarray(args[0]).flatten()]
        return np.random.randn(*args)
    args = [int(a) for a in args]
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
        if isinstance(precision, str) and '%' in precision:
            return precision % x
        try:
            return f"{x:.{precision}f}"
        except:
            return str(x)
    return str(x)

def mat2str(x):
    if isinstance(x, np.ndarray):
        return str(x).replace('\n', ';')
    return str(x)

def sprintf(fmt, *args):
    try:
        return fmt % args
    except:
        return str(fmt)

# High-impact styling with a Dark Professional Aesthetic (Module Level)
plt.rcParams.update({
    'axes.prop_cycle': plt.cycler(color=['#4fc3f7', '#81c784', '#ffb74d', '#f06292', '#ba68c8', '#a1887f']),
    'axes.linewidth': 1.5, 
    'axes.edgecolor': '#444444',
    'axes.facecolor': '#121212',
    'axes.labelcolor': '#e0e0e0',
    'axes.labelweight': 'bold',
    'axes.titleweight': 'bold',
    'figure.facecolor': '#121212',
    'grid.color': '#333333',
    'grid.linestyle': '--',
    'grid.linewidth': 0.8,
    'lines.linewidth': 4.0,
    'font.size': 16,
    'font.weight': 'bold',
    'text.color': '#e0e0e0',
    'xtick.color': '#b0b0b0',
    'ytick.color': '#b0b0b0',
    'xtick.labelsize': 16,
    'ytick.labelsize': 16,
    'legend.fontsize': 16,
    'legend.facecolor': '#1e1e1e',
    'legend.edgecolor': '#444444',
    'savefig.facecolor': '#121212',
    'savefig.edgecolor': '#121212',
    'figure.dpi': 120
})

# Figure versioning and plot counter for unique snapshots
_unilab_plot_counter = 0
_unilab_fig_versions = {}

def _unilab_update_fig_version(fig_num=None):
    """Increments the version counter for a figure, indicating a new plot instance."""
    global _unilab_fig_versions
    if fig_num is None:
        try: fig_num = plt.gcf().number
        except: fig_num = 1
    _unilab_fig_versions[fig_num] = _unilab_fig_versions.get(fig_num, 0) + 1
    return _unilab_fig_versions[fig_num]

def _unilab_refresh_graph():
    """Triggers a graph refresh by saving to a file and printing a marker."""
    global _unilab_plot_counter
    try:
        import json
        fig = plt.gcf()
        ax = plt.gca()
        if ax is None: return

        # Extract metadata for ASCII overlay (Internal use)
        meta = {
            "title": ax.get_title(),
            "xlabel": ax.get_xlabel(),
            "ylabel": ax.get_ylabel(),
            "xmin": float(ax.get_xlim()[0]),
            "xmax": float(ax.get_xlim()[1]),
            "ymin": float(ax.get_ylim()[0]),
            "ymax": float(ax.get_ylim()[1]),
            "is_3d": ax.name == '3d'
        }
        
        # Use a truly unique counter for each plot refresh to avoid collisions
        _unilab_plot_counter += 1
        plot_id = _unilab_plot_counter
        
        # Determine where to save based on session isolation (Context-safe)
        ws_path = unilab_workspace_ctx.get()
        prefix = pathlib.Path(ws_path).name.split('_')[-1][:6] + "_" if ws_path else ""
        
        # Add "3d" marker to filename if this is a 3D plot
        plot_type_marker = "3d_" if ax.name == '3d' else ""
        filename = f"graph_{plot_type_marker}{prefix}{plot_id}_{int(time.time())}.png"
        meta_filename = f"graph_{plot_type_marker}{prefix}{plot_id}_{int(time.time())}.json"
        
        save_path = pathlib.Path(ws_path) / filename if ws_path else pathlib.Path(filename)
        save_meta_path = pathlib.Path(ws_path) / meta_filename if ws_path else pathlib.Path(meta_filename)
        
        with open(str(save_meta_path), "w") as f:
            json.dump(meta, f)

        # Rendering Fixes for Headless/Web
        num_axes = len(fig.axes)
        if num_axes > 1:
            # Try to determine the grid from the axes positions
            rows, cols = 1, 1
            try:
                for ax_item in fig.axes:
                    if hasattr(ax_item, 'get_subplotspec'):
                        spec = ax_item.get_subplotspec()
                        if spec:
                            gs = spec.get_gridspec()
                            rows = max(rows, gs.nrows)
                            cols = max(cols, gs.ncols)
            except: 
                # Fallback to older heuristic if GridSpec fails
                rows = (num_axes // 2 + num_axes % 2)
                cols = 2 if num_axes >= 2 else 1
            
            # Divide the grid of the full width and place pictures on specific positions
            # Use 9 inches per column and 7 inches per row for very generous spacing
            fig.set_size_inches(max(14, 9 * cols), max(10, 7 * rows))
        else:
            # Make single plots smaller and more compact
            fig.set_size_inches(8, 5)

        fig.set_facecolor('#121212')
        fig.patch.set_facecolor('#121212')
        fig.patch.set_alpha(1.0)

        # Ensure legend is also dark if it exists
        for leg in fig.legends:
            leg.get_frame().set_facecolor('#1e1e1e')
            leg.get_frame().set_edgecolor('#444444')
            for text_item in leg.get_texts():
                text_item.set_color('#e0e0e0')

        for ax_item in fig.axes:
            ax_item.set_facecolor('#121212')
            ax_item.patch.set_facecolor('#121212')

        # Ensure the layout is tight so labels are not cut off
        try:
            has_3d = any(getattr(a, 'name', '') == '3d' for a in fig.axes)
            if not has_3d:
                # Use constrained_layout if available or tight_layout with adequate padding
                fig.tight_layout(pad=3.0)
            else:
                # For 3D plots, tight_layout can be finicky, use subplots_adjust
                fig.subplots_adjust(hspace=0.4, wspace=0.4, left=0.1, right=0.9, top=0.9, bottom=0.1)
        except Exception:
            try:
                fig.subplots_adjust(hspace=0.5, wspace=0.4)
            except: pass
        # Handle 3D pane colors for dark mode and save 3D data
        if ax.name == '3d':
            try:
                ax.xaxis.set_pane_color((0.07, 0.07, 0.07, 1.0))
                ax.yaxis.set_pane_color((0.07, 0.07, 0.07, 1.0))
                ax.zaxis.set_pane_color((0.07, 0.07, 0.07, 1.0))
                ax.xaxis._axinfo["grid"]['color'] = (0.2, 0.2, 0.2, 1.0)
                ax.yaxis._axinfo["grid"]['color'] = (0.2, 0.2, 0.2, 1.0)
            except: pass

        # Force artists to be rendered
        plt.draw()


        # Save with tight clipping to avoid cutting off labels/axes
        # We use a small padding to ensure edges are clean
        # We explicitly set facecolor and edgecolor to the dark theme to avoid white borders
        fig.savefig(
            str(save_path),
            format='png',
            dpi=120,
            facecolor='#121212',
            edgecolor='#121212',
            transparent=False,
            bbox_inches='tight',
            pad_inches=0.1
        )

        fig_num = fig.number
        fig_ver = _unilab_fig_versions.get(fig_num, 1)
        print(f"::GRAPHICAL_PLOT::{filename}::FIG::{fig_num}::VER::{fig_ver}")
    except Exception as e:
        print(f"Error saving graph: {e}")

_unilab_hold = False

def hold(state='on'):
    global _unilab_hold
    _unilab_hold = (state == 'on' or state == True or state == 1)

def clf():
    plt.clf()
    _unilab_update_fig_version()
    _unilab_refresh_graph()

def text(*args, **kwargs):
    """Adds text to the plot."""
    args_list = list(args)
    target_ax = plt
    if args_list and hasattr(args_list[0], 'text'):
        target_ax = args_list.pop(0)
    return target_ax.text(*args_list, **kwargs)

def plot(*args, **kwargs):
    """
    Plot vectors or matrices.
    Example:
        plot(x, y, 'LineWidth', 2);
    """
    args_list = list(args)
    target_ax = plt
    
    # Check if first arg is an axes object
    if args_list and hasattr(args_list[0], 'plot'):
        target_ax = args_list.pop(0)

    # MATLAB-style Name-Value pair extraction
    matlab_names = {
        'LineWidth': 'linewidth',
        'MarkerSize': 'markersize',
        'MarkerFaceColor': 'markerfacecolor',
        'MarkerEdgeColor': 'markeredgecolor',
        'Color': 'color',
        'LineStyle': 'linestyle',
        'Marker': 'marker',
        'DisplayName': 'label'
    }
    
    # Process Name-Value pairs from args_list
    i = 0
    while i < len(args_list) - 1:
        name = args_list[i]
        if isinstance(name, str) and (name in matlab_names or name.lower() == 'grid'):
            val = args_list[i+1]
            if name.lower() == 'grid':
                if hasattr(target_ax, 'grid'):
                    target_ax.grid(val == 'on' or val == True or val == 1)
            else:
                kwargs[matlab_names[name]] = val
            args_list.pop(i)
            args_list.pop(i)
            continue
        i += 1

    # Flatten vectors for Matplotlib compatibility
    args_list = [_unilab_vec(a) for a in args_list]

    if target_ax == plt and not _unilab_hold:
        plt.cla()
        _unilab_update_fig_version()
        
    res = target_ax.plot(*args_list, **kwargs)
    
    if target_ax == plt:
        _unilab_refresh_graph()
    elif hasattr(target_ax, 'figure'):
        target_ax.figure.canvas.draw()
        
    return res

def fill(*args, **kwargs):
    """
    Fill areas between curves.
    Example:
        fill(x, y, 'r');
        fill(ax, x, y, 'r');
    """
    args_list = list(args)
    target_ax = plt
    if args_list and hasattr(args_list[0], 'fill'):
        target_ax = args_list.pop(0)
    
    # MATLAB-style Name-Value pair extraction
    matlab_names = {'Alpha': 'alpha', 'FaceAlpha': 'alpha', 'FaceColor': 'facecolor', 'EdgeColor': 'edgecolor'}
    i = 0
    while i < len(args_list) - 1:
        name = args_list[i]
        if isinstance(name, str) and name in matlab_names:
            kwargs[matlab_names[name]] = args_list[i+1]
            args_list.pop(i); args_list.pop(i)
            continue
        i += 1

    # Flatten vectors
    args_list = [_unilab_vec(a) for a in args_list]
    
    if target_ax == plt and not _unilab_hold:
        plt.cla()
        _unilab_update_fig_version()

    res = target_ax.fill(*args_list, **kwargs)
    
    if target_ax == plt:
        _unilab_refresh_graph()
    elif hasattr(target_ax, 'figure'):
        target_ax.figure.canvas.draw()
    return res

def xlim(*args):
    args_list = list(args)
    target_ax = plt
    if args_list and hasattr(args_list[0], 'set_xlim'):
        target_ax = args_list.pop(0)
    
    if not args_list:
        return target_ax.get_xlim() if hasattr(target_ax, 'get_xlim') else plt.xlim()
    
    val = args_list[0]
    if isinstance(val, (list, np.ndarray)):
        val_arr = np.asarray(val).flatten()
        if len(val_arr) == 2:
            res = target_ax.set_xlim(val_arr[0], val_arr[1]) if hasattr(target_ax, 'set_xlim') else plt.xlim(val_arr[0], val_arr[1])
        else:
            res = target_ax.set_xlim(val_arr) if hasattr(target_ax, 'set_xlim') else plt.xlim(val_arr)
    elif len(args_list) == 2:
        res = target_ax.set_xlim(args_list[0], args_list[1]) if hasattr(target_ax, 'set_xlim') else plt.xlim(args_list[0], args_list[1])
    else:
        res = target_ax.set_xlim(val) if hasattr(target_ax, 'set_xlim') else plt.xlim(val)
        
    if target_ax == plt:
        _unilab_refresh_graph()
    elif hasattr(target_ax, 'figure'):
        target_ax.figure.canvas.draw()
    return res

def ylim(*args):
    args_list = list(args)
    target_ax = plt
    if args_list and hasattr(args_list[0], 'set_ylim'):
        target_ax = args_list.pop(0)
    
    if not args_list:
        return target_ax.get_ylim() if hasattr(target_ax, 'get_ylim') else plt.ylim()
    
    val = args_list[0]
    if isinstance(val, (list, np.ndarray)):
        val_arr = np.asarray(val).flatten()
        if len(val_arr) == 2:
            res = target_ax.set_ylim(val_arr[0], val_arr[1]) if hasattr(target_ax, 'set_ylim') else plt.ylim(val_arr[0], val_arr[1])
        else:
            res = target_ax.set_ylim(val_arr) if hasattr(target_ax, 'set_ylim') else plt.ylim(val_arr)
    elif len(args_list) == 2:
        res = target_ax.set_ylim(args_list[0], args_list[1]) if hasattr(target_ax, 'set_ylim') else plt.ylim(args_list[0], args_list[1])
    else:
        res = target_ax.set_ylim(val) if hasattr(target_ax, 'set_ylim') else plt.ylim(val)
        
    if target_ax == plt:
        _unilab_refresh_graph()
    elif hasattr(target_ax, 'figure'):
        target_ax.figure.canvas.draw()
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
                
                dx = unilab_abs(px - prev_px)
                dy = unilab_abs(py - prev_py)
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

def is_web():
    """Returns True if running in web mode."""
    return os.environ.get('UNILAB_WEB_MODE') == '1'

def terminal_plot_hd(y, x=None, height=None, width=None, type='line', **kwargs):
    """HD Terminal Plotting with High-Contrast Styling."""
    grid_state = kwargs.pop('grid', True)
    
    if x is None or (isinstance(x, (list, np.ndarray)) and len(x) == 0):
        if isinstance(y, (list, np.ndarray)):
            x = np.arange(len(y))
        else:
            x = np.arange(1)
            y = [y]
    
    # Ensure x and y are 1D for Matplotlib
    x = _unilab_vec(x)
    y = _unilab_vec(y)
            
    if not _unilab_hold:
        plt.clf()
        # Ensure we have a figure with the right size if it's the first plot
        if not plt.get_fignums():
            plt.figure(figsize=(10, 6))
        _unilab_update_fig_version()

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

def terminal_heatmap_hd(M):
    """HD Heatmap optimized for terminal grids."""
    plt.figure(figsize=(10, 6))
    plt.imshow(M, cmap='magma', interpolation='nearest')
    plt.colorbar()
    _unilab_refresh_graph()
    plt.close()

def _parse_matlab_style_args(args):
    MATLAB_PROPS = {
        'linecolor', 'linewidth', 'markerfacecolor', 'markeredgecolor',
        'markersize', 'displayname', 'location', 'name', 'position',
        'color', 'edgecolor', 'facecolor', 'marker', 'linestyle', 'alpha',
        'interpreter', 'fontweight', 'fontsize'
    }
    
    pos_args = []
    kwargs = {}
    i = 0
    while i < len(args):
        if i + 1 < len(args) and isinstance(args[i], str) and args[i].lower() in MATLAB_PROPS:
            key = args[i].lower()
            val = args[i+1]
            key_map = {
                'linecolor': 'edgecolor',
                'markerfacecolor': 'facecolor',
                'markeredgecolor': 'edgecolor',
                'displayname': 'label',
                'location': 'loc'
            }
            kwargs[key_map.get(key, key)] = val
            i += 2
        else:
            arg = args[i]
            # Automatically flatten vectors (1xN or Nx1) for Matplotlib compatibility
            if isinstance(arg, np.ndarray) and (arg.shape[0] == 1 or arg.shape[1] == 1):
                arg = _unilab_vec(arg)
            pos_args.append(arg)
            i += 1
    return pos_args, kwargs

def stem(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args)
    kwargs.update(p_kwargs)
    if not _unilab_hold: 
        plt.cla()
        _unilab_update_fig_version()
    res = plt.stem(*p_args, **kwargs); _unilab_refresh_graph(); return res

def stairs(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args)
    kwargs.update(p_kwargs)
    if not _unilab_hold: 
        plt.cla()
        _unilab_update_fig_version()
    res = plt.stairs(*p_args, **kwargs); _unilab_refresh_graph(); return res

def area(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args)
    kwargs.update(p_kwargs)
    if not _unilab_hold: 
        plt.cla()
        _unilab_update_fig_version()
    # area(y) or area(x, y)
    if len(p_args) == 1:
        y = p_args[0]
        x = np.arange(len(y))
        res = plt.fill_between(x, y, **kwargs)
    elif len(p_args) >= 2:
        x, y = p_args[0], p_args[1]
        res = plt.fill_between(x, y, **kwargs)
    _unilab_refresh_graph()
    return res

def scatter(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args)
    kwargs.update(p_kwargs)
    
    if not _unilab_hold: 
        plt.cla()
        _unilab_update_fig_version()
    
    # Matplotlib scatter is filled by default. Remove MATLAB flag.
    p_args = [a for a in p_args if not (isinstance(a, str) and a == 'filled')]
    
    # Map 'markersize' to 's'
    if 'markersize' in kwargs:
        kwargs['s'] = kwargs.pop('markersize')
            
    res = plt.scatter(*p_args, **kwargs); _unilab_refresh_graph(); return res

def bar(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args)
    kwargs.update(p_kwargs)
    if not _unilab_hold: 
        plt.cla()
        _unilab_update_fig_version()
    res = plt.bar(*p_args, **kwargs); _unilab_refresh_graph(); return res

def hist(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args)
    kwargs.update(p_kwargs)
    if not _unilab_hold: 
        plt.cla()
        _unilab_update_fig_version()
    res = plt.hist(*p_args, **kwargs); _unilab_refresh_graph(); return res

def title(*args, **kwargs):
    args_list = list(args)
    target = plt
    if args_list and hasattr(args_list[0], 'set_title'):
        target = args_list.pop(0)
        res = target.set_title(*args_list, **kwargs)
        if hasattr(target, 'figure'): target.figure.canvas.draw()
        return res
    res = plt.title(*args_list, **kwargs)
    _unilab_refresh_graph()
    return res

def xlabel(*args, **kwargs):
    args_list = list(args)
    target = plt
    if args_list and hasattr(args_list[0], 'set_xlabel'):
        target = args_list.pop(0)
        res = target.set_xlabel(*args_list, **kwargs)
        if hasattr(target, 'figure'): target.figure.canvas.draw()
        return res
    res = plt.xlabel(*args_list, **kwargs)
    _unilab_refresh_graph()
    return res

def ylabel(*args, **kwargs):
    args_list = list(args)
    target = plt
    if args_list and hasattr(args_list[0], 'set_ylabel'):
        target = args_list.pop(0)
        res = target.set_ylabel(*args_list, **kwargs)
        if hasattr(target, 'figure'): target.figure.canvas.draw()
        return res
    res = plt.ylabel(*args_list, **kwargs)
    _unilab_refresh_graph()
    return res

def gca(): return plt.gca()

def figure(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args)
    kwargs.update(p_kwargs)
    # Map some figure properties
    if 'name' in kwargs: kwargs.pop('name')
    if 'position' in kwargs: kwargs.pop('position')
    return plt.figure(**kwargs)

def subplot(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args)
    kwargs.update(p_kwargs)
    res = plt.subplot(*p_args, **kwargs)
    _unilab_refresh_graph()
    return res

def hold(*args):
    global _unilab_hold
    args_list = list(args)
    if args_list and hasattr(args_list[0], 'plot'):
        # First arg is likely an axes object, ignore it for now as UniLab 
        # uses a global hold state for the current figure.
        args_list.pop(0)
    
    state = args_list[0] if args_list else 'on'
    val = str(state).lower()
    _unilab_hold = (val == 'on' or val == '1' or state is True)

def grid(*args, **kwargs):
    args_list = list(args)
    target = plt
    if args_list and hasattr(args_list[0], 'grid'):
        target = args_list.pop(0)
    
    state = args_list[0] if args_list else 'on'
    val = str(state).lower()
    visible = val == 'on' or val == '1' or state is True
    
    if target == plt:
        plt.grid(visible, **kwargs)
    else:
        target.grid(visible, **kwargs)
        if hasattr(target, 'figure'): target.figure.canvas.draw()
    _unilab_refresh_graph()

def axis(*args):
    args_list = list(args)
    target = plt
    if args_list and hasattr(args_list[0], 'axis'):
        target = args_list.pop(0)
    
    if args_list:
        res = target.axis(args_list[0])
    else:
        res = target.axis()
        
    _unilab_refresh_graph()
    return res

def legend(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args)
    kwargs.update(p_kwargs)
    
    # If all positional arguments are strings, they are labels for the current plot.
    # Matplotlib's legend expects a list of labels in this case.
    if p_args and all(isinstance(a, str) for a in p_args):
        p_args = [p_args]
        
    plt.legend(*p_args, **kwargs); _unilab_refresh_graph()

def contourf(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args)
    kwargs.update(p_kwargs)
    if not _unilab_hold: 
        plt.cla()
        _unilab_update_fig_version()
    # MATLAB often passes levels as a 1xN matrix, Matplotlib wants 1D
    if len(p_args) >= 4 and isinstance(p_args[3], np.ndarray):
        p_args[3] = p_args[3].flatten()
    res = plt.contourf(*p_args, **kwargs); _unilab_refresh_graph(); return res


def colormap(*args):
    """Sets the colormap."""
    args_list = list(args)
    target_ax = None
    
    if args_list and hasattr(args_list[0], 'imshow'):
        target_ax = args_list.pop(0)
    
    if not args_list:
        return
        
    cmap = args_list[0]
    
    if isinstance(cmap, np.ndarray):
        from matplotlib.colors import ListedColormap
        import matplotlib as mpl
        cmap_obj = ListedColormap(cmap, name='unilab_custom')
        try:
            mpl.colormaps.register(cmap_obj, force=True)
        except:
            plt.register_cmap(name='unilab_custom', cmap=cmap_obj)
        cmap_name = 'unilab_custom'
    else:
        cmap_name = str(cmap)
        maps = {'bone': 'bone', 'jet': 'jet', 'hot': 'hot', 'cool': 'cool', 'spring': 'spring', 'summer': 'summer'}
        cmap_name = maps.get(cmap_name.lower(), cmap_name)
    
    if target_ax is None:
        plt.set_cmap(cmap_name)
        _unilab_refresh_graph()
    else:
        images = target_ax.get_images()
        if images:
            for img in images:
                img.set_cmap(cmap_name)
        if hasattr(target_ax, 'figure'):
            target_ax.figure.canvas.draw()

def _scatter_plot(x, y, t=None):
    if not _unilab_hold: 
        plt.cla()
        _unilab_update_fig_version()
    plt.scatter(x, y, s=100, alpha=0.6)
    if t: plt.title(t, fontweight='bold', fontsize=22)
    _unilab_refresh_graph()

def _hist_plot(data, bins=10, t=None):
    if not _unilab_hold: 
        plt.cla()
        _unilab_update_fig_version()
    plt.hist(data, bins=bins, alpha=0.7, edgecolor='white')
    if t: plt.title(t, fontweight='bold', fontsize=22)
    _unilab_refresh_graph()

def heatmap(M):
    if not _unilab_hold: 
        plt.cla()
        _unilab_update_fig_version()
    plt.imshow(M, interpolation='nearest')
    plt.colorbar()
    _unilab_refresh_graph()

def imagesc(*args, **kwargs):
    """Displays image with scaled colors."""
    args_list = list(args)
    target = plt
    if args_list and hasattr(args_list[0], 'imshow'):
        target = args_list.pop(0)
    
    if target == plt and not _unilab_hold:
        plt.cla()
        _unilab_update_fig_version()

    # Heuristic for transpose if needed
    if len(args_list) > 0 and isinstance(args_list[0], np.ndarray):
        M = args_list[0]
        # In MATLAB imagesc(data) uses (row, col) which maps to (y, x)
        res = target.imshow(M, interpolation='nearest', aspect='auto', **kwargs)
    else:
        res = target.imshow(*args_list, **kwargs)
        
    if target == plt:
        _unilab_refresh_graph()
    elif hasattr(target, 'figure'):
        target.figure.canvas.draw()
    return res

def colormap(*args):
    """Sets the colormap."""
    args_list = list(args)
    target_ax = None
    
    # Correctly identify if the first argument is an axes object
    if args_list and hasattr(args_list[0], 'imshow'):
        target_ax = args_list.pop(0)
    
    if not args_list:
        return
        
    cmap_name = str(args_list[0])
    # Map MATLAB names to matplotlib names
    maps = {'bone': 'bone', 'jet': 'jet', 'hot': 'hot', 'cool': 'cool', 'spring': 'spring', 'summer': 'summer'}
    cmap_name = maps.get(cmap_name.lower(), cmap_name)
    
    if target_ax is None:
        plt.set_cmap(cmap_name)
        _unilab_refresh_graph()
    else:
        # Directly set on axes images to avoid pyplot sca() error
        images = target_ax.get_images()
        if images:
            for img in images:
                img.set_cmap(cmap_name)
        else:
            # Fallback: setting current axes might still fail if not in pyplot, 
            # but we can try setting the attribute if matplotlib allows it
            pass
        if hasattr(target_ax, 'figure'):
            target_ax.figure.canvas.draw()

def plot3(*args, **kwargs):
    """Plot lines and points in 3D."""
    if not _unilab_hold: plt.cla()
    from mpl_toolkits.mplot3d import Axes3D
    fig = plt.gcf()

    # Ensure 3D axes
    if not fig.axes or fig.gca().name != '3d':
        ax = fig.add_subplot(111, projection='3d')
    else:
        ax = fig.gca()

    # Flatten vectors for Matplotlib compatibility
    args = [_unilab_vec(a) if isinstance(a, np.ndarray) and (a.shape[0] == 1 or a.shape[1] == 1) else a for a in args]

    res = ax.plot(*args, **kwargs)

    try:
        _unilab_3d_data_store[fig.number] = {
            'type': 'scatter3d',
            'x': np.asarray(args[0]).tolist() if len(args) > 0 else [],
            'y': np.asarray(args[1]).tolist() if len(args) > 1 else [],
            'z': np.asarray(args[2]).tolist() if len(args) > 2 else [],
        }
    except Exception:
        pass

    _unilab_refresh_graph()
    return res

def colorbar(*args, **kwargs):
    if not args:
        # Try to find a mappable in current axes
        ax = plt.gca()
        mappable = None
        # Check for collections (like Poly3DCollection from surf)
        if hasattr(ax, 'collections') and ax.collections:
            mappable = ax.collections[-1]
        # Check for images (like from imshow)
        elif hasattr(ax, 'images') and ax.images:
            mappable = ax.images[-1]
        
        if mappable:
            res = plt.colorbar(mappable, **kwargs)
        else:
            res = plt.colorbar(**kwargs)
    else:
        res = plt.colorbar(*args, **kwargs)
    _unilab_refresh_graph()
    return res

def surf(*args, **kwargs):
    """Create a 3D surface plot."""
    if not _unilab_hold: 
        plt.cla()
        _unilab_update_fig_version()
    from mpl_toolkits.mplot3d import Axes3D
    fig = plt.gcf()
    
    # Ensure 3D axes
    if not fig.axes or fig.gca().name != '3d':
        ax = fig.add_subplot(111, projection='3d')
    else:
        ax = fig.gca()
    
    # Handle peaks(N) returning (X, Y, Z) tuple
    if len(args) == 1 and isinstance(args[0], (tuple, list)) and len(args[0]) == 3:
        args = args[0]

    # Flatten vectors
    args = [_unilab_vec(a) if isinstance(a, np.ndarray) and (a.shape[0] == 1 or a.shape[1] == 1) else a for a in args]
    
    X_out, Y_out, Z_out = None, None, None
    if len(args) == 1:
        Z = np.asarray(args[0])
        if Z.ndim == 1:
             # Just a line? or reshape?
             Z = Z.reshape(1, -1)
        rows, cols = Z.shape
        X, Y = np.meshgrid(np.arange(cols), np.arange(rows))
        X_out, Y_out, Z_out = X, Y, Z
        if 'cmap' not in kwargs: kwargs['cmap'] = 'viridis'
        res = ax.plot_surface(X, Y, Z, **kwargs)
    elif len(args) == 3:
        X, Y, Z = args
        # MATLAB supports surf(x, y, Z) where x and y are vectors
        if X.ndim == 1 and Y.ndim == 1:
            X, Y = np.meshgrid(X, Y)
        X_out, Y_out, Z_out = X, Y, Z
        if 'cmap' not in kwargs: kwargs['cmap'] = 'viridis'
        res = ax.plot_surface(X, Y, Z, **kwargs)
    else:
        res = ax.plot_surface(*args, **kwargs)

    try:
        if X_out is not None and Y_out is not None and Z_out is not None:
            _unilab_3d_data_store[fig.number] = {
                'type': 'surface',
                'x': np.asarray(X_out).tolist(),
                'y': np.asarray(Y_out).tolist(),
                'z': np.asarray(Z_out).tolist(),
            }
    except Exception:
        pass

    _unilab_refresh_graph()
    return res

def mesh(*args, **kwargs):
    """Create a 3D wireframe mesh plot."""
    if not _unilab_hold: 
        plt.cla()
        _unilab_update_fig_version()
    from mpl_toolkits.mplot3d import Axes3D
    fig = plt.gcf()
    
    # Ensure 3D axes
    if not fig.axes or fig.gca().name != '3d':
        ax = fig.add_subplot(111, projection='3d')
    else:
        ax = fig.gca()
    
    # Flatten vectors
    args = [_unilab_vec(a) if isinstance(a, np.ndarray) and (a.shape[0] == 1 or a.shape[1] == 1) else a for a in args]

    X_out, Y_out, Z_out = None, None, None
    if len(args) == 1:
        Z = np.asarray(args[0])
        rows, cols = Z.shape
        X, Y = np.meshgrid(np.arange(cols), np.arange(rows))
        X_out, Y_out, Z_out = X, Y, Z
        res = ax.plot_wireframe(X, Y, Z, **kwargs)
    elif len(args) == 3:
        X, Y, Z = args
        if X.ndim == 1 and Y.ndim == 1:
            X, Y = np.meshgrid(X, Y)
        X_out, Y_out, Z_out = X, Y, Z
        res = ax.plot_wireframe(X, Y, Z, **kwargs)
    else:
        res = ax.plot_wireframe(*args, **kwargs)

    try:
        if X_out is not None and Y_out is not None and Z_out is not None:
            _unilab_3d_data_store[fig.number] = {
                'type': 'wireframe',
                'x': np.asarray(X_out).tolist(),
                'y': np.asarray(Y_out).tolist(),
                'z': np.asarray(Z_out).tolist(),
            }
    except Exception:
        pass

    _unilab_refresh_graph()
    return res

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
        meta_path = os.path.splitext(img_path)[0] + ".json"
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
        
        # ASCII density ramp - more detailed
        ramp = " .'`^,:;Il!i><~+_-?][}{1)(|\\/tfjrxnuvczMW&8%B@$"
        ramp_len = len(ramp)

        grid_data = []
        for y in range(target_h):
            row = ""
            for x in range(target_w):
                r, g, b = pixels[x, y]
                # Calculate luminance for character selection
                luma = 0.299*r + 0.587*g + 0.114*b
                
                # If it's very dark (theme background), treat as empty
                if luma < 25:
                    row += " "
                    continue
                    
                idx = int(luma * (ramp_len - 1) / 255)
                idx = max(0, min(idx, ramp_len - 1))
                char = ramp[idx]
                
                # Apply TrueColor to the character
                row += f"\x1b[38;2;{r};{g};{b}m{char}\x1b[0m"
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
    """Clears all variables from the workspace except protected ones."""
    import types
    keys_to_keep = {'np', 'plt', 'os', 'signal', 'fft', 'ifft', '__builtins__', 'addpath'}
    
    # Protect everything from this runtime module
    import backend.core.runtime as rt
    for name in dir(rt):
        if not name.startswith('_'): keys_to_keep.add(name)
        
    # Also protect any modules (libraries like ml, stats)
    modules_to_keep = [k for k, v in g.items() if isinstance(v, types.ModuleType)]
    keys_to_keep.update(modules_to_keep)
    
    to_remove = [k for k in g if k not in keys_to_keep and not k.startswith('__')]
    for k in to_remove: del g[k]

def unilab_clear_variables(g, names):
    """Clears specific variables from the workspace."""
    for name in names:
        if name in g:
            del g[name]

def unilab_iter(x):
    """Iterates over a UniLab object (columns for 2D arrays)."""
    if isinstance(x, np.ndarray):
        # Handle 0-d arrays by converting to a single-element list
        if x.ndim == 0:
            return iter([x.item()])
        if x.ndim == 1:
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

def error(msg):
    raise RuntimeError(str(msg))

def warning(msg):
    print(f"Warning: {msg}")

def unilab_not(x): return np.logical_not(x)
def unilab_xor(a, b): return np.logical_xor(a, b)
