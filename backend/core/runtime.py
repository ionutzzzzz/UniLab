import os
import time
import pathlib
import builtins
import inspect
import math
import re
import sys
import warnings

# Ensure sys.path does not contain virtualenv site-packages for a different Python major.minor version,
# and ensure the local workspace venv (matching the current Python version) is on sys.path.
def _sanitize_and_configure_sys_path():
    expected_py = f"python{sys.version_info.major}.{sys.version_info.minor}"
    py_dir_pattern = re.compile(r"[/\\]lib[/\\](python\d+\.\d+)[/\\]site-packages")
    cleaned = []
    for entry in sys.path:
        m = py_dir_pattern.search(entry)
        if m and m.group(1) != expected_py:
            continue
        cleaned.append(entry)
    sys.path[:] = cleaned

    here = pathlib.Path(__file__).resolve()
    for ancestor in list(here.parents)[:5]:
        for venv_name in ("venv", ".venv"):
            candidate = ancestor / venv_name / "lib" / expected_py / "site-packages"
            if candidate.is_dir():
                c_str = str(candidate)
                if c_str not in sys.path:
                    sys.path.insert(0, c_str)

_sanitize_and_configure_sys_path()

try:
    import numpy as np
except ImportError:
    np = None

try:
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from matplotlib.figure import Figure
except ImportError:
    plt = None
    Figure = None

# Suppress harmless Matplotlib warning when clearing figures with log-scaled axes
warnings.filterwarnings("ignore", category=UserWarning, message=".*non-positive xlim.*")


IS_HEADLESS = sys.platform.startswith('linux') and not os.environ.get('DISPLAY')

try:
    import scipy.signal as signal
    from scipy.fft import fft as scipy_fft, ifft as scipy_ifft, fftshift as scipy_fftshift, ifftshift as scipy_ifftshift
except ImportError:
    signal = None
    scipy_fft = scipy_ifft = scipy_fftshift = scipy_ifftshift = None

from contextvars import ContextVar
# Delay simulation import to avoid circular dependency and handle missing PyQt
def simulate(*args, **kwargs):
    try:
        from backend.core.simulation.engine import unilab_simulate
        return unilab_simulate(*args, **kwargs)
    except ImportError:
        print("Simulation engine unavailable (missing dependencies)")
        return None

from backend.core.models import safe_resolve_in_workspace, sanitize_for_json

# ContextVar for thread-safe session workspace path and CWD
unilab_workspace_ctx = ContextVar('unilab_workspace', default=None)
unilab_cwd_ctx = ContextVar('unilab_cwd', default=None)
unilab_restricted_ctx = ContextVar('unilab_restricted', default=False)
# ContextVar for engine update callback
unilab_update_ctx = ContextVar('unilab_update_callback', default=None)
unilab_event_ctx = ContextVar('unilab_event_callback', default=None)
# ContextVar for the current script path
unilab_script_ctx = ContextVar('unilab_script', default=None)
# Session-isolated state ContextVars
_unilab_tic_ctx = ContextVar('unilab_tic_stack', default=None)
_unilab_fid_ctx = ContextVar('unilab_fid_state', default=None)
_unilab_hold_ctx = ContextVar('unilab_hold', default=None)
_unilab_3d_ctx = ContextVar('unilab_3d_store', default=None)

# Fallback module-level store when outside session context
_unilab_3d_data_store = {}


def _get_3d_store() -> dict:
    store = _unilab_3d_ctx.get()
    return store if store is not None else _unilab_3d_data_store


def _get_hold_state() -> bool:
    h = _unilab_hold_ctx.get()
    if isinstance(h, dict):
        return bool(h.get("hold", False))
    if h is not None:
        return bool(h)
    return bool(_unilab_hold)


def _set_hold_state(val: bool) -> None:
    global _unilab_hold
    h = _unilab_hold_ctx.get()
    if isinstance(h, dict):
        h["hold"] = bool(val)
    else:
        _unilab_hold = bool(val)


def _get_tic_stack() -> list:
    st = _unilab_tic_ctx.get()
    return st if st is not None else _tic_stack


def _get_fid_state() -> dict:
    st = _unilab_fid_ctx.get()
    if st is not None:
        return st
    return _unilab_default_fid_state


def _resolve_runtime_path(user_path: str | pathlib.Path) -> pathlib.Path:
    """Resolve file paths against session CWD/workspace, enforcing workspace sandbox when restricted."""
    ws_root = unilab_workspace_ctx.get()
    cwd = unilab_cwd_ctx.get()
    base_dir = pathlib.Path(cwd) if cwd else (pathlib.Path(ws_root) if ws_root else pathlib.Path.cwd())
    p = pathlib.Path(str(user_path))
    candidate = p if p.is_absolute() else (base_dir / p)
    restricted = bool(unilab_restricted_ctx.get()) or os.environ.get("UNILAB_API_SERVER") == "1"
    if restricted and ws_root is not None:
        return safe_resolve_in_workspace(pathlib.Path(ws_root), candidate)
    return candidate.resolve()

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

def unilab_tf(num=None, den=None): 
    # Handle tf() or tf([], [])
    if num is None or (hasattr(num, '__len__') and len(num) == 0):
        if den is None or (hasattr(den, '__len__') and len(den) == 0):
            # Return a default or raise a better error
            raise ValueError("Error in 'tf': Missing numerator coefficients.")
        num = [1]
        
    if den is None or (hasattr(den, '__len__') and len(den) == 0):
        if isinstance(num, signal.lti): return num.to_tf()
        return signal.TransferFunction(_unilab_vec(num), [1])
        
    return signal.TransferFunction(_unilab_vec(num), _unilab_vec(den))

# --- Standard UniLab Constants ---
class UnilabCallableConstant:
    def __init__(self, val, dtype=None):
        self.val = val
        self.dtype = dtype
    def __call__(self, *args, **kwargs):
        if not args: return self.val
        if len(args) == 1:
            if isinstance(args[0], (list, tuple, np.ndarray)):
                shape = tuple(int(i) for i in np.asarray(args[0]).flatten())
            else:
                n = int(args[0])
                shape = (n, n)
        else:
            shape = tuple(int(i) for i in args)
        return np.full(shape, self.val, dtype=self.dtype or type(self.val))
    def __getitem__(self, idx):
        if isinstance(idx, tuple):
            return self(*idx)
        return self(idx)
    def __repr__(self): return str(self.val).lower()
    def __str__(self): return str(self.val).lower()
    def __float__(self): return float(self.val)
    def __int__(self): return int(self.val)
    def __bool__(self): return bool(self.val)
    def __add__(self, other): return self.val + other
    def __radd__(self, other): return other + self.val
    def __sub__(self, other): return self.val - other
    def __rsub__(self, other): return other - self.val
    def __mul__(self, other): return self.val * other
    def __rmul__(self, other): return other * self.val
    def __truediv__(self, other): return self.val / other
    def __rtruediv__(self, other): return other / self.val
    def __pow__(self, other): return self.val ** other
    def __rpow__(self, other): return other ** self.val
    def __eq__(self, other): return self.val == other
    def __ne__(self, other): return self.val != other
    def __lt__(self, other): return self.val < other
    def __le__(self, other): return self.val <= other
    def __gt__(self, other): return self.val > other
    def __ge__(self, other): return self.val >= other
    def __neg__(self): return -self.val

def kron(a, b):
    return np.kron(a, b)

inf = UnilabCallableConstant(np.inf)
Inf = inf
nan = UnilabCallableConstant(np.nan)
NaN = nan
pi = UnilabCallableConstant(np.pi)
def eps(*args):
    if not args: return np.finfo(float).eps
    x = args[0]
    if isinstance(x, (np.ndarray, list)):
        return np.spacing(np.asarray(x, dtype=np.float64))
    return np.spacing(float(x))
i = 1j
j = 1j
realmax = np.finfo(float).max
realmin = np.finfo(float).tiny
true = UnilabCallableConstant(True, dtype=bool)
false = UnilabCallableConstant(False, dtype=bool)

def unilab_tf2ss(num, den):
    return signal.tf2ss(_unilab_vec(num), _unilab_vec(den))

def unilab_ss2tf(A, B, C, D, iu=0):
    return signal.ss2tf(A, B, C, D, input=iu)

def unilab_ss(A, B, C, D=None): 
    if B is None:
        if isinstance(A, signal.lti): return A.to_ss()
        return signal.StateSpace(A)
    if D is None: D = np.zeros((np.atleast_2d(C).shape[0], np.atleast_2d(B).shape[1]))
    return signal.StateSpace(A, B, C, D)

def unilab_ssdata(sys):
    if not isinstance(sys, signal.StateSpace):
        sys = sys.to_ss()
    return sys.A, sys.B, sys.C, sys.D

def unilab_tfdata(sys):
    if not isinstance(sys, signal.TransferFunction):
        sys = sys.to_tf()
    # MATLAB tfdata returns cell arrays for num/den
    return [sys.num], [sys.den]

def unilab_zpkdata(sys):
    if not isinstance(sys, signal.ZerosPolesGain):
        sys = sys.to_zpk()
    return [sys.zeros], [sys.poles], sys.gain

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

def unilab_dcgain(sys):
    if isinstance(sys, signal.StateSpace):
        # DC gain = D - C * inv(A) * B
        return sys.D - sys.C @ np.linalg.inv(sys.A) @ sys.B
    elif isinstance(sys, signal.TransferFunction):
        return sys.num[-1] / sys.den[-1] if sys.den[-1] != 0 else np.inf
    else:
        return sys.gain * np.prod(-sys.zeros) / np.prod(-sys.poles) if np.all(sys.poles != 0) else np.inf

def unilab_pole(sys):
    return sys.poles

def unilab_zero(sys):
    return sys.zeros

def _extract_lti_and_plot_opts(args, kwargs):
    """Helper to extract LTI system(s), optional numeric vector (T or w), LineSpec, and MATLAB Name-Value kwargs."""
    p_args, p_kwargs = _parse_matlab_style_args(args)
    merged_kwargs = dict(p_kwargs)
    merged_kwargs.update(kwargs)

    systems = []
    num_vec = None
    line_specs = {}

    # Check if first two arguments are raw (num, den) vectors representing a transfer function: e.g. step([1], [1, 2, 1])
    remaining_args = list(p_args)
    if (len(remaining_args) >= 2 and
        not hasattr(remaining_args[0], 'poles') and not isinstance(remaining_args[0], (signal.lti, signal.dlti)) and
        not hasattr(remaining_args[1], 'poles') and not isinstance(remaining_args[1], (signal.lti, signal.dlti))):
        try:
            arr0 = np.asarray(remaining_args[0])
            arr1 = np.asarray(remaining_args[1])
            if (arr0.ndim <= 2 and arr1.ndim <= 1 and
                np.issubdtype(arr0.dtype, np.number) and np.issubdtype(arr1.dtype, np.number)):
                sys_conv = signal.TransferFunction(arr0, arr1)
                systems.append(sys_conv)
                remaining_args = remaining_args[2:]
        except Exception:
            pass

    for idx, item in enumerate(remaining_args):
        if hasattr(item, 'poles') or isinstance(item, (signal.lti, signal.dlti)):
            systems.append(item)
        elif isinstance(item, str):
            # Attach LineSpec to the most recent system
            sys_idx = max(0, len(systems) - 1)
            line_specs[sys_idx] = item
        elif item is not None:
            arr = np.asarray(item)
            if arr.size > 0 and np.issubdtype(arr.dtype, np.number):
                num_vec = item

    return systems, num_vec, line_specs, merged_kwargs


def _apply_control_axes_style(ax, title_str=None, xlabel_str=None, ylabel_str=None, extra_opts=None):
    """Applies active plot configuration (grid, fonts, labels, colors) to a control/signal Axes."""
    cfg = _unilab_plot_config
    fs = float((extra_opts or {}).get('fontsize', cfg['font_size']))
    show_lbl = cfg.get('show_labels', True)
    show_grd = (extra_opts or {}).get('grid', cfg.get('show_grid', True))

    if title_str is not None:
        t_txt = (extra_opts or {}).get('title', title_str)
        ax.set_title(t_txt if show_lbl else '', fontsize=fs + 1.5, fontweight='600', color=cfg['fg_color'], pad=8)
    if xlabel_str is not None:
        x_txt = (extra_opts or {}).get('xlabel', xlabel_str)
        ax.set_xlabel(x_txt if show_lbl else '', fontsize=fs, fontweight='500', color=cfg['fg_color'])
    if ylabel_str is not None:
        y_txt = (extra_opts or {}).get('ylabel', ylabel_str)
        ax.set_ylabel(y_txt if show_lbl else '', fontsize=fs, fontweight='500', color=cfg['fg_color'])

    ax.tick_params(axis='both', which='major', labelsize=max(7.0, fs - 1.0), colors=cfg['muted_fg_color'])
    if show_grd:
        ax.grid(True, which='both', linestyle='--', alpha=0.4, color=cfg['grid_color'], linewidth=0.75)
    else:
        ax.grid(False)


def unilab_pzmap(sys, *args, **kwargs):
    systems, _, line_specs, p_kwargs = _extract_lti_and_plot_opts((sys,) + args, kwargs)
    if not systems:
        systems = [sys]
    extra_opts = _extract_extra_axes_opts(p_kwargs)

    cfg = _unilab_plot_config
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()

    ms = float(p_kwargs.pop('markersize', max(7.5, cfg['marker_size'] + 1.5)))
    mew = float(p_kwargs.pop('linewidth', max(1.6, cfg['line_width'])))
    palette = _get_active_color_cycle()

    p_out, z_out = np.array([]), np.array([])
    for idx, s_item in enumerate(systems):
        p = np.asarray(s_item.poles)
        z = np.asarray(s_item.zeros)
        if idx == 0:
            p_out, z_out = p, z
        col_p = p_kwargs.get('color', '#f7768e' if idx == 0 else palette[idx % len(palette)])
        col_z = p_kwargs.get('color', '#7aa2f7' if idx == 0 else palette[(idx + 1) % len(palette)])
        lbl_suffix = f" ({idx+1})" if len(systems) > 1 else ""
        if len(p) > 0:
            ax.plot(np.real(p), np.imag(p), 'x', color=col_p, markersize=ms, markeredgewidth=mew, label=f'Poles{lbl_suffix}')
        if len(z) > 0:
            ax.plot(np.real(z), np.imag(z), 'o', color=col_z, markersize=ms - 0.5, markeredgewidth=mew, markerfacecolor='none', label=f'Zeros{lbl_suffix}')

    ax.axhline(0, color=cfg['spine_color'], lw=1.0, zorder=1)
    ax.axvline(0, color=cfg['spine_color'], lw=1.0, zorder=1)
    _apply_control_axes_style(ax, 'Pole-Zero Map', 'Real Axis (seconds⁻¹)', 'Imaginary Axis (seconds⁻¹)', extra_opts)
    if ax.get_legend_handles_labels()[0]:
        ax.legend(loc='best', fontsize=max(7.5, cfg['font_size'] - 1.0), framealpha=0.85)
    _unilab_refresh_graph()
    return p_out, z_out


def pzmap(sys, *args, **kwargs):
    return unilab_pzmap(sys, *args, **kwargs)


def unilab_damp(sys):
    p = sys.poles
    wn = np.abs(p)
    zeta = np.where(wn > 0, -np.real(p) / wn, 0.0)
    print(f"{'Pole':^25} {'Damping':^15} {'Frequency':^15}")
    print("-" * 55)
    for i in range(len(p)):
        print(f"{str(p[i]):^25} {zeta[i]:^15.4f} {wn[i]:^15.4f}")
    return wn, zeta, p


def unilab_c2d(sys, dt, method='zoh'):
    m = str(method).lower()
    scipy_method = 'bilinear' if m == 'tustin' else m
    dt_f = float(dt)
    if hasattr(sys, 'to_discrete'):
        return sys.to_discrete(dt_f, method=scipy_method)
    if isinstance(sys, (tuple, list)):
        res = signal.cont2discrete(sys, dt_f, method=scipy_method)
        if len(res) == 5:
            return signal.StateSpace(res[0], res[1], res[2], res[3], dt=res[4])
        return signal.TransferFunction(res[0], res[1], dt=res[2])
    return signal.cont2discrete(sys, dt_f, method=scipy_method)


def unilab_ctrb(A, B):
    n = A.shape[0]
    return np.hstack([np.linalg.matrix_power(A, i) @ B for i in range(n)])


def unilab_obsv(A, C):
    n = A.shape[0]
    return np.vstack([C @ np.linalg.matrix_power(A, i) for i in range(n)])


def unilab_rlocus(sys, k=None, *args, **kwargs):
    _, k_vec, _, p_kwargs = _extract_lti_and_plot_opts((sys, k) + args if k is not None else (sys,) + args, kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)

    s = sys if isinstance(sys, signal.TransferFunction) else sys.to_tf()
    num = np.asarray(s.num, dtype=float).flatten()
    den = np.asarray(s.den, dtype=float).flatten()

    if k_vec is not None and np.asarray(k_vec).size > 0:
        gains = np.asarray(k_vec, dtype=float).flatten()
    else:
        gains = np.concatenate(([0.0], np.logspace(-2, 2.5, 400)))

    all_roots = []
    for g_val in gains:
        poly_num = g_val * num
        max_len = builtins.max(len(den), len(poly_num))
        p1 = np.pad(den, (max_len - len(den), 0))
        p2 = np.pad(poly_num, (max_len - len(poly_num), 0))
        all_roots.append(np.roots(p1 + p2))

    all_roots = np.array(all_roots)

    # Track roots to maintain branch continuity
    tracked = np.zeros_like(all_roots)
    if len(all_roots) > 0:
        tracked[0] = all_roots[0]
        for i in range(1, len(all_roots)):
            prev = tracked[i - 1]
            curr = all_roots[i]
            new_row = np.zeros_like(curr)
            used_curr = set()
            for j in range(len(prev)):
                best_dist = float('inf')
                best_idx = 0
                for k_idx in range(len(curr)):
                    if k_idx in used_curr:
                        continue
                    dist = np.abs(curr[k_idx] - prev[j])
                    if dist < best_dist:
                        best_dist = dist
                        best_idx = k_idx
                new_row[j] = curr[best_idx]
                used_curr.add(best_idx)
            tracked[i] = new_row

    cfg = _unilab_plot_config
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()

    palette = _get_active_color_cycle()
    lw = float(p_kwargs.pop('linewidth', cfg['line_width']))
    ms = float(p_kwargs.pop('markersize', max(7.5, cfg['marker_size'] + 1.5)))

    if tracked.ndim == 2:
        for i in range(tracked.shape[1]):
            ax.plot(
                np.real(tracked[:, i]),
                np.imag(tracked[:, i]),
                color=palette[i % len(palette)],
                linewidth=lw,
                label=f'Branch {i + 1}' if tracked.shape[1] <= 4 else None,
            )

    ol_poles = np.roots(den)
    ol_zeros = np.roots(num)
    if len(ol_poles) > 0:
        ax.plot(np.real(ol_poles), np.imag(ol_poles), 'x', color='#f7768e', markersize=ms, markeredgewidth=1.8, label='Open-Loop Poles', zorder=5)
    if len(ol_zeros) > 0:
        ax.plot(np.real(ol_zeros), np.imag(ol_zeros), 'o', color='#7aa2f7', markersize=ms - 0.5, markeredgewidth=1.8, markerfacecolor='none', label='Open-Loop Zeros', zorder=5)

    ax.axhline(0, color=cfg['spine_color'], lw=1.0, zorder=1)
    ax.axvline(0, color=cfg['spine_color'], lw=1.0, zorder=1)

    # Compute sensible bounding box focused around poles, zeros, and moderate-gain loci
    key_pts = np.concatenate([
        ol_poles,
        ol_zeros,
        tracked[:min(len(tracked), 260)].flatten() if tracked.size > 0 else np.array([-1.0, 1.0]),
    ])
    finite_pts = key_pts[np.isfinite(key_pts)]
    if finite_pts.size > 0:
        r_min, r_max = float(np.min(np.real(finite_pts))), float(np.max(np.real(finite_pts)))
        i_min, i_max = float(np.min(np.imag(finite_pts))), float(np.max(np.imag(finite_pts)))
        span = max(r_max - r_min, i_max - i_min, 2.0)
        pad = 0.25 * span
        ax.set_xlim(min(r_min - pad, -0.5), max(r_max + pad, 0.5))
        ax.set_ylim(min(i_min - pad, -1.0), max(i_max + pad, 1.0))

    xlim_cur = ax.get_xlim()
    ylim_cur = ax.get_ylim()
    max_r = 1.4 * max(abs(xlim_cur[0]), abs(xlim_cur[1]), abs(ylim_cur[0]), abs(ylim_cur[1]), 1.0)

    # Subtle S-plane damping rays
    for z_val in (0.3, 0.5, 0.707, 0.9):
        ang = np.pi - np.arccos(z_val)
        ax.plot([0, max_r * np.cos(ang)], [0, max_r * np.sin(ang)], ':', color=cfg['grid_color'], alpha=0.45, linewidth=0.8)
        ax.plot([0, max_r * np.cos(ang)], [0, -max_r * np.sin(ang)], ':', color=cfg['grid_color'], alpha=0.45, linewidth=0.8)

    ax.set_xlim(xlim_cur)
    ax.set_ylim(ylim_cur)

    _apply_control_axes_style(ax, 'Root Locus', 'Real Axis (seconds⁻¹)', 'Imaginary Axis (seconds⁻¹)', extra_opts)
    ax.legend(loc='best', fontsize=max(7.5, cfg['font_size'] - 1.0), framealpha=0.85)
    _unilab_refresh_graph()
    return tracked, gains


def rlocus(sys, k=None, *args, **kwargs):
    return unilab_rlocus(sys, k, *args, **kwargs)


def unilab_zpk(z, p, k):
    return signal.ZerosPolesGain(_unilab_vec(z), _unilab_vec(p), k)


def _normalize_time_vec(T):
    if T is None:
        return None
    if isinstance(T, (list, tuple, np.ndarray)) and np.asarray(T).size == 0:
        return None
    if isinstance(T, (int, float, np.integer, np.floating)):
        return np.linspace(0, float(T), 1000)
    return _unilab_vec(T)


def unilab_step(sys, T=None):
    t, y = signal.step(sys, T=_normalize_time_vec(T))
    return t, y


def step(*args, **kwargs):
    systems, T_vec, line_specs, p_kwargs = _extract_lti_and_plot_opts(args, kwargs)
    if not systems and args:
        systems = [args[0]]
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    T_norm = _normalize_time_vec(T_vec)

    results = []
    for s_item in systems:
        t_i, y_i = signal.step(s_item, T=T_norm)
        results.append((t_i, y_i))

    n_out = unilab_get_nargout()
    if n_out == 0 and results:
        cfg = _unilab_plot_config
        ax = plt.gca()
        if not _get_hold_state():
            ax.cla()
            _unilab_update_fig_version()

        lw = float(p_kwargs.pop('linewidth', cfg['line_width']))
        palette = _get_active_color_cycle()
        for idx, (t_i, y_i) in enumerate(results):
            fmt = line_specs.get(idx, '')
            plot_kw = dict(p_kwargs)
            plot_kw.setdefault('linewidth', lw)
            if not fmt and 'color' not in plot_kw:
                plot_kw['color'] = palette[idx % len(palette)]
            if len(results) > 1 and 'label' not in plot_kw:
                plot_kw['label'] = f'System {idx + 1}'
            if fmt:
                ax.plot(t_i, y_i, fmt, **plot_kw)
            else:
                ax.plot(t_i, y_i, **plot_kw)
            # Subtle steady-state reference line
            if len(y_i) > 0:
                ax.axhline(float(y_i[-1]), color=cfg['spine_color'], linestyle=':', linewidth=0.9, alpha=0.6)

        _apply_control_axes_style(ax, 'Step Response', 'Time (s)', 'Amplitude', extra_opts)
        if len(results) > 1 or 'label' in p_kwargs or cfg.get('show_legend', False):
            if ax.get_legend_handles_labels()[0]:
                ax.legend(loc='best', fontsize=max(7.5, cfg['font_size'] - 1.0), framealpha=0.85)
        _unilab_refresh_graph()

    if not results:
        return np.array([]), np.array([])
    t0, y0 = results[0]
    return y0, t0


def unilab_impulse(sys, T=None):
    t, y = signal.impulse(sys, T=_normalize_time_vec(T))
    return t, y


def impulse(*args, **kwargs):
    systems, T_vec, line_specs, p_kwargs = _extract_lti_and_plot_opts(args, kwargs)
    if not systems and args:
        systems = [args[0]]
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    T_norm = _normalize_time_vec(T_vec)

    results = []
    for s_item in systems:
        t_i, y_i = signal.impulse(s_item, T=T_norm)
        results.append((t_i, y_i))

    n_out = unilab_get_nargout()
    if n_out == 0 and results:
        cfg = _unilab_plot_config
        ax = plt.gca()
        if not _get_hold_state():
            ax.cla()
            _unilab_update_fig_version()

        lw = float(p_kwargs.pop('linewidth', cfg['line_width']))
        palette = _get_active_color_cycle()
        ax.axhline(0.0, color=cfg['spine_color'], linestyle=':', linewidth=0.9, alpha=0.6)
        for idx, (t_i, y_i) in enumerate(results):
            fmt = line_specs.get(idx, '')
            plot_kw = dict(p_kwargs)
            plot_kw.setdefault('linewidth', lw)
            if not fmt and 'color' not in plot_kw:
                plot_kw['color'] = palette[idx % len(palette)]
            if len(results) > 1 and 'label' not in plot_kw:
                plot_kw['label'] = f'System {idx + 1}'
            if fmt:
                ax.plot(t_i, y_i, fmt, **plot_kw)
            else:
                ax.plot(t_i, y_i, **plot_kw)

        _apply_control_axes_style(ax, 'Impulse Response', 'Time (s)', 'Amplitude', extra_opts)
        if len(results) > 1 or 'label' in p_kwargs or cfg.get('show_legend', False):
            if ax.get_legend_handles_labels()[0]:
                ax.legend(loc='best', fontsize=max(7.5, cfg['font_size'] - 1.0), framealpha=0.85)
        _unilab_refresh_graph()

    if not results:
        return np.array([]), np.array([])
    t0, y0 = results[0]
    return y0, t0


def unilab_lsim(sys, U, T=None, x0=None):
    if T is not None and ((isinstance(T, np.ndarray) and T.size == 0) or (isinstance(T, list) and len(T) == 0)):
        T = None
    if T is None:
        T = np.linspace(0, 10, 1000)

    T_vec = _unilab_vec(T)
    U_vec = _unilab_vec(U)

    if hasattr(U_vec, 'free_symbols'):
        import sympy
        free_symbols = U_vec.free_symbols
        if free_symbols:
            sym_names = [s.name for s in free_symbols]
            if 't' in sym_names:
                var = sympy.Symbol('t')
            elif 's' in sym_names:
                var = sympy.Symbol('s')
            else:
                var = sorted(list(free_symbols), key=lambda x: x.name)[0]
            f_u = sympy.lambdify(var, U_vec, 'numpy')
            try:
                U_vec = f_u(T_vec)
                if np.isscalar(U_vec):
                    U_vec = np.full_like(T_vec, U_vec)
            except Exception:
                pass

    if np.isscalar(U_vec):
        U_vec = np.full_like(T_vec, U_vec)

    x0_vec = _unilab_vec(x0) if x0 is not None and np.asarray(x0).size > 0 else None
    t, y, x = signal.lsim(sys, U_vec, T_vec, X0=x0_vec)
    return t, y


def lsim(sys, U, T=None, x0=None, *args, **kwargs):
    _, p_kwargs = _parse_matlab_style_args(args)
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    t, y = unilab_lsim(sys, U, T, x0)
    if unilab_get_nargout() == 0:
        cfg = _unilab_plot_config
        ax = plt.gca()
        if not _get_hold_state():
            ax.cla()
            _unilab_update_fig_version()
        lw = float(p_kwargs.pop('linewidth', cfg['line_width']))
        palette = _get_active_color_cycle()
        u_arr = _unilab_vec(U)
        if isinstance(u_arr, np.ndarray) and u_arr.shape == t.shape:
            ax.plot(t, u_arr, '--', color=cfg['muted_fg_color'], linewidth=max(1.0, lw * 0.75), alpha=0.65, label='Input u(t)')
        ax.plot(t, y, color=p_kwargs.pop('color', palette[0]), linewidth=lw, label=p_kwargs.pop('label', 'Output y(t)'), **p_kwargs)
        _apply_control_axes_style(ax, 'Linear Simulation Results', 'Time (s)', 'Amplitude', extra_opts)
        ax.legend(loc='best', fontsize=max(7.5, cfg['font_size'] - 1.0), framealpha=0.85)
        _unilab_refresh_graph()
    return y, t


def _unilab_opt_vec(w):
    if w is None:
        return None
    if isinstance(w, np.ndarray) and w.size == 0:
        return None
    if isinstance(w, (list, tuple)) and len(w) == 0:
        return None
    return _unilab_vec(w)


def unilab_bode(sys, w=None, *args, **kwargs):
    systems, w_vec, line_specs, p_kwargs = _extract_lti_and_plot_opts((sys, w) + args if w is not None else (sys,) + args, kwargs)
    if not systems:
        systems = [sys]
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    w_opt = _unilab_opt_vec(w_vec)

    cfg = _unilab_plot_config
    fig = plt.gcf()
    cur_ax = plt.gca()
    # If the user previously created subplots (e.g. subplot(2,2,3)), check whether to draw in current sub-axes or create two stacked subplots
    is_in_multi_subplot = len(fig.axes) > 1 and not (len(fig.axes) == 2 and hasattr(fig.axes[1], '_sharex'))
    if is_in_multi_subplot:
        # User called bode inside an existing subplot: plot magnitude and phase onto inset/twin or current axes cleanly
        ax_mag = cur_ax
        if not _get_hold_state():
            ax_mag.cla()
        ax_phase = ax_mag.twinx()
        ax_phase._twinx_for = ax_mag
    elif not _get_hold_state() or len(fig.axes) != 2:
        fig.clf()
        _unilab_update_fig_version()
        ax_mag = fig.add_subplot(2, 1, 1)
        ax_phase = fig.add_subplot(2, 1, 2, sharex=ax_mag)
    else:
        ax_mag, ax_phase = fig.axes[0], fig.axes[1]

    lw = float(p_kwargs.pop('linewidth', cfg['line_width']))
    palette = _get_active_color_cycle()

    w_out, mag_out, phase_out = None, None, None
    for idx, s_item in enumerate(systems):
        w_i, mag_i, phase_i = signal.bode(s_item, w=w_opt)
        if isinstance(mag_i, np.ndarray) and mag_i.ndim > 1:
            mag_i = mag_i.squeeze()
        if isinstance(phase_i, np.ndarray) and phase_i.ndim > 1:
            phase_i = phase_i.squeeze()
        if idx == 0:
            w_out, mag_out, phase_out = w_i, mag_i, phase_i

        fmt = line_specs.get(idx, '')
        col = p_kwargs.get('color', palette[idx % len(palette)])
        lbl = p_kwargs.get('label', f'System {idx + 1}' if len(systems) > 1 else None)
        if fmt:
            ax_mag.semilogx(w_i, mag_i, fmt, linewidth=lw, label=lbl)
            ax_phase.semilogx(w_i, phase_i, fmt, linewidth=lw, label=lbl)
        else:
            ax_mag.semilogx(w_i, mag_i, color=col, linewidth=lw, label=lbl)
            ax_phase.semilogx(w_i, phase_i, color=col, linewidth=lw, label=lbl)

    ax_mag.axhline(0.0, color=cfg['spine_color'], linestyle=':', linewidth=0.9, alpha=0.6)
    _apply_control_axes_style(ax_mag, 'Bode Diagram', None, 'Magnitude (dB)', extra_opts)
    _apply_control_axes_style(ax_phase, None, 'Frequency (rad/s)', 'Phase (deg)', extra_opts)
    if len(systems) > 1 or 'label' in p_kwargs:
        ax_mag.legend(loc='best', fontsize=max(7.5, cfg['font_size'] - 1.0), framealpha=0.85)

    _unilab_refresh_graph()
    return w_out, mag_out, phase_out


def bode(*args, **kwargs):
    if not args:
        return np.array([]), np.array([]), np.array([])
    w, mag, phase = unilab_bode(*args, **kwargs)
    return mag, phase, w


def unilab_nyquist(sys, w=None, *args, **kwargs):
    systems, w_vec, line_specs, p_kwargs = _extract_lti_and_plot_opts((sys, w) + args if w is not None else (sys,) + args, kwargs)
    if not systems:
        systems = [sys]
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    w_opt = _unilab_opt_vec(w_vec)

    cfg = _unilab_plot_config
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()

    lw = float(p_kwargs.pop('linewidth', cfg['line_width']))
    palette = _get_active_color_cycle()

    # Unit circle reference
    theta = np.linspace(0, 2 * np.pi, 200)
    ax.plot(np.cos(theta), np.sin(theta), ':', color=cfg['grid_color'], linewidth=0.9, alpha=0.6)

    w_out, h_out = None, None
    for idx, s_item in enumerate(systems):
        w_i, h_i = signal.freqresp(s_item, w=w_opt)
        if idx == 0:
            w_out, h_out = w_i, h_i
        col = p_kwargs.get('color', palette[idx % len(palette)])
        lbl_pos = f'H(jω){f" ({idx+1})" if len(systems) > 1 else ""}'
        lbl_neg = f'H(-jω){f" ({idx+1})" if len(systems) > 1 else ""}'
        re_h, im_h = np.real(h_i), np.imag(h_i)
        ax.plot(re_h, im_h, color=col, linewidth=lw, label=lbl_pos)
        ax.plot(re_h, -im_h, '--', color=col, linewidth=max(1.1, lw * 0.8), alpha=0.7, label=lbl_neg)
        # Add arrow at midpoint
        if len(re_h) > 4:
            mid = len(re_h) // 2
            ax.annotate(
                '',
                xy=(re_h[mid], im_h[mid]),
                xytext=(re_h[mid - 1], im_h[mid - 1]),
                arrowprops=dict(arrowstyle='->', color=col, lw=lw),
            )

    ax.plot(-1, 0, '+', color='#f7768e', markersize=10, markeredgewidth=2.0, label='Critical (-1, 0)', zorder=6)
    ax.axhline(0, color=cfg['spine_color'], lw=0.9, zorder=1)
    ax.axvline(0, color=cfg['spine_color'], lw=0.9, zorder=1)
    _apply_control_axes_style(ax, 'Nyquist Diagram', 'Real Axis', 'Imaginary Axis', extra_opts)
    ax.legend(loc='best', fontsize=max(7.5, cfg['font_size'] - 1.0), framealpha=0.85)
    _unilab_refresh_graph()
    return w_out, h_out


def nyquist(sys, w=None, *args, **kwargs):
    w_out, h_out = unilab_nyquist(sys, w, *args, **kwargs)
    return np.real(h_out), np.imag(h_out), w_out


def unilab_nichols(sys, w=None, *args, **kwargs):
    systems, w_vec, _, p_kwargs = _extract_lti_and_plot_opts((sys, w) + args if w is not None else (sys,) + args, kwargs)
    if not systems:
        systems = [sys]
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    w_opt = _unilab_opt_vec(w_vec)

    cfg = _unilab_plot_config
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()

    lw = float(p_kwargs.pop('linewidth', cfg['line_width']))
    palette = _get_active_color_cycle()

    w_out, h_out = None, None
    for idx, s_item in enumerate(systems):
        w_i, h_i = signal.freqresp(s_item, w=w_opt)
        if idx == 0:
            w_out, h_out = w_i, h_i
        mag = 20 * np.log10(np.maximum(np.abs(h_i), 1e-15))
        phase = np.rad2deg(np.unwrap(np.angle(h_i)))
        col = p_kwargs.get('color', palette[idx % len(palette)])
        ax.plot(phase, mag, color=col, linewidth=lw, label=f'System {idx + 1}' if len(systems) > 1 else 'Open-Loop')

    ax.axhline(0, color=cfg['spine_color'], lw=0.9, linestyle=':')
    ax.axvline(-180, color='#f7768e', lw=1.2, linestyle='--')
    ax.plot(-180, 0, '+', color='#f7768e', markersize=10, markeredgewidth=2.0, label='Critical (-180°, 0 dB)')
    _apply_control_axes_style(ax, 'Nichols Chart', 'Open-Loop Phase (deg)', 'Open-Loop Gain (dB)', extra_opts)
    ax.legend(loc='best', fontsize=max(7.5, cfg['font_size'] - 1.0), framealpha=0.85)
    _unilab_refresh_graph()
    return w_out, h_out


def nichols(sys, w=None, *args, **kwargs):
    w_out, h_out = unilab_nichols(sys, w, *args, **kwargs)
    mag = 20 * np.log10(np.maximum(np.abs(h_out), 1e-15))
    phase = np.rad2deg(np.angle(h_out))
    return mag, phase, w_out


def unilab_sigma(sys, w=None, *args, **kwargs):
    _, w_vec, _, p_kwargs = _extract_lti_and_plot_opts((sys, w) + args if w is not None else (sys,) + args, kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    w_opt = _unilab_opt_vec(w_vec)
    w_out, h = signal.freqresp(sys, w=w_opt)

    sigmas = []
    if h.ndim == 3:
        for i in range(len(w_out)):
            H_w = h[:, :, i]
            s = np.linalg.svd(H_w, compute_uv=False)
            sigmas.append(s)
    else:
        sigmas = np.abs(h).reshape(-1, 1)

    sigmas = np.array(sigmas)

    cfg = _unilab_plot_config
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()

    lw = float(p_kwargs.pop('linewidth', cfg['line_width']))
    palette = _get_active_color_cycle()
    ax.semilogx(w_out, 20 * np.log10(np.maximum(sigmas, 1e-15)), color=p_kwargs.get('color', palette[0]), linewidth=lw)
    _apply_control_axes_style(ax, 'Singular Values', 'Frequency (rad/s)', 'Singular Values (dB)', extra_opts)
    _unilab_refresh_graph()
    return w_out, sigmas


def sigma(sys, w=None, *args, **kwargs):
    w_out, sigmas = unilab_sigma(sys, w, *args, **kwargs)
    return sigmas, w_out


def _compute_margins(sys):
    w = np.logspace(-2, 3, 2000)
    w, mag_db, phase = signal.bode(sys, w=w)
    mag = 10.0 ** (mag_db / 20.0)

    # Phase crossover (-180 deg) -> Gain margin
    phase_shifted = phase + 180.0
    sign_changes_gm = np.where(np.diff(np.sign(phase_shifted)) != 0)[0]
    if len(sign_changes_gm) > 0:
        idx = sign_changes_gm[0]
        # Linear interpolation
        p0, p1 = phase_shifted[idx], phase_shifted[idx + 1]
        frac = -p0 / (p1 - p0) if (p1 != p0) else 0.0
        w_gm = float(w[idx] + frac * (w[idx + 1] - w[idx]))
        mag_at_gm = float(mag[idx] + frac * (mag[idx + 1] - mag[idx]))
        gm = (1.0 / mag_at_gm) if mag_at_gm > 0 else np.inf
    else:
        gm = np.inf
        w_gm = np.nan

    # Gain crossover (0 dB) -> Phase margin
    sign_changes_pm = np.where(np.diff(np.sign(mag_db)) != 0)[0]
    if len(sign_changes_pm) > 0:
        idx = sign_changes_pm[0]
        m0, m1 = mag_db[idx], mag_db[idx + 1]
        frac = -m0 / (m1 - m0) if (m1 != m0) else 0.0
        w_pm = float(w[idx] + frac * (w[idx + 1] - w[idx]))
        phase_at_pm = float(phase[idx] + frac * (phase[idx + 1] - phase[idx]))
        pm = 180.0 + phase_at_pm
    else:
        pm = np.inf
        w_pm = np.nan

    return gm, pm, w_gm, w_pm, w, mag_db, phase


def unilab_margin(sys, *args, **kwargs):
    gm, pm, w_gm, w_pm, w, mag_db, phase = _compute_margins(sys)
    gm_db = 20.0 * np.log10(gm) if (np.isfinite(gm) and gm > 0) else np.inf

    gm_str = f"{gm_db:.2f} dB (at {w_gm:.2f} rad/s)" if np.isfinite(gm_db) else "Inf dB"
    pm_str = f"{pm:.2f} deg (at {w_pm:.2f} rad/s)" if np.isfinite(pm) else "Inf deg"
    print(f"Gain Margin: {gm_str}")
    print(f"Phase Margin: {pm_str}")

    if unilab_get_nargout() == 0:
        cfg = _unilab_plot_config
        fig = plt.gcf()
        fig.clf()
        _unilab_update_fig_version()
        ax_mag = fig.add_subplot(2, 1, 1)
        ax_phase = fig.add_subplot(2, 1, 2, sharex=ax_mag)

        palette = _get_active_color_cycle()
        lw = float(cfg['line_width'])

        ax_mag.semilogx(w, mag_db, color=palette[0], linewidth=lw, label='Magnitude')
        ax_mag.axhline(0.0, color=cfg['spine_color'], linestyle=':', linewidth=1.0)
        if np.isfinite(w_gm) and np.isfinite(gm_db):
            ax_mag.axvline(w_gm, color='#f7768e', linestyle='--', linewidth=1.1, alpha=0.8)
            ax_mag.plot([w_gm, w_gm], [0.0, -gm_db], color='#f7768e', linewidth=2.2, label=f'Gm = {gm_db:.1f} dB')
            ax_mag.plot(w_gm, -gm_db, 'o', color='#f7768e', markersize=6)
        if np.isfinite(w_pm):
            ax_mag.plot(w_pm, 0.0, 'o', color='#9ece6a', markersize=6)
            ax_mag.axvline(w_pm, color='#9ece6a', linestyle='--', linewidth=1.1, alpha=0.8)

        ax_phase.semilogx(w, phase, color=palette[0], linewidth=lw, label='Phase')
        ax_phase.axhline(-180.0, color=cfg['spine_color'], linestyle=':', linewidth=1.0)
        if np.isfinite(w_pm) and np.isfinite(pm):
            ax_phase.axvline(w_pm, color='#9ece6a', linestyle='--', linewidth=1.1, alpha=0.8)
            ax_phase.plot([w_pm, w_pm], [-180.0, -180.0 + pm], color='#9ece6a', linewidth=2.2, label=f'Pm = {pm:.1f}°')
            ax_phase.plot(w_pm, -180.0 + pm, 'o', color='#9ece6a', markersize=6)
        if np.isfinite(w_gm):
            ax_phase.plot(w_gm, -180.0, 'o', color='#f7768e', markersize=6)
            ax_phase.axvline(w_gm, color='#f7768e', linestyle='--', linewidth=1.1, alpha=0.8)

        title_summary = f"Bode Stability Margins  |  Gm = {gm_db:.1f} dB,  Pm = {pm:.1f}°"
        _apply_control_axes_style(ax_mag, title_summary, None, 'Magnitude (dB)')
        _apply_control_axes_style(ax_phase, None, 'Frequency (rad/s)', 'Phase (deg)')
        if ax_mag.get_legend_handles_labels()[0]:
            ax_mag.legend(loc='best', fontsize=max(7.5, cfg['font_size'] - 1.0), framealpha=0.85)
        if ax_phase.get_legend_handles_labels()[0]:
            ax_phase.legend(loc='best', fontsize=max(7.5, cfg['font_size'] - 1.0), framealpha=0.85)
        _unilab_refresh_graph()

    return gm, pm, w_gm, w_pm


def margin(sys, *args, **kwargs):
    return unilab_margin(sys, *args, **kwargs)

def unilab_lqr(A, B, Q, R):
    from scipy.linalg import solve_continuous_are
    A, B, Q, R = np.atleast_2d(A), np.atleast_2d(B), np.atleast_2d(Q), np.atleast_2d(R)
    P = solve_continuous_are(A, B, Q, R)
    K = np.linalg.inv(R) @ (B.T @ P)
    E = np.linalg.eigvals(A - B @ K)
    return K, P, E

def unilab_place(A, B, p):
    res = signal.place_poles(np.atleast_2d(A), np.atleast_2d(B), _unilab_vec(p))
    return res.gain_matrix

def unilab_acker(A, B, p):
    # Ackermann's formula for SISO
    A, B = np.atleast_2d(A), np.atleast_2d(B)
    n = A.shape[0]
    p = _unilab_vec(p)
    # Desired characteristic polynomial: poly(p)
    poly = np.poly(p)
    # Matrix polynomial Phi(A)
    Phi = np.zeros_like(A)
    for i, coeff in enumerate(reversed(poly)):
        Phi += coeff * np.linalg.matrix_power(A, i)
    # Controllability matrix
    C = unilab_ctrb(A, B)
    C_inv = np.linalg.inv(C)
    # Last row of inverse C
    e_n = np.zeros((1, n))
    e_n[0, -1] = 1
    K = e_n @ C_inv @ Phi
    return K

def unilab_initial(sys, x0, T=None):
    # Handle empty T arrays
    if T is not None and isinstance(T, np.ndarray) and T.size == 0:
        T = None
    elif T is not None and isinstance(T, list) and len(T) == 0:
        T = None
        
    # Handle empty x0
    x0_vec = _unilab_vec(x0)
    if x0_vec is not None and hasattr(x0_vec, '__len__') and len(x0_vec) == 0:
        x0_vec = None
        
    if not isinstance(sys, signal.StateSpace):
        sys = sys.to_ss()
    if T is None: T = np.linspace(0, 10, 1000)
    elif isinstance(T, (int, float, np.integer, np.floating)): T = np.linspace(0, T, 1000)
    T = _unilab_vec(T)
    U = np.zeros_like(T)
    t, y, x = signal.lsim(sys, U, T, X0=x0_vec)
    return t, y, x


def initial(sys, x0, T=None, *args, **kwargs):
    _, p_kwargs = _parse_matlab_style_args(args)
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    t, y, x = unilab_initial(sys, x0, T)
    if unilab_get_nargout() == 0:
        cfg = _unilab_plot_config
        ax = plt.gca()
        if not _get_hold_state():
            ax.cla()
            _unilab_update_fig_version()
        lw = float(p_kwargs.pop('linewidth', cfg['line_width']))
        palette = _get_active_color_cycle()
        ax.axhline(0.0, color=cfg['spine_color'], linestyle=':', linewidth=0.9, alpha=0.6)
        ax.plot(t, y, color=p_kwargs.pop('color', palette[0]), linewidth=lw, **p_kwargs)
        _apply_control_axes_style(ax, 'Initial Condition Response', 'Time (s)', 'Amplitude', extra_opts)
        _unilab_refresh_graph()
    return y, t, x

def unilab_stepinfo(sys):
    t, y = unilab_step(sys)
    y = y.flatten()
    ss_val = y[-1]
    if np.abs(ss_val) < 1e-12: return {}
    idx10 = np.where(y >= 0.1 * ss_val)[0]
    idx90 = np.where(y >= 0.9 * ss_val)[0]
    tr = t[idx90[0]] - t[idx10[0]] if len(idx10) > 0 and len(idx90) > 0 else 0
    # Settling time (2%)
    tol = 0.02 * np.abs(ss_val)
    idx_outside = np.where(np.abs(y - ss_val) > tol)[0]
    ts = t[idx_outside[-1] + 1] if len(idx_outside) > 0 and idx_outside[-1] + 1 < len(t) else t[-1]
    peak_idx = np.argmax(np.abs(y))
    peak_val = y[peak_idx]
    os = (np.abs(peak_val) - np.abs(ss_val)) / np.abs(ss_val) * 100
    return {'RiseTime': tr, 'SettlingTime': ts, 'Overshoot': os, 'Peak': peak_val, 'PeakTime': t[peak_idx], 'SteadyStateValue': ss_val}

def unilab_bandwidth(sys, db_drop=-3):
    w, mag, _ = signal.bode(sys)
    dc_mag = mag[0]
    target = dc_mag + db_drop
    idx = np.where(mag <= target)[0]
    return w[idx[0]] if len(idx) > 0 else np.inf

def unilab_gram(sys, type='c'):
    from scipy.linalg import solve_continuous_lyapunov
    if not isinstance(sys, signal.StateSpace): sys = sys.to_ss()
    A, B, C, _D = sys.A, sys.B, sys.C, sys.D
    if type.lower() == 'c': return solve_continuous_lyapunov(A, -np.atleast_2d(B) @ np.atleast_2d(B).T)
    else: return solve_continuous_lyapunov(A.T, -np.atleast_2d(C).T @ np.atleast_2d(C))

def unilab_care(A, B, Q, R):
    from scipy.linalg import solve_continuous_are
    return solve_continuous_are(np.atleast_2d(A), np.atleast_2d(B), np.atleast_2d(Q), np.atleast_2d(R))

def unilab_dare(A, B, Q, R):
    from scipy.linalg import solve_discrete_are
    return solve_discrete_are(np.atleast_2d(A), np.atleast_2d(B), np.atleast_2d(Q), np.atleast_2d(R))

def unilab_lyap(A, Q):
    from scipy.linalg import solve_continuous_lyapunov
    return solve_continuous_lyapunov(np.atleast_2d(A), np.atleast_2d(Q))

def unilab_kalman(sys, Q, R):
    from scipy.linalg import solve_continuous_are
    if not isinstance(sys, signal.StateSpace): sys = sys.to_ss()
    A, C, Q, R = np.atleast_2d(sys.A), np.atleast_2d(sys.C), np.atleast_2d(Q), np.atleast_2d(R)
    P = solve_continuous_are(A.T, C.T, Q, R)
    L = P @ C.T @ np.linalg.inv(R)
    return L, P, np.linalg.eigvals(A - L @ C)

def unilab_lqg(sys, Q, R, Qn, Rn):
    if not isinstance(sys, signal.StateSpace): sys = sys.to_ss()
    K, _, _ = unilab_lqr(sys.A, sys.B, Q, R)
    L, _, _ = unilab_kalman(sys, Qn, Rn)
    A_reg = sys.A - sys.B @ K - L @ sys.C
    return signal.StateSpace(A_reg, L, K, np.zeros((K.shape[0], L.shape[1])))

def unilab_d2c(sys, method='zoh'):
    from scipy.linalg import logm
    was_tf = isinstance(sys, signal.TransferFunction)
    dt = float(getattr(sys, 'dt', None) or 1.0)
    if dt <= 0:
        raise ValueError("Discrete-time system must have a positive sampling time dt.")
    ss_d = sys if isinstance(sys, signal.StateSpace) else sys.to_ss()
    Ad = np.atleast_2d(np.asarray(ss_d.A, dtype=float))
    Bd = np.atleast_2d(np.asarray(ss_d.B, dtype=float))
    Cd = np.atleast_2d(np.asarray(ss_d.C, dtype=float))
    Dd = np.atleast_2d(np.asarray(ss_d.D, dtype=float))
    n = Ad.shape[0]
    m = Bd.shape[1]
    m_name = str(method).lower()
    if m_name in ('tustin', 'bilinear'):
        I_n = np.eye(n)
        inv_p = np.linalg.inv(I_n + Ad)
        Ac = (2.0 / dt) * inv_p @ (Ad - I_n)
        Bc = (2.0 / dt) * inv_p @ Bd
        Cc = 2.0 * Cd @ inv_p
        Dc = Dd - Cd @ inv_p @ Bd
    else:
        aug = np.block([
            [Ad, Bd],
            [np.zeros((m, n)), np.eye(m)]
        ])
        L = logm(aug) / dt
        if np.max(np.abs(np.imag(L))) < 1e-8:
            L = np.real(L)
        Ac = L[:n, :n]
        Bc = L[:n, n:]
        Cc = Cd
        Dc = Dd
    sys_c = signal.StateSpace(Ac, Bc, Cc, Dc)
    if was_tf:
        return sys_c.to_tf()
    return sys_c

def unilab_zp2ss(z, p, k):
    return signal.zpk2ss(_unilab_vec(z), _unilab_vec(p), k)

def unilab_ss2zp(A, B, C, D, iu=0):
    return signal.ss2zpk(A, B, C, D, input=iu)

def blkdiag(*args):
    from scipy.linalg import block_diag
    return block_diag(*[np.atleast_2d(a) for a in args])

def unilab_append(*args):
    from scipy.linalg import block_diag
    As, Bs, Cs, Ds = [], [], [], []
    for s in args:
        if not isinstance(s, signal.StateSpace): s = s.to_ss()
        As.append(s.A); Bs.append(s.B); Cs.append(s.C); Ds.append(s.D)
    return signal.StateSpace(block_diag(*As), block_diag(*Bs), block_diag(*Cs), block_diag(*Ds))

def unilab_canon(sys, type='modal'):
    if not isinstance(sys, signal.StateSpace): sys = sys.to_ss()
    if type == 'modal':
        E, V = np.linalg.eig(sys.A)
        invV = np.linalg.inv(V)
        # Handle complex pairs to keep real if desired? No, MATLAB modal can be complex diagonal
        return signal.StateSpace(np.diag(E), invV @ sys.B, sys.C @ V, sys.D)
    return sys

def unilab_allmargin(sys):
    gm, pm, w_gm, w_pm, _, _, _ = _compute_margins(sys)
    return gm, pm, w_gm, w_pm


def allmargin(sys):
    gm, pm, w_gm, w_pm = unilab_allmargin(sys)
    return struct('GainMargin', gm, 'PhaseMargin', pm, 'GMFrequency', w_gm, 'PMFrequency', w_pm)


def unilab_freqfreqz(b, a=1, worN=512, fs=None):
    b_vec = _unilab_vec(b) if b is not None and np.asarray(b).size > 0 else np.array([1.0])
    a_vec = _unilab_vec(a) if a is not None and np.asarray(a).size > 0 else np.array([1.0])
    n_pts = int(worN) if isinstance(worN, (int, float, np.integer, np.floating)) else (512 if worN is None or (hasattr(worN, '__len__') and len(worN) == 0) else _unilab_vec(worN))
    if fs is not None and np.asarray(fs).size > 0:
        w, h = signal.freqz(b_vec, a_vec, worN=n_pts, fs=float(np.asarray(fs).item()))
    else:
        w, h = signal.freqz(b_vec, a_vec, worN=n_pts)
    return w, h


def freqz(b, a=1, worN=512, fs=None, *args, **kwargs):
    _, p_kwargs = _parse_matlab_style_args(args)
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    w, h = unilab_freqfreqz(b, a, worN, fs)
    if unilab_get_nargout() == 0:
        cfg = _unilab_plot_config
        fig = plt.gcf()
        if not _get_hold_state() or len(fig.axes) != 2:
            fig.clf()
            _unilab_update_fig_version()
            ax_mag = fig.add_subplot(2, 1, 1)
            ax_phase = fig.add_subplot(2, 1, 2, sharex=ax_mag)
        else:
            ax_mag, ax_phase = fig.axes[0], fig.axes[1]

        palette = _get_active_color_cycle()
        lw = float(p_kwargs.pop('linewidth', cfg['line_width']))
        col = p_kwargs.pop('color', palette[0])

        mag_db = 20.0 * np.log10(np.maximum(np.abs(h), 1e-12))
        phase_deg = np.rad2deg(np.unwrap(np.angle(h)))
        x_vals = w if (fs is not None and np.asarray(fs).size > 0) else (w / np.pi)
        freq_unit = 'Frequency (Hz)' if (fs is not None and np.asarray(fs).size > 0) else 'Normalized Frequency (×π rad/sample)'

        ax_mag.plot(x_vals, mag_db, color=col, linewidth=lw)
        ax_mag.axhline(-3.0, color=cfg['spine_color'], linestyle=':', linewidth=0.9, alpha=0.7)
        _apply_control_axes_style(ax_mag, 'Digital Filter Frequency Response', None, 'Magnitude (dB)', extra_opts)

        ax_phase.plot(x_vals, phase_deg, color=palette[1 % len(palette)], linewidth=lw)
        _apply_control_axes_style(ax_phase, None, freq_unit, 'Phase (degrees)', extra_opts)
        _unilab_refresh_graph()
    return h, w


def unilab_conv(a, v, mode='full'):
    return signal.convolve(_unilab_vec(a), _unilab_vec(v), mode=mode)


def unilab_xcorr(a, v=None, mode='full'):
    if v is None: v = a
    c = signal.correlate(_unilab_vec(a), _unilab_vec(v), mode=mode)

    n_out = unilab_get_nargout()
    if n_out <= 1:
        return c

    # [c, lags]
    n = len(_unilab_vec(a))
    m = len(_unilab_vec(v))
    if mode == 'full':
        lags = np.arange(-m + 1, n)
    elif mode == 'same':
        lags = np.arange(-max(n, m) // 2, max(n, m) // 2 + max(n, m) % 2)
    else:
        lags = np.arange(0, len(c))

    return c, lags


def unilab_pwelch(x, window=None, noverlap=None, nfft=None, fs=1.0):
    x_vec = np.asarray(_unilab_vec(x), dtype=float).flatten()
    nperseg = min(256, len(x_vec))
    win_arg = 'hann'
    if window is not None and np.asarray(window).size > 0:
        w_arr = np.asarray(window).flatten()
        if w_arr.size == 1:
            nperseg = min(int(w_arr.item()), len(x_vec))
        else:
            win_arg = w_arr
            nperseg = len(w_arr)
    nover = int(noverlap) if (noverlap is not None and np.asarray(noverlap).size > 0) else (nperseg // 2)
    nover = min(nover, max(0, nperseg - 1))
    nfft_val = int(nfft) if (nfft is not None and np.asarray(nfft).size > 0) else max(256, nperseg)
    fs_val = float(np.asarray(fs).item()) if (fs is not None and np.asarray(fs).size > 0) else 1.0
    f, Pxx = signal.welch(x_vec, fs=fs_val, window=win_arg, nperseg=nperseg, noverlap=nover, nfft=nfft_val)
    return f, Pxx


def pwelch(x, *args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args)
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)

    # Support both pwelch(x, fs) 2-arg shorthand and pwelch(x, window, noverlap, nfft, fs)
    window, noverlap, nfft, fs = None, None, None, 1.0
    if len(p_args) == 1:
        fs = p_args[0]
    elif len(p_args) >= 2:
        window = p_args[0]
        noverlap = p_args[1]
        if len(p_args) >= 3:
            nfft = p_args[2]
        if len(p_args) >= 4:
            fs = p_args[3]

    f, Pxx = unilab_pwelch(x, window=window, noverlap=noverlap, nfft=nfft, fs=fs)
    if unilab_get_nargout() == 0:
        cfg = _unilab_plot_config
        ax = plt.gca()
        if not _get_hold_state():
            ax.cla()
            _unilab_update_fig_version()
        lw = float(p_kwargs.pop('linewidth', cfg['line_width']))
        palette = _get_active_color_cycle()
        pxx_db = 10.0 * np.log10(np.maximum(Pxx, 1e-18))
        ax.plot(f, pxx_db, color=p_kwargs.pop('color', palette[0]), linewidth=lw)
        ax.fill_between(f, pxx_db, np.min(pxx_db) - 5.0, color=palette[0], alpha=0.12)
        ax.set_ylim(bottom=float(np.min(pxx_db) - 3.0), top=float(np.max(pxx_db) + 5.0))
        _apply_control_axes_style(ax, 'Welch Power Spectral Density Estimate', 'Frequency (Hz)', 'Power/Frequency (dB/Hz)', extra_opts)
        _unilab_refresh_graph()
    return Pxx, f


def spectrogram(x, window=None, noverlap=None, nfft=None, fs=1.0, *args, **kwargs):
    _, p_kwargs = _parse_matlab_style_args(args)
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)

    x_vec = np.asarray(_unilab_vec(x), dtype=float).flatten()
    nperseg = min(128, len(x_vec))
    win_arg = 'hann'
    if window is not None and not isinstance(window, str) and np.asarray(window).size > 0:
        w_arr = np.asarray(window).flatten()
        if w_arr.size == 1:
            nperseg = min(int(w_arr.item()), len(x_vec))
        else:
            win_arg = w_arr
            nperseg = len(w_arr)
    nover = int(noverlap) if (noverlap is not None and not isinstance(noverlap, str) and np.asarray(noverlap).size > 0) else int(0.75 * nperseg)
    nover = min(nover, max(0, nperseg - 1))
    nfft_val = int(nfft) if (nfft is not None and not isinstance(nfft, str) and np.asarray(nfft).size > 0) else max(128, nperseg)
    fs_val = float(np.asarray(fs).item()) if (fs is not None and not isinstance(fs, str) and np.asarray(fs).size > 0) else 1.0

    f_vec, t_vec, Sxx = signal.spectrogram(
        x_vec, fs=fs_val, window=win_arg, nperseg=nperseg, noverlap=nover, nfft=nfft_val, mode='psd'
    )
    _, _, Zxx = signal.spectrogram(
        x_vec, fs=fs_val, window=win_arg, nperseg=nperseg, noverlap=nover, nfft=nfft_val, mode='complex'
    )

    if unilab_get_nargout() == 0:
        cfg = _unilab_plot_config
        ax = plt.gca()
        if not _get_hold_state():
            ax.cla()
            _unilab_update_fig_version()
        cmap_name = p_kwargs.pop('cmap', cfg.get('colormap', 'viridis')).lower()
        s_db = 10.0 * np.log10(np.maximum(Sxx, 1e-18))
        mesh_obj = ax.pcolormesh(t_vec, f_vec, s_db, shading='gouraud', cmap=cmap_name)
        if len(ax.figure.axes) <= 2:
            cb = ax.figure.colorbar(mesh_obj, ax=ax, pad=0.02)
            cb.set_label('Power/Frequency (dB/Hz)', fontsize=max(7.5, cfg['font_size'] - 0.5), color=cfg['fg_color'])
            cb.ax.tick_params(labelsize=max(7.0, cfg['font_size'] - 1.0), colors=cfg['muted_fg_color'])
        _apply_control_axes_style(ax, 'Spectrogram (Time-Frequency Analysis)', 'Time (s)', 'Frequency (Hz)', extra_opts)
        _unilab_refresh_graph()

    return Zxx, f_vec, t_vec, Sxx

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
    if signal is not None:
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

def edit(filename):
    """Signals the frontend to open a file."""
    # Push event via update context if available
    cb = unilab_update_ctx.get()
    if cb:
        # We need a way to push arbitrary events. 
        # For now, we can abuse the variables snapshot or add a new context.
        # But TranspilerEngine._trigger_workspace_changed only sends variables.
        pass
    
    # Actually, the easiest is to print a marker that AppProvider handles
    print(f"::OPEN_FILE::{filename}")

def _to_safe_serializable(val):
    """Prepare values for safe scipy.io.savemat / np.savez without pickle."""
    if isinstance(val, (int, float, complex, str, bool, np.number, np.bool_)):
        return val
    if isinstance(val, np.ndarray):
        if val.dtype == object:
            # Convert homogeneous string/numeric object arrays if possible
            flat = val.flatten().tolist()
            if builtins.all(isinstance(x, (int, float, complex, str, bool, np.number, np.bool_)) for x in flat):
                return np.array(val.tolist())
        return val
    if isinstance(val, (list, tuple)):
        return np.array(val)
    if isinstance(val, UnilabStruct):
        return {k: _to_safe_serializable(v) for k, v in val.__dict__.items() if not k.startswith('_')}
    if isinstance(val, dict):
        return {str(k): _to_safe_serializable(v) for k, v in val.items() if not str(k).startswith('_')}
    return str(val)


def _save_safe_dict(path: pathlib.Path, data: dict) -> None:
    """Save dictionary of variables safely using scipy.io.savemat or np.savez (never pickle)."""
    from scipy.io import savemat
    clean_data = {}
    for k, v in data.items():
        if not isinstance(k, str) or not k or k.startswith('_'):
            continue
        try:
            clean_data[k] = _to_safe_serializable(v)
        except Exception:
            continue

    path.parent.mkdir(parents=True, exist_ok=True)
    if path.suffix.lower() == '.npz':
        with open(path, 'wb') as f:
            np.savez(f, **{k: np.asarray(v) if not isinstance(v, dict) else str(v) for k, v in clean_data.items()})
        return

    try:
        savemat(str(path), clean_data, do_compression=True)
    except Exception:
        # Fallback to safe .npz format (without pickle) for types savemat rejects
        npz_dict = {}
        for k, v in clean_data.items():
            arr = np.asarray(v) if not isinstance(v, dict) else np.asarray(str(v))
            if arr.dtype != object:
                npz_dict[k] = arr
            else:
                npz_dict[k] = np.asarray([str(x) for x in arr.flatten()]).reshape(arr.shape)
        with open(path, 'wb') as f:
            np.savez(f, **npz_dict)


def _load_safe_dict(path: pathlib.Path) -> dict:
    """Load dictionary of variables safely using scipy.io.loadmat or np.load(..., allow_pickle=False)."""
    from scipy.io import loadmat
    with open(path, 'rb') as f:
        header = f.read(4)

    data = {}
    if header == b'PK\x03\x04' or path.suffix.lower() == '.npz':
        with np.load(str(path), allow_pickle=False) as archive:
            for k in archive.files:
                val = archive[k]
                if val.ndim == 0:
                    data[k] = val.item()
                else:
                    data[k] = val
        return data

    raw = loadmat(str(path), squeeze_me=False)
    for k, v in raw.items():
        if k.startswith('__') and k.endswith('__'):
            continue
        if isinstance(v, np.ndarray):
            if v.dtype.kind in ('U', 'S'):
                if v.size == 1:
                    data[k] = str(v.item())
                elif v.ndim <= 1:
                    data[k] = "".join(v.tolist())
                else:
                    data[k] = v
            elif v.size == 1 and v.ndim == 2 and v.shape == (1, 1):
                data[k] = v.item()
            else:
                data[k] = v
        else:
            data[k] = v
    return data


def save(filename, *vars):
    """Saves variables to a .mat or .npz file safely without pickle."""
    fname = str(filename)
    if not fname.endswith('.mat') and not fname.endswith('.npz'):
        fname += '.mat'

    p = _resolve_runtime_path(fname)

    frame = inspect.currentframe().f_back
    while frame and frame.f_globals.get('__name__') == __name__:
        frame = frame.f_back

    data = {}
    caller_globals = frame.f_globals if frame else {}
    if not vars:
        runtime_names = set(dir(sys.modules[__name__]))
        internal = {'np', 'plt', 'signal', 'unilab_workspace_ctx', 'unilab_update_ctx', 'ans'}
        for k, v in caller_globals.items():
            if k.startswith('_') or k in internal or k in runtime_names:
                continue
            if inspect.ismodule(v) or inspect.isfunction(v) or inspect.isbuiltin(v) or isinstance(v, type):
                continue
            data[k] = v
    else:
        for v in vars:
            vname = str(v)
            if vname in caller_globals:
                data[vname] = caller_globals[vname]

    _save_safe_dict(p, data)
    print(f"Saved {len(data)} variables to {fname}")


def load(filename, *vars):
    """Loads variables from a .mat or .npz file safely without pickle."""
    fname = str(filename)
    candidates = [fname]
    if not fname.endswith('.mat') and not fname.endswith('.npz'):
        candidates.extend([fname + '.mat', fname + '.npz'])

    p = None
    for cand in candidates:
        resolved = _resolve_runtime_path(cand)
        if resolved.exists():
            p = resolved
            fname = cand
            break

    if p is None:
        p = _resolve_runtime_path(candidates[0])
        if not p.exists():
            raise FileNotFoundError(f"File not found: {filename}")

    data = _load_safe_dict(p)
    if vars:
        wanted = {str(v) for v in vars}
        data = {k: v for k, v in data.items() if k in wanted}

    n_out = _unilab_nargout_ctx.get()
    if n_out is not None and n_out >= 1:
        return data

    frame = inspect.currentframe().f_back
    while frame and frame.f_globals.get('__name__') == __name__:
        frame = frame.f_back
    if frame is not None:
        frame.f_globals.update(data)
    print(f"Loaded {len(data)} variables from {fname}")
    return data

def exit(*args):
    print("Use the 'Quit' button in the application menu to close UniLab.")

def quit(*args):
    print("Use the 'Quit' button in the application menu to close UniLab.")

def clc():
    if os.environ.get('UNILAB_WEB_MODE') == '1' or os.environ.get('UNILAB_API_SERVER') == '1' or os.environ.get('UNILAB_BRIDGE_MODE') == '1':
        print('::CLEAR_TERMINAL::')
    else:
        os.system('cls' if os.name == 'nt' else 'clear')

def pause(n=None):
    """Pauses execution for n seconds or until a key is pressed."""
    # Trigger a workspace update whenever we pause
    cb = unilab_update_ctx.get()
    if cb:
        try:
            cb()
        except:
            pass

    if n is None:
        # MATLAB pause without arguments waits for a keypress
        # In a headless/terminal environment, we just wait a bit or use input()
        # but input() might block the whole process. Let's just sleep a bit.
        time.sleep(0.5)
    else:
        try:
            time.sleep(float(n))
        except:
            pass

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
        'np', 'plt', 'signal', 'unilab_workspace_ctx', 'unilab_update_ctx', '_unilab_3d_data_store',
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
        return "Workspace is empty."

    output = []
    output.append(f"{'Name':<18} {'Size':<15} {'Bytes':<12} {'Class':<15}")
    output.append("-" * 60)
    
    for name in sorted(variables.keys()):
        val = variables[name]
        
        # Get size
        if hasattr(val, 'shape'):
            # Handle numpy arrays and similar
            shape = val.shape
            if not shape: # Scalar array
                size_str = "1x1"
            else:
                size_str = 'x'.join(map(str, shape))
        elif hasattr(val, '__len__') and not isinstance(val, (str, dict)):
            size_str = f"1x{len(val)}"
        else:
            size_str = "1x1"
            
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
            
        output.append(f"{name:<18} {size_str:<15} {bytes_count:<12} {cls:<15}")
    
    return "\n".join(output)

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

def _unilab_to_int(x):
    if isinstance(x, np.ndarray):
        return int(x.item() if x.size == 1 else x.flatten()[0])
    return int(x)

class UnilabEnd:
    """Deferred MATLAB `end` index expression supporting full arithmetic and rounding."""
    def __init__(self, fn_or_offset=0):
        if callable(fn_or_offset):
            self._fn = fn_or_offset
        else:
            off = fn_or_offset
            self._fn = lambda n, _o=off: n + _o

    @staticmethod
    def _eval_operand(other, n):
        if isinstance(other, UnilabEnd):
            return other._fn(n)
        if isinstance(other, np.ndarray) and other.size == 1:
            return other.item()
        return other

    def resolve(self, size: int) -> int:
        return int(self._fn(size))

    @property
    def offset(self) -> int:
        return int(self._fn(0))

    def __add__(self, other):
        return UnilabEnd(lambda n, s=self._fn, o=other: s(n) + UnilabEnd._eval_operand(o, n))

    def __radd__(self, other):
        return UnilabEnd(lambda n, s=self._fn, o=other: UnilabEnd._eval_operand(o, n) + s(n))

    def __sub__(self, other):
        return UnilabEnd(lambda n, s=self._fn, o=other: s(n) - UnilabEnd._eval_operand(o, n))

    def __rsub__(self, other):
        return UnilabEnd(lambda n, s=self._fn, o=other: UnilabEnd._eval_operand(o, n) - s(n))

    def __mul__(self, other):
        return UnilabEnd(lambda n, s=self._fn, o=other: s(n) * UnilabEnd._eval_operand(o, n))

    def __rmul__(self, other):
        return UnilabEnd(lambda n, s=self._fn, o=other: UnilabEnd._eval_operand(o, n) * s(n))

    def __truediv__(self, other):
        return UnilabEnd(lambda n, s=self._fn, o=other: s(n) / UnilabEnd._eval_operand(o, n))

    def __rtruediv__(self, other):
        return UnilabEnd(lambda n, s=self._fn, o=other: UnilabEnd._eval_operand(o, n) / s(n))

    def __floordiv__(self, other):
        return UnilabEnd(lambda n, s=self._fn, o=other: s(n) // UnilabEnd._eval_operand(o, n))

    def __rfloordiv__(self, other):
        return UnilabEnd(lambda n, s=self._fn, o=other: UnilabEnd._eval_operand(o, n) // s(n))

    def __mod__(self, other):
        return UnilabEnd(lambda n, s=self._fn, o=other: s(n) % UnilabEnd._eval_operand(o, n))

    def __rmod__(self, other):
        return UnilabEnd(lambda n, s=self._fn, o=other: UnilabEnd._eval_operand(o, n) % s(n))

    def __neg__(self):
        return UnilabEnd(lambda n, s=self._fn: -s(n))

    def __pos__(self):
        return self

    def __floor__(self):
        return UnilabEnd(lambda n, s=self._fn: math.floor(s(n)))

    def __ceil__(self):
        return UnilabEnd(lambda n, s=self._fn: math.ceil(s(n)))

    def __round__(self, ndigits=None):
        return UnilabEnd(lambda n, s=self._fn, d=ndigits: builtins.round(s(n), d) if d is not None else builtins.round(s(n)))

    def __repr__(self):
        return "unilab_end"


unilab_end = UnilabEnd()

def unilab_range(start, stop, step=1):
    if isinstance(start, UnilabEnd) or isinstance(stop, UnilabEnd) or isinstance(step, UnilabEnd):
        return slice(start, stop, step)
    # Standard numerical range
    eps_val = step * 1e-10
    return np.atleast_2d(np.arange(start, stop + eps_val, step))


def _unilab_resolve_idx(idx, size):
    if isinstance(idx, UnilabEnd):
        return idx.resolve(size) - 1
    if idx is None: return None
    if isinstance(idx, np.ndarray) and idx.size == 1:
        return int(idx.item()) - 1
    return int(idx) - 1

def _unilab_resolve_slice(slc, size):
    if not isinstance(slc, slice): return slc
    start = _unilab_resolve_idx(slc.start, size) if slc.start is not None else 0
    stop = _unilab_resolve_idx(slc.stop, size) + 1 if slc.stop is not None else size
    if isinstance(slc.step, UnilabEnd):
        step = slc.step.resolve(size)
    else:
        step = int(slc.step) if slc.step is not None else 1
    return slice(start, stop, step)

class UnilabHandle:
    def __init__(self, func):
        self.func = func
    def __call__(self, *args, **kwargs):
        if isinstance(self.func, str):
            return unilab_execute_file(self.func, *args, **kwargs)
        return self.func(*args, **kwargs)
    def __repr__(self):
        return f"<function handle: {self.func}>"

def unilab_execute_file(path, *args, **kwargs):
    p_str = str(path)
    candidates = [p_str]
    if not p_str.endswith('.m'):
        candidates.append(p_str + '.m')

    full_path = None
    for cand in candidates:
        resolved = _resolve_runtime_path(cand)
        if resolved.exists():
            full_path = resolved
            break

    if full_path is not None and full_path.exists():
        content = full_path.read_text(encoding='utf-8')
        from backend.core.transpiler_core import UniLabTranspiler
        transpiler = UniLabTranspiler()
        py_code, _, _ = transpiler.transpile(content)
        exec_globals = globals().copy()
        exec(py_code, exec_globals)
        stem = full_path.stem
        if stem in exec_globals and callable(exec_globals[stem]):
            return exec_globals[stem](*args, **kwargs)
        return exec_globals.get('ans', None)
    return None

def unilab_handle(func):
    if isinstance(func, UnilabHandle): return func
    return UnilabHandle(func)


def unilab_call_nargout(nargout, obj, *args, **kwargs):
    if callable(obj):
        if len(args) == 0 and len(kwargs) == 0 and isinstance(obj, UnilabHandle):
            return obj
            
        token = _unilab_nargout_ctx.set(nargout)
        try:
            import builtins
            try:
                name = getattr(obj, '__name__', None)
                if name == 'abs' or obj == builtins.abs: res = unilab_abs(*args, **kwargs)
                elif name == 'round' or obj == builtins.round: res = round(*args, **kwargs)
                elif name == 'min' or obj == builtins.min: res = unilab_min(*args, **kwargs)
                elif name == 'max' or obj == builtins.max: res = unilab_max(*args, **kwargs)
                elif name == 'sum' or obj == builtins.sum: res = unilab_sum(*args, **kwargs)
                elif name == 'any' or obj == builtins.any: res = unilab_any(*args, **kwargs)
                elif name == 'all' or obj == builtins.all: res = unilab_all(*args, **kwargs)
                elif name == 'real': res = np.real(*args, **kwargs)
                elif name == 'imag': res = np.imag(*args, **kwargs)
                else:
                    res = obj(*args, **kwargs)
            except Exception as e:
                # If it's already a UniLab error or we want to pass it up with more info
                if hasattr(obj, '__name__'):
                    func_name = obj.__name__
                elif hasattr(obj, '__class__'):
                    func_name = obj.__class__.__name__
                else:
                    func_name = "unknown function"
                
                # Check for common Scipy/Numpy errors and give better hints
                err_msg = str(e)
                if "T must be a rank-1 array" in err_msg:
                    raise ValueError(f"Error in '{func_name}': Time vector T must be a 1D array (vector).") from e
                if "Denominator polynomial must be rank-1 array" in err_msg:
                    raise ValueError(f"Error in '{func_name}': Denominator must be a vector of coefficients.") from e
                if "Numerator polynomial must be rank-1 array" in err_msg:
                    raise ValueError(f"Error in '{func_name}': Numerator must be a vector of coefficients.") from e
                if "must be at least as long as the numerator" in err_msg:
                    raise ValueError(f"Error in '{func_name}': System must be proper (denominator degree >= numerator degree).") from e
                if "takes" in err_msg and "positional argument" in err_msg:
                    raise TypeError(f"Error in '{func_name}': Incorrect number of arguments. {err_msg}") from e
                
                # Re-raise with function name context if not already present
                if func_name not in err_msg:
                    raise type(e)(f"Error in '{func_name}': {err_msg}") from e
                raise
        finally:
            _unilab_nargout_ctx.reset(token)
            
        if nargout <= 1:
            if isinstance(res, (tuple, list)) and len(res) > 0 and hasattr(obj, '__name__') and obj.__name__ in ('eig', 'svd', 'min', 'max', 'sort'):
                return res[0]
            if isinstance(res, tuple) and len(res) > 0:
                return res[0]
            return res
            
        # For nargout > 1
        if isinstance(res, (tuple, list)):
            res_list = list(res)
            # Ensure we return exactly nargout values
            if len(res_list) >= nargout:
                return tuple(res_list[:nargout])
            else:
                return tuple(res_list + [None] * (nargout - len(res_list)))
        else:
            # Function returned a scalar but nargout > 1 requested
            return tuple([res] + [None] * (nargout - 1))
    return unilab_call(obj, *args, **kwargs)

def angle(x):
    return np.angle(x)

_unilab_nargout_ctx = ContextVar('unilab_nargout', default=None)

def unilab_call(obj, *args, **kwargs):
    if obj is None:
        if len(args) > 0 or len(kwargs) > 0:
            # We don't have the variable name here easily, but we can try to be helpful
            raise NameError("Attempted to call an undefined variable or function")
        return None
        
    if callable(obj):
        # Avoid auto-calling handles if no args given
        if len(args) == 0 and len(kwargs) == 0 and isinstance(obj, UnilabHandle):
            return obj
            
        # Set nargout=1 for nested calls (default in UniLab/MATLAB)
        token = _unilab_nargout_ctx.set(1)
        try:
            # Handle built-in functions that might be passed (e.g. Python's abs vs UniLab's abs)
            import builtins
            # Check by name and identity to be absolutely sure
            try:
                name = getattr(obj, '__name__', None)
                if name == 'abs' or obj == builtins.abs: res = unilab_abs(*args, **kwargs)
                elif name == 'round' or obj == builtins.round: res = round(*args, **kwargs)
                elif name == 'min' or obj == builtins.min: res = unilab_min(*args, **kwargs)
                elif name == 'max' or obj == builtins.max: res = unilab_max(*args, **kwargs)
                elif name == 'sum' or obj == builtins.sum: res = unilab_sum(*args, **kwargs)
                elif name == 'any' or obj == builtins.any: res = unilab_any(*args, **kwargs)
                elif name == 'all' or obj == builtins.all: res = unilab_all(*args, **kwargs)
                elif name == 'real': res = np.real(*args, **kwargs)
                elif name == 'imag': res = np.imag(*args, **kwargs)
                else:
                    res = obj(*args, **kwargs)
            except Exception as e:
                if hasattr(obj, '__name__'):
                    func_name = obj.__name__
                elif hasattr(obj, '__class__'):
                    func_name = obj.__class__.__name__
                else:
                    func_name = "unknown function"
                
                err_msg = str(e)
                if "T must be a rank-1 array" in err_msg:
                    raise ValueError(f"Error in '{func_name}': Time vector T must be a 1D array (vector).") from e
                if "Denominator polynomial must be rank-1 array" in err_msg:
                    raise ValueError(f"Error in '{func_name}': Denominator must be a vector of coefficients.") from e
                if "Numerator polynomial must be rank-1 array" in err_msg:
                    raise ValueError(f"Error in '{func_name}': Numerator must be a vector of coefficients.") from e
                if "must be at least as long as the numerator" in err_msg:
                    raise ValueError(f"Error in '{func_name}': System must be proper (denominator degree >= numerator degree).") from e
                if "takes" in err_msg and "positional argument" in err_msg:
                    raise TypeError(f"Error in '{func_name}': Incorrect number of arguments. {err_msg}") from e
                
                if func_name not in err_msg:
                    raise type(e)(f"Error in '{func_name}': {err_msg}") from e
                raise
        finally:
            _unilab_nargout_ctx.reset(token)
            
        if isinstance(res, tuple) and len(res) > 0:
            return res[0]
        return res
    
    # If not callable but called with no args, it might be a variable being accessed like a func (MATLAB style)
    if len(args) == 0 and len(kwargs) == 0: return obj
    
    # Handle array/list/string indexing
    if len(args) == 1:
        idx = args[0]
        if isinstance(obj, np.ndarray):
            # Logical indexing
            if isinstance(idx, np.ndarray) and idx.dtype == bool:
                if obj.ndim == 1 or (obj.ndim == 2 and (obj.shape[0] == 1 or obj.shape[1] == 1)):
                    flat_obj = obj.flatten()
                    flat_mask = idx.flatten()
                    res = flat_obj[flat_mask]
                    if res.size == 1: return res.item()
                    if obj.ndim == 2 and obj.shape[1] == 1:
                        return res.reshape(-1, 1)
                    if obj.ndim == 2 and obj.shape[0] == 1:
                        return res.reshape(1, -1)
                    return res
                try:
                    res = obj[idx]
                except (IndexError, ValueError):
                    res = obj.flatten()[idx.flatten()]
                if res.size == 1: return res.item()
                if res.ndim == 1:
                    if obj.ndim == 2 and obj.shape[1] == 1:
                        return res.reshape(-1, 1)
                    if obj.ndim == 2 and obj.shape[0] == 1:
                        return res.reshape(1, -1)
                return res
            
            if isinstance(idx, UnilabEnd):
                flat = obj.flatten()
                return flat[idx.resolve(len(flat)) - 1]
                
            flat = obj.flatten()
            # Scalar indexing
            try:
                if isinstance(idx, (int, np.integer, float, np.floating, np.ndarray)) and np.asarray(idx).size == 1:
                    return flat[int(np.asarray(idx).item()) - 1]
            except:
                pass

            if isinstance(idx, (list, np.ndarray, slice)): 
                if isinstance(idx, slice):
                    if idx == slice(None): return flat.reshape(-1, 1)
                    res = flat[_unilab_resolve_slice(idx, flat.size)]
                else:
                    try:
                        indices = np.asarray(idx).flatten().astype(int) - 1
                        res = flat[indices]
                    except:
                        # Fallback for complex indices or nested sequences
                        res = flat[np.atleast_1d(idx).astype(int) - 1]
                        
                if isinstance(res, np.ndarray) and res.size == 1: return res.item()
                if isinstance(res, np.ndarray) and res.ndim == 1: 
                    # Try to maintain orientation if original was column vector
                    if (obj.ndim == 2 and obj.shape[1] == 1):
                        return res.reshape(-1, 1)
                    if (obj.ndim == 2 and obj.shape[0] == 1):
                        return res.reshape(1, -1)
                    return res
                return res
        if isinstance(obj, (list, tuple, str)):
            if isinstance(idx, UnilabEnd):
                return obj[idx.resolve(len(obj)) - 1]
            try:
                # Scalar indexing
                if isinstance(idx, (int, np.integer, float, np.floating, np.ndarray)) and np.asarray(idx).size == 1:
                    return obj[int(np.asarray(idx).item()) - 1]
            except:
                pass
            if isinstance(idx, slice): return obj[_unilab_resolve_slice(idx, len(obj))]
            if isinstance(idx, (list, np.ndarray)):
                indices = (np.asarray(idx).astype(int) - 1).tolist()
                res = [obj[i] for i in indices]
                return "".join(res) if isinstance(obj, str) else res
            
    # Ensure obj has shape if we're indexing it
    indexing_obj = obj
    if not hasattr(indexing_obj, 'shape'):
        indexing_obj = np.asarray(indexing_obj)
    if np.isscalar(indexing_obj) or (isinstance(indexing_obj, np.ndarray) and indexing_obj.ndim == 0):
        indexing_obj = np.atleast_2d(indexing_obj)
        
    processed = []
    for i, arg in enumerate(args):
        if isinstance(arg, UnilabEnd):
            processed.append(arg.resolve(indexing_obj.shape[i]) - 1)
        elif isinstance(arg, slice):
            processed.append(_unilab_resolve_slice(arg, indexing_obj.shape[i]))
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
        res = obj[tuple(processed)]
    except (TypeError, IndexError, ValueError):
        # Scalar indexing (MATLAB allows indexing into scalars as 1x1 matrices)
        if np.isscalar(obj) or (isinstance(obj, np.ndarray) and obj.ndim == 0):
            res = np.atleast_2d(obj)[tuple(processed)]
        elif isinstance(obj, np.ndarray) and obj.size == 0:
            return np.array([])
        else:
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

def unilab_transpose(x):
    if isinstance(x, (list, tuple)):
        x = np.asarray(x)
    if isinstance(x, np.ndarray):
        if x.ndim == 1:
            return x.reshape(-1, 1).conj()
        return x.T.conj()
    if isinstance(x, (complex, np.complexfloating)):
        return np.conj(x)
    return x


def unilab_array_transpose(x):
    """Non-conjugate transpose (MATLAB `.'` operator)."""
    if isinstance(x, (list, tuple)):
        x = np.asarray(x)
    if isinstance(x, np.ndarray):
        if x.ndim == 1:
            return x.reshape(-1, 1)
        return np.swapaxes(np.atleast_2d(x), -2, -1)
    return x


def unilab_switch_match(sw_val, case_expr) -> bool:
    """MATLAB switch/case matcher supporting cell cases `case {'a', 'b'}` and safe array/string equality."""
    if isinstance(case_expr, (list, tuple)):
        return builtins.any(unilab_switch_match(sw_val, item) for item in case_expr)
    if isinstance(case_expr, np.ndarray) and case_expr.dtype == object:
        return builtins.any(unilab_switch_match(sw_val, item) for item in case_expr.flatten().tolist())
    if isinstance(sw_val, str) or isinstance(case_expr, str):
        return isinstance(sw_val, str) and isinstance(case_expr, str) and sw_val == case_expr
    if isinstance(sw_val, np.ndarray) or isinstance(case_expr, np.ndarray):
        try:
            return bool(np.array_equal(sw_val, case_expr))
        except Exception:
            return False
    try:
        return bool(sw_val == case_expr)
    except Exception:
        return False


def unilab_cell_get(cell_obj, *args):
    """MATLAB curly-brace cell indexing `C{idx}` returning unpacked element(s)."""
    if cell_obj is None:
        raise NameError("Attempted to index into an undefined cell array")
    if not args:
        return cell_obj
    if isinstance(cell_obj, (list, tuple)):
        idx = args[0]
        if isinstance(idx, slice):
            return cell_obj[_unilab_resolve_slice(idx, len(cell_obj))]
        r_idx = _unilab_resolve_idx(idx, len(cell_obj))
        return cell_obj[r_idx]
    if isinstance(cell_obj, np.ndarray):
        if len(args) == 1:
            idx = args[0]
            flat = cell_obj.flatten(order='F') if cell_obj.ndim >= 2 else cell_obj.flatten()
            if isinstance(idx, slice):
                return flat[_unilab_resolve_slice(idx, flat.size)].tolist()
            r_idx = _unilab_resolve_idx(idx, flat.size)
            return flat[r_idx]
        coords = []
        for dim_i, arg in enumerate(args):
            dim_sz = cell_obj.shape[dim_i] if dim_i < cell_obj.ndim else 1
            if isinstance(arg, slice):
                coords.append(_unilab_resolve_slice(arg, dim_sz))
            else:
                coords.append(_unilab_resolve_idx(arg, dim_sz))
        return cell_obj[tuple(coords)]
    return unilab_call(cell_obj, *args)


def unilab_cell_set(cell_obj, val, *args):
    """MATLAB curly-brace cell assignment `C{idx} = val`."""
    if not args:
        return val
    if isinstance(cell_obj, list):
        if len(args) == 1:
            r_idx = _unilab_resolve_idx(args[0], len(cell_obj))
            if r_idx >= len(cell_obj):
                cell_obj.extend([None] * (r_idx - len(cell_obj) + 1))
            cell_obj[r_idx] = val
            return cell_obj
    if cell_obj is None:
        if len(args) == 1:
            r_idx = _unilab_resolve_idx(args[0], 0)
            arr = np.full((1, r_idx + 1), None, dtype=object)
            arr[0, r_idx] = val
            return arr
        shape = tuple(_unilab_resolve_idx(a, 0) + 1 for a in args)
        arr = np.full(shape, None, dtype=object)
        arr[tuple(s - 1 for s in shape)] = val
        return arr

    if not isinstance(cell_obj, np.ndarray) or cell_obj.dtype != object:
        arr = np.empty(np.shape(cell_obj) or (1, 1), dtype=object)
        arr[...] = cell_obj
        cell_obj = arr

    if len(args) == 1:
        idx = args[0]
        if isinstance(idx, slice):
            slc = _unilab_resolve_slice(idx, cell_obj.size)
            cell_obj.flat[slc] = val
            return cell_obj
        r_idx = _unilab_resolve_idx(idx, cell_obj.size)
        if r_idx >= cell_obj.size:
            pad_len = r_idx - cell_obj.size + 1
            if cell_obj.ndim == 2 and cell_obj.shape[0] <= 1:
                new_arr = np.full((1, cell_obj.size + pad_len), None, dtype=object)
                if cell_obj.size > 0:
                    new_arr[0, :cell_obj.size] = cell_obj.flatten()
                cell_obj = new_arr
            else:
                new_arr = np.full((cell_obj.size + pad_len, 1), None, dtype=object)
                if cell_obj.size > 0:
                    new_arr[:cell_obj.size, 0] = cell_obj.flatten()
                cell_obj = new_arr
        cell_obj.flat[r_idx] = val
        return cell_obj

    coords = []
    req_shape = list(cell_obj.shape)
    while len(req_shape) < len(args):
        req_shape.append(1)
    need_grow = False
    for dim_i, arg in enumerate(args):
        if isinstance(arg, slice):
            coords.append(_unilab_resolve_slice(arg, req_shape[dim_i]))
        else:
            c = _unilab_resolve_idx(arg, req_shape[dim_i])
            coords.append(c)
            if c >= req_shape[dim_i]:
                req_shape[dim_i] = c + 1
                need_grow = True
    if need_grow:
        grown = np.full(tuple(req_shape), None, dtype=object)
        old_slices = tuple(slice(0, s) for s in cell_obj.shape)
        grown[old_slices] = cell_obj
        cell_obj = grown
    cell_obj[tuple(coords)] = val
    return cell_obj


def unilab_set_nested(root_obj, steps, val):
    """Recursive setter for arbitrary nested struct/index/cell LHS chains (`s.field(1)=5`, `s.a.b=1`, `folds(i).train=idx`)."""
    if not steps:
        return val
    kind, payload = steps[0]
    rest = steps[1:]

    if not rest:
        if kind == 'attr':
            return unilab_set_attr(root_obj, payload, val)
        if kind == 'cell':
            return unilab_cell_set(root_obj, val, *payload)
        if kind == 'call':
            return unilab_set(root_obj, val, *payload)
        return val

    next_kind = rest[0][0]
    if kind == 'attr':
        if root_obj is None:
            root_obj = {}
        cur_child = unilab_get(root_obj, payload)
        new_child = unilab_set_nested(cur_child, rest, val)
        return unilab_set_attr(root_obj, payload, new_child)

    if kind == 'cell':
        cur_child = None
        if root_obj is not None:
            try:
                cur_child = unilab_cell_get(root_obj, *payload)
            except Exception:
                cur_child = None
        new_child = unilab_set_nested(cur_child, rest, val)
        return unilab_cell_set(root_obj, new_child, *payload)

    if kind == 'call':
        # e.g. folds(i).train = idx (struct array) or arr(i)...
        if next_kind == 'attr':
            if root_obj is None or (isinstance(root_obj, np.ndarray) and root_obj.size == 0):
                root_obj = np.empty((1, 0), dtype=object)
            elif isinstance(root_obj, dict) or isinstance(root_obj, UnilabStruct):
                arr = np.empty((1, 1), dtype=object)
                arr[0, 0] = root_obj
                root_obj = arr
            if isinstance(root_obj, np.ndarray) and root_obj.dtype == object and len(payload) == 1:
                r_idx = _unilab_resolve_idx(payload[0], root_obj.size)
                if r_idx >= root_obj.size:
                    grown = np.empty((1, r_idx + 1), dtype=object)
                    for k in range(r_idx + 1):
                        if k < root_obj.size and root_obj.flat[k] is not None:
                            grown[0, k] = root_obj.flat[k]
                        else:
                            grown[0, k] = {}
                    root_obj = grown
                cur_elem = root_obj.flat[r_idx]
                if cur_elem is None:
                    cur_elem = {}
                root_obj.flat[r_idx] = unilab_set_nested(cur_elem, rest, val)
                return root_obj
        cur_child = None
        if root_obj is not None:
            try:
                cur_child = unilab_call(root_obj, *payload)
            except Exception:
                cur_child = None
        new_child = unilab_set_nested(cur_child, rest, val)
        return unilab_set(root_obj, new_child, *payload)

    return root_obj

def unilab_mul(a, b):
    # Ensure we are not dealing with Python lists/tuples in a way that causes "multiply sequence"
    if isinstance(a, (list, tuple)): a = np.asarray(a)
    if isinstance(b, (list, tuple)): b = np.asarray(b)
    
    # In MATLAB, * is matrix multiplication, but if either is a scalar, it's element-wise.
    a_is_scalar = np.isscalar(a) or (hasattr(a, 'ndim') and a.ndim == 0)
    b_is_scalar = np.isscalar(b) or (hasattr(b, 'ndim') and b.ndim == 0)

    if a_is_scalar or b_is_scalar:
        res = a * b
    else:
        try:
            # Matrix multiplication
            if a.ndim == 2 and a.shape[1] == 1 and b.ndim == 1 and a.shape[0] == b.shape[0]:
                res = np.matmul(a, b.reshape(1, -1))
            else:
                res = np.matmul(a, b)
        except (ValueError, TypeError):
            # Fallback for 1x1 matrices which MATLAB often treats as scalars for *
            if a.size == 1 or b.size == 1:
                res = a * b
            elif a.ndim == 2 and a.shape[1] == 1 and b.ndim == 1 and a.shape[0] == b.shape[0]:
                res = np.matmul(a, b.reshape(1, -1))
            else:
                # Re-raise to avoid silent broadcasting bugs
                raise

    if isinstance(res, np.ndarray) and res.size == 1:
        return res.item()
    return res

def unilab_dot_mul(a, b):
    if isinstance(a, (list, tuple)): a = np.asarray(a)
    if isinstance(b, (list, tuple)): b = np.asarray(b)
    res = a * b
    if isinstance(res, np.ndarray) and res.size == 1:
        return res.item()
    return res

def unilab_div(a, b):
    if isinstance(a, (list, tuple)): a = np.asarray(a)
    if isinstance(b, (list, tuple)): b = np.asarray(b)
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
    if isinstance(a, (list, tuple)): a = np.asarray(a)
    if isinstance(b, (list, tuple)): b = np.asarray(b)
    res = a / b
    if isinstance(res, np.ndarray) and res.size == 1:
        return res.item()
    return res

def unilab_ldiv(a, b):
    if isinstance(a, (list, tuple)): a = np.asarray(a)
    if isinstance(b, (list, tuple)): b = np.asarray(b)
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
    if isinstance(a, (list, tuple)): a = np.asarray(a)
    if isinstance(b, (list, tuple)): b = np.asarray(b)
    res = b / a
    if isinstance(res, np.ndarray) and res.size == 1:
        return res.item()
    return res

def unilab_pow(a, b):
    if isinstance(a, (list, tuple)): a = np.asarray(a)
    if isinstance(b, (list, tuple)): b = np.asarray(b)
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
    if isinstance(a, (list, tuple)): a = np.asarray(a)
    if isinstance(b, (list, tuple)): b = np.asarray(b)
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
        return a < b # SymPy supports this for symbolic expr
    return a < b

def unilab_gt(a, b):
    if _is_symbolic(a) or _is_symbolic(b):
        return a > b
    return a > b

def unilab_le(a, b):
    if _is_symbolic(a) or _is_symbolic(b):
        return a <= b
    return a <= b

def unilab_ge(a, b):
    if _is_symbolic(a) or _is_symbolic(b):
        return a >= b
    return a >= b

class UnilabStruct:
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)
    def __repr__(self):
        fields = ", ".join([f"{k}: {repr(v)}" for k, v in self.__dict__.items()])
        return f"struct({fields})"

def unilab_get_undefined(name, globals_dict):
    if globals_dict and name in globals_dict:
        return globals_dict[name]
    return None

def unilab_set_attr(obj, attr, val, globals_dict=None):
    if obj is None:
        obj = UnilabStruct()
    
    if isinstance(obj, UnilabStruct):
        setattr(obj, attr, val)
    elif isinstance(obj, dict):
        obj[attr] = val
    else:
        try:
            setattr(obj, attr, val)
        except (AttributeError, TypeError):
            # Fallback: convert to struct if possible? 
            # In MATLAB, if you do x.a = 1 and x was a double, it might error or convert.
            pass
    return obj

def unilab_get(obj, attr):
    if obj is None:
        return None
    if isinstance(obj, dict):
        return obj.get(attr)
    
    # Handle UnilabStruct explicitly
    if isinstance(obj, UnilabStruct):
        return getattr(obj, attr, None)

    try:
        return getattr(obj, attr)
    except AttributeError:
        # Check if it's a common property we want to support
        if attr == 'shape' and isinstance(obj, (list, tuple)):
            return (1, len(obj))
        return None

def log10(x): return np.log10(x)

def unilab_mean(x, axis=None):
    """MATLAB-compatible mean() function."""
    x_arr = np.asarray(x)
    if axis is not None:
        if isinstance(axis, (int, float, np.integer, np.floating)):
            axis = int(axis) - 1
    elif x_arr.ndim > 1:
        # MATLAB default mean is along first non-singleton dimension
        axis = 0
        for i, d in enumerate(x_arr.shape):
            if d > 1: axis = i; break
            
    keep = (x_arr.ndim >= 2 and axis is not None)
    res = np.mean(x_arr, axis=axis, keepdims=keep)
    if hasattr(res, 'item') and res.size == 1 and not keep:
        return res.item()
    return res

def unilab_median(x, axis=None):
    """MATLAB-compatible median() function."""
    x_arr = np.asarray(x)
    if axis is not None:
        if isinstance(axis, (int, float, np.integer, np.floating)):
            axis = int(axis) - 1
    elif x_arr.ndim > 1:
        axis = 0
        for i, d in enumerate(x_arr.shape):
            if d > 1: axis = i; break
    res = np.median(x_arr, axis=axis)
    if hasattr(res, 'item') and res.size == 1:
        return res.item()
    return res

def unilab_quantile(x, p, axis=None):
    """MATLAB-compatible quantile() function."""
    x_arr = np.asarray(x)
    p_arr = np.asarray(p)
    if axis is not None:
        if isinstance(axis, (int, float, np.integer, np.floating)):
            axis = int(axis) - 1
    elif x_arr.ndim > 1:
        axis = 0
        for i, d in enumerate(x_arr.shape):
            if d > 1: axis = i; break
    # MATLAB quantile takes p in [0, 1], NumPy quantile also does (since version 1.15)
    res = np.quantile(x_arr, p_arr, axis=axis)
    if hasattr(res, 'item') and res.size == 1:
        return res.item()
    return res

def unilab_set(obj, val, *args):
    if len(args) == 1 and isinstance(args[0], str):
        # Property set
        attr = args[0]
        if obj is None:
            obj = {}
        if isinstance(obj, dict):
            obj[attr] = val
            return obj
        try:
            setattr(obj, attr, val)
            return obj
        except:
            return obj
    
    if obj is None:
        if len(args) == 1:
            r_idx = _unilab_resolve_idx(args[0], 0)
            obj = np.zeros((1, max(1, r_idx + 1)))
        elif len(args) > 1:
            shape = tuple(max(1, _unilab_resolve_idx(a, 0) + 1) for a in args)
            obj = np.zeros(shape)

    if len(args) == 1:
        idx = args[0]
        # Flatten boolean masks for consistent indexing
        if isinstance(idx, (bool, np.bool_)):
            if not idx: return obj
            idx_adj = 0
        elif isinstance(idx, np.ndarray) and idx.dtype == bool:
            if not np.any(idx): return obj
            idx_adj = idx.flatten()
        else:
            if isinstance(idx, UnilabEnd):
                idx_adj = idx.resolve(len(obj.flatten()) if isinstance(obj, np.ndarray) else len(obj)) - 1
            elif isinstance(idx, (list, np.ndarray)):
                idx_adj = np.asarray(idx).astype(int) - 1
            elif isinstance(idx, slice):
                idx_adj = _unilab_resolve_slice(idx, obj.size if isinstance(obj, np.ndarray) else len(obj))
            else:
                idx_adj = int(idx)-1 if isinstance(idx, (int, np.integer, float, np.floating)) else idx
            
        if isinstance(obj, np.ndarray):
            v_val = val
            # Handle size-1 values (arrays, lists, tuples) by converting to scalar
            if hasattr(val, '__len__') or isinstance(val, np.ndarray):
                if np.size(val) == 1:
                    try:
                        if isinstance(val, np.ndarray): v_val = val.item()
                        elif isinstance(val, (list, tuple)): v_val = val[0]
                        else: v_val = float(val)
                    except: pass
                
            # Handle automatic array expansion
            try:
                max_idx = builtins.max(idx_adj) if isinstance(idx_adj, (list, np.ndarray)) else (idx_adj.stop if isinstance(idx_adj, slice) and idx_adj.stop else idx_adj)
                if max_idx is not None and max_idx >= obj.size:
                    # Need to pad
                    pad_len = int(max_idx - obj.size + 1)
                    # Pad along the longest dimension to maintain row/col vector shape
                    if obj.ndim == 2:
                        if obj.shape[0] == 1:
                            obj = np.pad(obj, ((0, 0), (0, pad_len)), mode='constant')
                        else:
                            obj = np.pad(obj, ((0, pad_len), (0, 0)), mode='constant')
                    else:
                        obj = np.pad(obj, (0, pad_len), mode='constant')
            except:
                pass
            
            # Promotion to complex if assigning complex to real array
            if (np.iscomplexobj(v_val) or np.iscomplexobj(val)) and not np.iscomplexobj(obj):
                obj = obj.astype(complex)
                
            try:
                if isinstance(idx_adj, (int, np.integer)):
                    obj.flat[int(idx_adj)] = v_val
                else:
                    obj.flat[idx_adj] = v_val
            except (IndexError, ValueError, TypeError):
                try:
                    if isinstance(idx_adj, (slice, list, np.ndarray)):
                        v_arr = np.atleast_1d(v_val)
                        if v_arr.size == 1:
                            obj.flat[idx_adj] = v_arr.item()
                        else:
                            obj.flat[idx_adj] = v_arr.flatten()
                    else:
                        obj.flat[idx_adj] = v_val
                except:
                    # Last resort: try to broadcast/reshape
                    try:
                        v_arr = np.asarray(v_val)
                        if v_arr.size == 1:
                            obj.flat[idx_adj] = v_arr.item()
                        else:
                            obj.flat[idx_adj] = v_arr.flatten()
                    except Exception as final_err:
                        # If it still fails, raise a more descriptive error
                        raise ValueError(f"Failed to set value at index {idx_adj}: {final_err}")
            return obj
        
        # Handle list expansion (for cell arrays and varargout)
        if isinstance(obj, list):
            if isinstance(idx_adj, (int, np.integer)):
                if idx_adj >= len(obj):
                    obj.extend([None] * (int(idx_adj) - len(obj) + 1))
                obj[int(idx_adj)] = val
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
        if isinstance(obj, np.ndarray):
            req_shape = list(obj.shape)
            while len(req_shape) < len(args):
                req_shape.append(1)
            need_grow = False
            for dim_i, arg in enumerate(args):
                if isinstance(arg, (int, np.integer, float, np.floating)) or (isinstance(arg, np.ndarray) and arg.size == 1 and arg.dtype != bool):
                    c = int(np.asarray(arg).item()) - 1
                    if c >= req_shape[dim_i]:
                        req_shape[dim_i] = c + 1
                        need_grow = True
            if need_grow:
                if len(obj.shape) < len(req_shape):
                    obj = obj.reshape(tuple(list(obj.shape) + [1] * (len(req_shape) - len(obj.shape))))
                grown = np.zeros(tuple(req_shape), dtype=obj.dtype)
                if obj.size > 0:
                    old_slices = tuple(slice(0, s) for s in obj.shape)
                    grown[old_slices] = obj
                obj = grown

        processed = []
        for i, arg in enumerate(args):
            if isinstance(arg, UnilabEnd):
                processed.append(arg.resolve(obj.shape[i]) - 1)
            elif isinstance(arg, slice):
                processed.append(_unilab_resolve_slice(arg, obj.shape[i]))
            elif isinstance(arg, (int, np.integer, float, np.floating, np.ndarray)) and np.asarray(arg).size == 1:
                processed.append(int(np.asarray(arg).item()) - 1)
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
        
        # Promotion to complex if assigning complex to real array
        if isinstance(obj, np.ndarray) and (np.iscomplexobj(val) or np.iscomplexobj(v_val if 'v_val' in locals() else None)) and not np.iscomplexobj(obj):
            obj = obj.astype(complex)
                    
        try:
            obj[tuple(processed)] = val
        except (TypeError, ValueError, IndexError):
            if not hasattr(obj, '__setitem__'):
                # Promote to array to handle scalar indexing
                obj = np.atleast_2d(obj)
                return unilab_set(obj, val, *args)
            
            try:
                # Common case: assigning a column vector to a row slice or vice versa
                v_arr = np.asarray(val)
                target_shape = np.empty(obj.shape)[tuple(processed)].shape
                if v_arr.size == np.prod(target_shape):
                    obj[tuple(processed)] = v_arr.reshape(target_shape)
                else:
                    obj[tuple(processed)] = v_arr
            except:
                # Final fallback: direct assignment might still work if types were the issue
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
                non_empty = [r for r in items if np.asarray(r).size > 0]
                if not non_empty:
                    return np.empty((0, 0))
                # Only treat 1D arrays as column vectors if every item has the same length > 1
                all_1d_same_len = (
                    builtins.len(non_empty) > 1
                    and builtins.all(
                        (isinstance(r, np.ndarray) and r.ndim == 1)
                        or (isinstance(r, np.ndarray) and r.ndim == 2 and r.shape[0] > 1)
                        for r in non_empty
                    )
                    and len({r.shape[0] for r in non_empty if isinstance(r, np.ndarray) and r.ndim >= 1}) == 1
                )
                processed = []
                for r in non_empty:
                    if all_1d_same_len and isinstance(r, np.ndarray) and r.ndim == 1:
                        processed.append(r.reshape(-1, 1))
                    else:
                        processed.append(np.atleast_2d(r))
                res = np.hstack(processed)
                target_dtype = np.complex128 if np.iscomplexobj(res) else np.float64
                return res.astype(target_dtype)
            except Exception:
                try:
                    row_parts = [np.atleast_2d(np.asarray(r).flatten()) for r in items if np.asarray(r).size > 0]
                    res = np.hstack(row_parts)
                    target_dtype = np.complex128 if np.iscomplexobj(res) else np.float64
                    return res.astype(target_dtype)
                except Exception:
                    return np.array(items, dtype=object)

        # Check for MATLAB-style string concatenation ['abc', 'def'] -> 'abcdef'
        if builtins.all(isinstance(r, (str, np.str_)) for r in items):
            return "".join(str(r) for r in items)

        res = np.atleast_2d(items)
        target_dtype = np.complex128 if np.iscomplexobj(res) else np.float64
        return res.astype(target_dtype)

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

        # Use complex if any row is complex
        res = np.vstack(processed_rows)
        target_dtype = np.complex128 if np.iscomplexobj(res) else np.float64
        return res.astype(target_dtype)
    except:
        # Fallback
        if builtins.all(isinstance(r, (str, np.str_)) for r in rows):
            return "".join(str(r) for r in rows)
        try:
            arr = np.array(rows)
            target_dtype = np.complex128 if np.iscomplexobj(arr) else np.float64
            return arr.astype(target_dtype)
        except:
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
    elif isinstance(outputs, (list, np.ndarray, tuple)):
        # varargout was the only return or a single tuple
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
    if _is_symbolic(n):
        import sympy
        return sympy.factorial(n)
    from math import factorial as f
    if isinstance(n, (np.ndarray, list, tuple)):
        arr = np.asarray(n)
        vec = np.vectorize(lambda k: float(f(int(k))))
        return vec(arr)
    return float(f(int(n)))

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
    if not isinstance(condition, np.ndarray):
        condition = np.asarray(condition)
        
    n_out = unilab_get_nargout()
    
    if n_out <= 1:
        # Linear indices
        indices = np.where(condition.flatten())[0] + 1
        if k is not None:
            k = int(k)
            indices = indices[:k] if direction == 'first' else indices[-k:]
        return indices.reshape(1, -1) if indices.size > 0 else np.array([])

    # Multiple outputs: [row, col] or [row, col, val]
    rows, cols = np.where(condition)
    rows += 1 # 1-based
    cols += 1
    
    if k is not None:
        k = int(k)
        if direction == 'first':
            rows, cols = rows[:k], cols[:k]
        else:
            rows, cols = rows[-k:], cols[-k:]
            
    if n_out == 2:
        return rows.reshape(-1, 1), cols.reshape(-1, 1)
    
    # 3 outputs: [row, col, val]
    vals = condition[rows-1, cols-1]
    return rows.reshape(-1, 1), cols.reshape(-1, 1), vals.reshape(-1, 1)

def triu(A, k=0):
    return np.triu(np.asarray(A), k=int(k))

def tril(A, k=0):
    return np.tril(np.asarray(A), k=int(k))

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
        
    symbols = builtins.getattr(sympy, 'symbols')(names)
    
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
    return builtins.getattr(sympy, 'simplify')(expr)

def expand(expr):
    return builtins.getattr(sympy, 'expand')(expr)

def factor(expr):
    return builtins.getattr(sympy, 'factor')(expr)

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
    
    x_arr = np.asanyarray(x)
    if x_arr.ndim == 0:
        return np.array([], dtype=x_arr.dtype)
        
    n = 1
    axis = None
    
    # MATLAB: Y = diff(X)
    # MATLAB: Y = diff(X, n)
    # MATLAB: Y = diff(X, n, dim)
    if len(args) > 0:
        n = int(args[0])
    if len(args) > 1:
        axis = int(args[1]) - 1
        
    if 'dim' in kwargs:
        axis = int(kwargs.pop('dim')) - 1
    if 'axis' in kwargs:
        axis = int(kwargs.pop('axis'))
        
    if axis is None:
        if x_arr.ndim <= 1:
            axis = 0
        else:
            # Find first dimension > 1
            axis = 0
            for idx, dim in enumerate(x_arr.shape):
                if dim > 1:
                    axis = idx
                    break
                    
    n = int(n)
    return np.diff(x_arr, n=n, axis=axis, *args[2:], **kwargs)

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
    import numpy as np
    
    handle = 1
    if isinstance(fmt, (int, float)):
        handle = int(fmt)
        if len(args) < 2: return
        fmt = args[1]
        data_args = args[2:]
    else:
        data_args = args[1:]
        
    try:
        # Determine output target
        target = sys.stdout
        fid_map = _get_fid_state()["map"]
        if handle == 2: target = sys.stderr
        elif handle > 2 and handle in fid_map:
            target = fid_map[handle]

        if not data_args:
            output = str(fmt)
        else:
            # Flatten arrays to format them element by element
            flat_args = []
            for a in data_args:
                if isinstance(a, np.ndarray):
                    # Matlab flattens in Fortran order (column-major)
                    flat_args.extend(a.flatten('F').tolist())
                elif isinstance(a, list):
                    flat_args.extend(a)
                else:
                    flat_args.append(a)
                    
            if not flat_args:
                output = str(fmt)
            else:
                # Count format specifiers
                import re
                specifiers = re.findall(r'%[-+ 0#]*\d*(?:\.\d*)?[hlL]?[diuoxXfFeEgGaAcsp]', str(fmt))
                num_specs = len(specifiers)
                
                if num_specs == 0:
                    output = str(fmt)
                else:
                    # Repeat formatting until all elements are consumed
                    outputs = []
                    i = 0
                    while i < len(flat_args):
                        chunk = tuple(flat_args[i:i+num_specs])
                        if len(chunk) < num_specs:
                            # Pad with necessary values or just format what's left
                            # Usually Matlab stops or pads, we'll try to format the remaining
                            # by constructing a new format string, but for simplicity we'll just format
                            # and let python throw if it's missing args. To avoid throwing, we pad with 0.
                            chunk = chunk + (0,) * (num_specs - len(chunk))
                        
                        # Replace Matlab specific format specifiers (e.g. \n needs to be handled properly if escaped)
                        fmt_str = str(fmt).replace('\\n', '\n').replace('\\t', '\t')
                        try:
                            outputs.append(fmt_str % chunk)
                        except Exception:
                            outputs.append(fmt_str)
                        i += num_specs
                    
                    output = "".join(outputs)
    except Exception:
        output = str(fmt).replace('\\n', '\n').replace('\\t', '\t')
        
    # Write to target
    target.write(output)
    target.flush()

def clc():
    """Clear Command Window."""
    if os.environ.get('UNILAB_WEB_MODE') == '1' or os.environ.get('UNILAB_API_SERVER') == '1' or os.environ.get('UNILAB_BRIDGE_MODE') == '1':
        print('::CLEAR_TERMINAL::')
    else:
        os.system('cls' if os.name == 'nt' else 'clear')

def length(x):
    if hasattr(x, '__len__'):
        if isinstance(x, np.ndarray):
            if x.size == 0: return 0
            if x.ndim == 0: return 1
            return int(builtins.max(np.shape(x)))
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
    
    if dim is not None:
        d = _unilab_to_int(dim)
        return s[d-1] if d <= len(s) else 1
    
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
        raw_dims = list(np.asarray(args[0]).flatten())
    else:
        raw_dims = list(args)
    shape = []
    for d in raw_dims:
        if d is None or (isinstance(d, (list, tuple, np.ndarray)) and np.asarray(d).size == 0):
            shape.append(-1)
        else:
            shape.append(_unilab_to_int(d))
    return np.reshape(x, shape, order='F') if np.asarray(x).ndim >= 2 else np.reshape(x, shape)

def sort(x, axis=None, direction='ascend'):
    x_arr = np.asarray(x)
    if isinstance(axis, str) and axis.lower() in ('ascend', 'descend'):
        direction = axis
        axis = None
    if axis is None:
        if x_arr.ndim == 2:
            axis = 1 if x_arr.shape[0] == 1 else 0
        else:
            axis = 0
    else:
        axis = _unilab_to_int(axis) - 1

    desc = str(direction).lower().startswith('desc')
    if x_arr.ndim == 0:
        idx = np.array([[1]])
        return (x_arr, idx) if unilab_get_nargout() > 1 else x_arr

    order_idx = np.argsort(-x_arr if desc else x_arr, axis=axis, kind='mergesort')
    sorted_arr = np.take_along_axis(x_arr, order_idx, axis=axis)
    if unilab_get_nargout() <= 1:
        return sorted_arr
    return sorted_arr, order_idx + 1

def unique(x): return np.unique(x)

def inv(x):
    arr = np.asarray(x)
    if arr.ndim == 0 or (arr.ndim <= 2 and arr.size == 1 and np.isscalar(x)):
        val = arr.item()
        if val == 0:
            return np.inf
        return 1.0 / val
    res = np.linalg.inv(np.atleast_2d(arr))
    return res

def det(x):
    arr = np.asarray(x)
    if arr.ndim == 0 or arr.size == 1:
        return float(arr.item()) if not np.iscomplexobj(arr) else arr.item()
    return np.linalg.det(np.atleast_2d(arr))

def svd(x, *args):
    x_mat = np.atleast_2d(np.asarray(x))
    econ = len(args) > 0 and str(args[0]) in ('0', 'econ')
    n_out = unilab_get_nargout()
    if n_out <= 1:
        S = np.linalg.svd(x_mat, compute_uv=False)
        return S.reshape(-1, 1)
    U, S, Vh = np.linalg.svd(x_mat, full_matrices=(not econ))
    if econ:
        S_mat = np.diag(S)
    else:
        S_mat = np.zeros((x_mat.shape[0], x_mat.shape[1]), dtype=S.dtype)
        np.fill_diagonal(S_mat, S)
    return U, S_mat, Vh.conj().T

def linspace(start, stop, n=100):
    start = float(start) if isinstance(start, UnilabCallableConstant) else start
    stop = float(stop) if isinstance(stop, UnilabCallableConstant) else stop
    return np.atleast_2d(np.linspace(start, stop, int(n)))
def logspace(start, stop, n=50):
    start = float(start) if isinstance(start, UnilabCallableConstant) else start
    stop = float(stop) if isinstance(stop, UnilabCallableConstant) else stop
    return np.atleast_2d(np.logspace(start, stop, int(n)))
def meshgrid(*args):
    if not args: return []
    processed_args = [_unilab_vec(arg) for arg in args]
    if len(processed_args) == 1:
        x = processed_args[0]
        return np.meshgrid(x, x)
    return np.meshgrid(*processed_args)
def randperm(n): return (np.random.permutation(_unilab_to_int(n)) + 1).reshape(1, -1)
def _is_symbolic(x):
    return hasattr(x, '__module__') and 'sympy' in x.__module__

def unilab_abs(*args):
    if not args: return 0.0
    x = args[0]
    if _is_symbolic(x):
        import sympy
        return sympy.Abs(x)
    return np.abs(x)

def round(x, n=0):
    if isinstance(x, UnilabEnd):
        return x.__round__(int(n) if n else None)
    if _is_symbolic(x):
        return x
    return np.round(x, decimals=int(n))

def floor(x):
    if isinstance(x, UnilabEnd):
        return x.__floor__()
    if _is_symbolic(x):
        import sympy
        return sympy.floor(x)
    return np.floor(x)

def ceil(x):
    if isinstance(x, UnilabEnd):
        return x.__ceil__()
    if _is_symbolic(x):
        import sympy
        return sympy.ceil(x)
    return np.ceil(x)

def fix(x):
    if isinstance(x, UnilabEnd):
        return UnilabEnd(lambda n, s=x._fn: math.trunc(s(n)))
    return np.trunc(x)
def rem(x, y): return np.remainder(x, y)
def sign(x): return np.sign(x)

def _to_numeric(x):
    if _is_symbolic(x):
        return x
    if isinstance(x, UnilabCallableConstant):
        return x.val
    if isinstance(x, np.ndarray) and x.dtype == object:
        try:
            return x.astype(np.complex128 if np.iscomplexobj(x) else np.float64)
        except Exception:
            return x
    return x

def sin(x):
    if _is_symbolic(x):
        import sympy
        return sympy.sin(x)
    return np.sin(_to_numeric(x))

def cos(x):
    if _is_symbolic(x):
        import sympy
        return sympy.cos(x)
    return np.cos(_to_numeric(x))

def tan(x):
    if _is_symbolic(x):
        import sympy
        return sympy.tan(x)
    return np.tan(_to_numeric(x))

def asin(x):
    if _is_symbolic(x):
        import sympy
        return sympy.asin(x)
    return np.arcsin(_to_numeric(x))

def acos(x):
    if _is_symbolic(x):
        import sympy
        return sympy.acos(x)
    return np.arccos(_to_numeric(x))

def atan(x):
    if _is_symbolic(x):
        import sympy
        return sympy.atan(x)
    return np.arctan(_to_numeric(x))

def atan2(y, x):
    if _is_symbolic(y) or _is_symbolic(x):
        import sympy
        return sympy.atan2(y, x)
    return np.arctan2(_to_numeric(y), _to_numeric(x))

def sinh(x):
    if _is_symbolic(x):
        import sympy
        return sympy.sinh(x)
    return np.sinh(_to_numeric(x))

def cosh(x):
    if _is_symbolic(x):
        import sympy
        return sympy.cosh(x)
    return np.cosh(_to_numeric(x))

def tanh(x):
    if _is_symbolic(x):
        import sympy
        return sympy.tanh(x)
    return np.tanh(_to_numeric(x))

def asinh(x):
    if _is_symbolic(x):
        import sympy
        return sympy.asinh(x)
    return np.arcsinh(_to_numeric(x))

def acosh(x):
    if _is_symbolic(x):
        import sympy
        return sympy.acosh(x)
    return np.arccosh(_to_numeric(x))

def atanh(x):
    if _is_symbolic(x):
        import sympy
        return sympy.atanh(x)
    return np.arctanh(_to_numeric(x))

def sec(x): return 1.0 / np.cos(x)
def csc(x): return 1.0 / np.sin(x)
def cot(x): return 1.0 / np.tan(x)

def asec(x): return np.arccos(1.0 / np.asarray(x))
def acsc(x): return np.arcsin(1.0 / np.asarray(x))
def acot(x): return np.arctan(1.0 / np.asarray(x))

def sech(x): return 1.0 / np.cosh(x)
def csch(x): return 1.0 / np.sinh(x)
def coth(x): return 1.0 / np.tanh(x)

def asech(x): return np.arccosh(1.0 / np.asarray(x))
def acsch(x): return np.arcsinh(1.0 / np.asarray(x))
def acoth(x): return np.arctanh(1.0 / np.asarray(x))

def rad2deg(x): return np.rad2deg(x)
def deg2rad(x): return np.deg2rad(x)

def relu(x):
    if _is_symbolic(x):
        import sympy
        return sympy.Max(0, x)
    return np.maximum(0, x)

def exp(x):
    if _is_symbolic(x):
        import sympy
        return sympy.exp(x)
    return np.exp(_to_numeric(x))

def log(x):
    if _is_symbolic(x):
        import sympy
        return sympy.log(x)
    return np.log(_to_numeric(x))

def sqrt(x):
    if _is_symbolic(x):
        import sympy
        return sympy.sqrt(x)
    return np.sqrt(_to_numeric(x))

def eye(n, m=None):
    if isinstance(n, (list, tuple, np.ndarray)):
        sz = np.asarray(n).flatten()
        if len(sz) >= 2:
            return np.eye(int(sz[0]), int(sz[1]))
        n = sz[0]
    return np.eye(int(n), int(m) if m is not None else int(n))
def zeros(*args): 
    if not args:
        return np.zeros((1, 1))
    if len(args) == 1:
        if isinstance(args[0], (list, tuple, np.ndarray)):
            flat = [_unilab_to_int(i) for i in np.asarray(args[0]).flatten()]
            shape = (flat[0], flat[0]) if len(flat) == 1 else tuple(flat)
            return np.zeros(shape)
        n = _unilab_to_int(args[0])
        return np.zeros((n, n))
    return np.zeros(tuple(_unilab_to_int(i) for i in args))

def ones(*args): 
    if not args:
        return np.ones((1, 1))
    if len(args) == 1:
        if isinstance(args[0], (list, tuple, np.ndarray)):
            flat = [_unilab_to_int(i) for i in np.asarray(args[0]).flatten()]
            shape = (flat[0], flat[0]) if len(flat) == 1 else tuple(flat)
            return np.ones(shape)
        n = _unilab_to_int(args[0])
        return np.ones((n, n))
    return np.ones(tuple(_unilab_to_int(i) for i in args))

def median(x, axis=None):
    return unilab_median(x, axis=axis)

def quantile(x, q, axis=None):
    return unilab_quantile(x, q, axis=axis)

def var(x, flag=0, axis=None):
    x_arr = np.asarray(x, dtype=float)
    ddof = 0 if (flag is not None and isinstance(flag, (int, float, np.number)) and int(flag) == 1) else (1 if x_arr.size > 1 else 0)
    if axis is not None:
        axis = _unilab_to_int(axis) - 1
    elif x_arr.ndim > 1:
        axis = 0
        for idx, d in enumerate(x_arr.shape):
            if d > 1:
                axis = idx
                break
                
    if axis is not None and x_arr.ndim > axis and x_arr.shape[axis] <= 1:
        ddof = 0
    res = np.var(x_arr, ddof=ddof, axis=axis)
    return res.item() if hasattr(res, 'item') and res.size == 1 else res

def std(x, flag=0, axis=None):
    x_arr = np.asarray(x, dtype=float)
    ddof = 0 if (flag is not None and isinstance(flag, (int, float, np.number)) and int(flag) == 1) else (1 if x_arr.size > 1 else 0)
    if axis is not None:
        axis = _unilab_to_int(axis) - 1
    elif x_arr.ndim > 1:
        axis = 0
        for idx, d in enumerate(x_arr.shape):
            if d > 1:
                axis = idx
                break
    if axis is not None and x_arr.ndim > axis and x_arr.shape[axis] <= 1:
        ddof = 0
    res = np.std(x_arr, ddof=ddof, axis=axis)
    return res.item() if hasattr(res, 'item') and res.size == 1 else res

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
    if seed is not None:
        if isinstance(seed, (int, np.integer)):
            np.random.seed(int(seed))
        elif str(seed) == 'default':
            np.random.seed(0)
    return None

_tic_stack = []

def tic():
    _get_tic_stack().append(time.time())

def toc():
    stack = _get_tic_stack()
    if not stack:
        print("Error: toc called without a preceding tic.")
        return 0.0
    elapsed = time.time() - stack.pop()
    print(f"Elapsed time is {elapsed:.6f} seconds.")
    return elapsed

def rand(*args):
    if len(args) == 1:
        if isinstance(args[0], (list, tuple, np.ndarray)): 
            args = [_unilab_to_int(a) for a in np.asarray(args[0]).flatten()]
        else:
            args = [_unilab_to_int(args[0]), _unilab_to_int(args[0])]
    else:
        args = [_unilab_to_int(a) for a in args]
    return np.random.rand(*args) if args else np.random.rand()

def randn(*args):
    if len(args) == 1:
        if isinstance(args[0], (list, tuple, np.ndarray)):
            args = [_unilab_to_int(a) for a in np.asarray(args[0]).flatten()]
        else:
            args = [_unilab_to_int(args[0]), _unilab_to_int(args[0])]
    else:
        args = [_unilab_to_int(a) for a in args]
    return np.random.randn(*args) if args else np.random.randn()

def randi(imax, *args):
    if isinstance(imax, (list, tuple, np.ndarray)):
        bounds = np.asarray(imax).flatten()
        if bounds.size >= 2:
            low, high = _unilab_to_int(bounds[0]), _unilab_to_int(bounds[1])
        else:
            low, high = 1, _unilab_to_int(bounds[0])
    else:
        low, high = 1, _unilab_to_int(imax)

    if not args:
        return int(np.random.randint(low, high + 1))
    if len(args) == 1:
        if isinstance(args[0], (list, tuple, np.ndarray)):
            flat = [_unilab_to_int(i) for i in np.asarray(args[0]).flatten()]
            size = (flat[0], flat[0]) if len(flat) == 1 else tuple(flat)
        else:
            n = _unilab_to_int(args[0])
            size = (n, n)
    else:
        size = tuple(_unilab_to_int(i) for i in args)
    return np.random.randint(low, high + 1, size=size)

def unilab_max(x, *args, **kwargs):
    if len(args) == 1 and not kwargs:
        return np.maximum(x, args[0])

    x_arr = np.asarray(x)
    axis = kwargs.get('axis', None)
    if len(args) >= 2 and isempty(args[0]):
        axis = _unilab_to_int(args[1]) - 1
    elif axis is not None:
        axis = _unilab_to_int(axis) - 1
    elif len(args) == 0:
        if x_arr.ndim <= 1:
            axis = 0 if x_arr.ndim == 1 else None
        else:
            axis = 0
            for idx_d, d in enumerate(x_arr.shape):
                if d > 1:
                    axis = idx_d
                    break

    n_out = unilab_get_nargout()
    if n_out <= 1:
        res = np.max(x_arr, axis=axis)
        return res.item() if hasattr(res, 'item') and res.size == 1 else res

    val = np.max(x_arr, axis=axis)
    idx = np.argmax(x_arr, axis=axis) + 1
    v_ret = val.item() if hasattr(val, 'item') and val.size == 1 else val
    return v_ret, idx

def unilab_min(x, *args, **kwargs):
    if len(args) == 1 and not kwargs:
        return np.minimum(x, args[0])

    x_arr = np.asarray(x)
    axis = kwargs.get('axis', None)
    if len(args) >= 2 and isempty(args[0]):
        axis = _unilab_to_int(args[1]) - 1
    elif axis is not None:
        axis = _unilab_to_int(axis) - 1
    elif len(args) == 0:
        if x_arr.ndim <= 1:
            axis = 0 if x_arr.ndim == 1 else None
        else:
            axis = 0
            for idx_d, d in enumerate(x_arr.shape):
                if d > 1:
                    axis = idx_d
                    break

    n_out = unilab_get_nargout()
    if n_out <= 1:
        res = np.min(x_arr, axis=axis)
        return res.item() if hasattr(res, 'item') and res.size == 1 else res

    val = np.min(x_arr, axis=axis)
    idx = np.argmin(x_arr, axis=axis) + 1
    v_ret = val.item() if hasattr(val, 'item') and val.size == 1 else val
    return v_ret, idx

def unilab_sum(x, axis=None):
    x_arr = np.asarray(x)
    if axis is not None:
        axis = _unilab_to_int(axis) - 1
    elif x_arr.ndim > 1:
        axis = 0
        for idx_d, d in enumerate(x_arr.shape):
            if d > 1:
                axis = idx_d
                break

    res = np.sum(x_arr, axis=axis)
    return res.item() if hasattr(res, 'item') and res.size == 1 else res

def ode45(f, tspan, y0, options=None):
    from scipy.integrate import solve_ivp
    tspan_arr = np.asarray(tspan, dtype=float).flatten()
    y0_arr = np.asarray(y0, dtype=float)
    y0_shape = y0_arr.shape
    y0_flat = y0_arr.flatten()
    
    def wrapper(t, y):
        res = unilab_call(f, t, y.reshape(y0_shape) if y0_shape else y[0])
        return np.asarray(res, dtype=float).flatten()

    t_eval = tspan_arr if tspan_arr.size > 2 else np.linspace(tspan_arr[0], tspan_arr[-1], 100)
    sol = solve_ivp(wrapper, (float(tspan_arr[0]), float(tspan_arr[-1])), y0_flat, t_eval=t_eval)
    
    n_out = unilab_get_nargout()
    if n_out == 1:
        return {'x': sol.t, 'y': sol.y}
    return sol.t.reshape(-1, 1), sol.y.T

ode45_custom = ode45

def diag(v, k=0):
    v = np.asarray(v)
    k = int(k)
    if v.ndim == 2:
        if v.shape[0] == 1 or v.shape[1] == 1:
            # Vector input: create diagonal matrix
            return np.diag(v.flatten(), k)
        else:
            # Matrix input: extract diagonal as column vector
            return np.diag(v, k).reshape(-1, 1)
    # 1D input: create diagonal matrix
    return np.diag(v, k)

def unilab_eig(x):
    n_out = unilab_get_nargout()
    x_mat = np.atleast_2d(x)
    if n_out <= 1:
        # Return eigenvalues as a column vector
        return np.linalg.eigvals(x_mat).reshape(-1, 1)
    
    # [V, D] = eig(A)
    eigenvalues, eigenvectors = np.linalg.eig(x_mat)
    return eigenvectors, np.diag(eigenvalues)

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
        if not args:
            return str(fmt)
            
        import numpy as np
        flat_args = []
        for a in args:
            if isinstance(a, np.ndarray):
                flat_args.extend(a.flatten('F').tolist())
            elif isinstance(a, list):
                flat_args.extend(a)
            else:
                flat_args.append(a)
                
        if not flat_args:
            return str(fmt)
            
        import re
        specifiers = re.findall(r'%[-+ 0#]*\d*(?:\.\d*)?[hlL]?[diuoxXfFeEgGaAcsp]', str(fmt))
        num_specs = len(specifiers)
        
        if num_specs == 0:
            return str(fmt)
            
        outputs = []
        i = 0
        fmt_str = str(fmt).replace('\\n', '\n').replace('\\t', '\t')
        while i < len(flat_args):
            chunk = tuple(flat_args[i:i+num_specs])
            if len(chunk) < num_specs:
                chunk = chunk + (0,) * (num_specs - len(chunk))
            try:
                outputs.append(fmt_str % chunk)
            except Exception:
                outputs.append(fmt_str)
            i += num_specs
        return "".join(outputs)
    except Exception:
        return str(fmt).replace('\\n', '\n').replace('\\t', '\t')

# ==============================================================================
# UniLab Plotting & Visualization Engine (Customizable, Theme-Aware, MATLAB-Compatible)
# ==============================================================================

_COLORMAP_PALETTES = {
    'viridis': ['#4cc9f0', '#7ae582', '#f9c74f', '#f9844a', '#b5179e', '#4361ee', '#90be6d', '#f94144'],
    'plasma': ['#f72585', '#b5179e', '#7209b7', '#4361ee', '#4cc9f0', '#ffbe0b', '#fb5607', '#8338ec'],
    'inferno': ['#fcbf49', '#f77f00', '#d62828', '#9d4edd', '#48cae4', '#80ed99', '#ff9f1c', '#e71d36'],
    'magma': ['#ff758f', '#c77dff', '#72efdd', '#ffd166', '#06d6a0', '#118ab2', '#ef476f', '#e0aaff'],
    'cividis': ['#64dfdf', '#ffd166', '#80ed99', '#7400b8', '#4ea8de', '#f4a261', '#e76f51', '#a8dadc'],
    'coolwarm': ['#4ea8de', '#f7768e', '#7dcfff', '#ff9e64', '#9ece6a', '#bb9af7', '#e0af68', '#2ac3de'],
    'turbo': ['#3a86ff', '#06d6a0', '#ffbe0b', '#fb5607', '#ff006e', '#8338ec', '#4cc9f0', '#70e000'],
    'jet': ['#00b4d8', '#70e000', '#ffbe0b', '#ff5400', '#9d4edd', '#00f5d4', '#f15bb5', '#fee440'],
}

_unilab_plot_config = {
    'theme_mode': 'theme',       # 'theme' (matches IDE theme), 'dark', or 'light' (publication white)
    'bg_color': '#16161e',
    'axes_bg_color': '#1a1b26',
    'fg_color': '#c0caf5',
    'muted_fg_color': '#9aa5ce',
    'grid_color': '#2f3549',
    'spine_color': '#414868',
    'accent_color': '#7dcfff',
    'colormap': 'viridis',
    'show_grid': True,
    'show_labels': True,
    'show_legend': False,
    'font_size': 9.5,
    'line_width': 1.8,
    'marker_size': 6.0,
    'dpi': 130,
    'theme_bg_color': '#16161e',
    'theme_axes_bg_color': '#1a1b26',
    'theme_fg_color': '#c0caf5',
    'theme_muted_fg_color': '#9aa5ce',
    'theme_grid_color': '#2f3549',
    'theme_spine_color': '#414868',
}


def _get_active_color_cycle():
    cmap_key = str(_unilab_plot_config.get('colormap', 'viridis')).lower()
    if _unilab_plot_config.get('theme_mode') == 'light':
        return ['#0072bd', '#d95319', '#edb120', '#7e2f8e', '#77ac30', '#4dbeee', '#a2142f', '#3b82f6']
    return _COLORMAP_PALETTES.get(cmap_key, _COLORMAP_PALETTES['viridis'])


def _sync_rcparams_from_config():
    cfg = _unilab_plot_config
    fs = float(cfg.get('font_size', 9.5))
    lw = float(cfg.get('line_width', 1.8))
    ms = float(cfg.get('marker_size', 6.0))
    cmap_name = str(cfg.get('colormap', 'viridis')).lower()
    valid_cmaps = {
        'viridis', 'plasma', 'inferno', 'magma', 'cividis', 'coolwarm',
        'turbo', 'jet', 'hot', 'cool', 'spring', 'summer', 'winter', 'bone', 'copper', 'gray'
    }
    if cmap_name not in valid_cmaps:
        cmap_name = 'viridis'

    palette = _get_active_color_cycle()
    plt.rcParams.update({
        'axes.prop_cycle': plt.cycler(color=palette),
        'axes.linewidth': 1.0,
        'axes.edgecolor': cfg['spine_color'],
        'axes.facecolor': cfg['axes_bg_color'],
        'axes.labelcolor': cfg['fg_color'],
        'axes.labelsize': fs,
        'axes.labelweight': '500',
        'axes.titlesize': fs + 1.5,
        'axes.titleweight': '600',
        'axes.titlepad': 8.0,
        'axes.grid': bool(cfg.get('show_grid', True)),
        'figure.facecolor': cfg['bg_color'],
        'figure.edgecolor': cfg['bg_color'],
        'figure.figsize': (7.2, 4.6),
        'figure.dpi': int(cfg.get('dpi', 130)),
        'grid.color': cfg['grid_color'],
        'grid.linestyle': '--',
        'grid.linewidth': 0.75,
        'grid.alpha': 0.45,
        'lines.linewidth': lw,
        'lines.markersize': ms,
        'font.size': fs,
        'font.weight': 'normal',
        'text.color': cfg['fg_color'],
        'xtick.color': cfg['muted_fg_color'],
        'ytick.color': cfg['muted_fg_color'],
        'xtick.labelsize': max(7.0, fs - 1.0),
        'ytick.labelsize': max(7.0, fs - 1.0),
        'legend.fontsize': max(7.5, fs - 1.0),
        'legend.facecolor': cfg['axes_bg_color'],
        'legend.edgecolor': cfg['spine_color'],
        'legend.framealpha': 0.88,
        'image.cmap': cmap_name,
        'savefig.facecolor': cfg['bg_color'],
        'savefig.edgecolor': cfg['bg_color'],
        'savefig.dpi': int(cfg.get('dpi', 130)),
    })


_sync_rcparams_from_config()

_unilab_plot_counter = 0
_unilab_fig_versions = {}
_unilab_custom_fig_colors = set()


def _normalize_matlab_color(c):
    """Converts MATLAB color specs (char codes, color names, hex strings, or 1x3/1x4 RGB arrays) to Matplotlib colors."""
    if c is None:
        return None
    if isinstance(c, str):
        c_strip = c.strip()
        matlab_color_map = {
            'r': '#ef4444', 'red': '#ef4444',
            'g': '#22c55e', 'green': '#22c55e',
            'b': '#3b82f6', 'blue': '#3b82f6',
            'c': '#06b6d4', 'cyan': '#06b6d4',
            'm': '#d946ef', 'magenta': '#d946ef',
            'y': '#eab308', 'yellow': '#eab308',
            'k': '#1e293b', 'black': '#1e293b',
            'w': '#ffffff', 'white': '#ffffff',
            'none': 'none', 'auto': None,
        }
        return matlab_color_map.get(c_strip.lower(), c_strip)
    if isinstance(c, (list, tuple, np.ndarray)):
        try:
            arr = np.asarray(c, dtype=float).flatten()
            if len(arr) in (3, 4):
                if np.any(arr > 1.0):
                    arr = np.clip(arr / 255.0, 0.0, 1.0)
                else:
                    arr = np.clip(arr, 0.0, 1.0)
                return tuple(float(x) for x in arr)
        except Exception:
            pass
    return c


def _extract_extra_axes_opts(kwargs_dict):
    """Extracts high-level axes options (title, xlabel, ylabel, grid, fontsize) from kwargs_dict so Matplotlib artist calls don't reject them."""
    extra = {}
    for k in ('title', 'xlabel', 'ylabel', 'zlabel', 'grid', 'fontsize', 'fontweight', 'xlim', 'ylim', 'colormap'):
        if k in kwargs_dict:
            extra[k] = kwargs_dict.pop(k)
    return extra


def _apply_extra_axes_opts(ax, extra_opts):
    """Applies extracted high-level axes options to ax."""
    if not extra_opts or ax is None:
        return
    cfg = _unilab_plot_config
    fs = float(extra_opts.get('fontsize', cfg['font_size']))
    fw = extra_opts.get('fontweight', '600')
    if 'title' in extra_opts and hasattr(ax, 'set_title'):
        ax.set_title(str(extra_opts['title']), fontsize=fs + 1.5, fontweight=fw, color=cfg['fg_color'])
    if 'xlabel' in extra_opts and hasattr(ax, 'set_xlabel'):
        ax.set_xlabel(str(extra_opts['xlabel']), fontsize=fs, color=cfg['fg_color'])
    if 'ylabel' in extra_opts and hasattr(ax, 'set_ylabel'):
        ax.set_ylabel(str(extra_opts['ylabel']), fontsize=fs, color=cfg['fg_color'])
    if 'zlabel' in extra_opts and hasattr(ax, 'set_zlabel'):
        ax.set_zlabel(str(extra_opts['zlabel']), fontsize=fs, color=cfg['fg_color'])
    if 'grid' in extra_opts and hasattr(ax, 'grid'):
        g_val = extra_opts['grid']
        vis = str(g_val).lower() in ('on', 'true', '1') or g_val is True
        ax.grid(vis, which='both', linestyle='--', alpha=0.45, color=cfg['grid_color'])
    if 'xlim' in extra_opts and hasattr(ax, 'set_xlim'):
        xl = np.asarray(extra_opts['xlim'], dtype=float).flatten()
        if xl.size >= 2:
            ax.set_xlim(float(xl[0]), float(xl[1]))
    if 'ylim' in extra_opts and hasattr(ax, 'set_ylim'):
        yl = np.asarray(extra_opts['ylim'], dtype=float).flatten()
        if yl.size >= 2:
            ax.set_ylim(float(yl[0]), float(yl[1]))


def unilab_configure_plots(**kwargs):
    """
    Updates global UniLab plot styling from Flutter Settings / Theme or user scripts.
    Supports:
      theme_mode ('theme' | 'dark' | 'light'),
      bg_color, axes_bg_color, fg_color, muted_fg_color, grid_color, spine_color, accent_color,
      colormap, show_grid, show_labels, show_legend, font_size, line_width, marker_size, dpi, re_render.
    """
    cfg = _unilab_plot_config
    re_render = bool(kwargs.pop('re_render', False))

    # Persist theme colors when passed from IDE theme sync
    for tk in ('bg_color', 'axes_bg_color', 'fg_color', 'muted_fg_color', 'grid_color', 'spine_color'):
        if tk in kwargs and kwargs.get('theme_mode', cfg.get('theme_mode')) == 'theme':
            cfg[f'theme_{tk}'] = kwargs[tk]

    for k, v in kwargs.items():
        if v is not None and k in cfg:
            cfg[k] = v

    mode = str(cfg.get('theme_mode', 'theme')).lower()
    if mode == 'light':
        cfg['bg_color'] = '#ffffff'
        cfg['axes_bg_color'] = '#f8fafc'
        cfg['fg_color'] = '#0f172a'
        cfg['muted_fg_color'] = '#475569'
        cfg['grid_color'] = '#cbd5e1'
        cfg['spine_color'] = '#94a3b8'
    elif mode == 'dark':
        cfg['bg_color'] = '#12131a'
        cfg['axes_bg_color'] = '#181a24'
        cfg['fg_color'] = '#e2e8f0'
        cfg['muted_fg_color'] = '#94a3b8'
        cfg['grid_color'] = '#2d3348'
        cfg['spine_color'] = '#475569'
    else:
        for tk in ('bg_color', 'axes_bg_color', 'fg_color', 'muted_fg_color', 'grid_color', 'spine_color'):
            if f'theme_{tk}' in cfg:
                cfg[tk] = cfg[f'theme_{tk}']

    _sync_rcparams_from_config()

    if re_render and plt is not None:
        for fnum in list(plt.get_fignums()):
            try:
                unilab_customize_figure(fnum)
            except Exception:
                pass
    return cfg


def unilab_customize_figure(
    fig_num=None,
    title_text=None,
    xlabel_text=None,
    ylabel_text=None,
    zlabel_text=None,
    show_grid=None,
    show_legend=None,
    show_labels=None,
    colormap_name=None,
    line_width=None,
    font_size=None,
    theme_mode=None,
    xlim_vals=None,
    ylim_vals=None,
):
    """
    Live-updates an existing Matplotlib figure's style, labels, grid, legend, colormap,
    line width, font size, or theme, and re-emits the updated PNG & metadata to the UI.
    """
    cfg = _unilab_plot_config
    global_updates = {}
    if show_grid is not None:
        global_updates['show_grid'] = bool(show_grid)
    if show_legend is not None:
        global_updates['show_legend'] = bool(show_legend)
    if show_labels is not None:
        global_updates['show_labels'] = bool(show_labels)
    if colormap_name is not None:
        global_updates['colormap'] = str(colormap_name).lower()
    if line_width is not None:
        global_updates['line_width'] = float(line_width)
    if font_size is not None:
        global_updates['font_size'] = float(font_size)
    if theme_mode is not None:
        global_updates['theme_mode'] = str(theme_mode).lower()
    if global_updates:
        unilab_configure_plots(**global_updates, re_render=False)

    fnums = plt.get_fignums()
    if not fnums:
        return None
    target_num = int(fig_num) if (fig_num is not None and int(fig_num) in fnums) else fnums[-1]
    fig = plt.figure(target_num)
    if not fig.axes:
        return None

    fs = float(cfg['font_size'])
    lw = float(cfg['line_width'])
    cmap_str = str(cfg['colormap']).lower()
    palette = _get_active_color_cycle()

    # Main content axes (excluding colorbar axes)
    content_axes = [a for a in fig.axes if getattr(a, 'get_label', lambda: '')() != '<colorbar>']
    if not content_axes:
        content_axes = list(fig.axes)

    primary_ax = content_axes[0]
    if title_text is not None:
        primary_ax._unilab_saved_title = str(title_text)
        primary_ax.set_title(str(title_text), fontsize=fs + 1.5, fontweight='600', color=cfg['fg_color'])
    if xlabel_text is not None:
         target_x_ax = content_axes[-1]
         target_x_ax._unilab_saved_xlabel = str(xlabel_text)
         target_x_ax.set_xlabel(str(xlabel_text), fontsize=fs, color=cfg['fg_color'])
    if ylabel_text is not None:
        primary_ax._unilab_saved_ylabel = str(ylabel_text)
        primary_ax.set_ylabel(str(ylabel_text), fontsize=fs, color=cfg['fg_color'])
    if zlabel_text is not None and hasattr(primary_ax, 'set_zlabel'):
        primary_ax._unilab_saved_zlabel = str(zlabel_text)
        primary_ax.set_zlabel(str(zlabel_text), fontsize=fs, color=cfg['fg_color'])

    if xlim_vals is not None and len(xlim_vals) >= 2:
        primary_ax.set_xlim(float(xlim_vals[0]), float(xlim_vals[1]))
    if ylim_vals is not None and len(ylim_vals) >= 2:
        primary_ax.set_ylim(float(ylim_vals[0]), float(ylim_vals[1]))

    for ax_item in content_axes:
        # Preserve original titles/labels when toggling show_labels off/on
        cur_t = ax_item.get_title()
        if cur_t:
            ax_item._unilab_saved_title = cur_t
        cur_x = ax_item.get_xlabel()
        if cur_x:
            ax_item._unilab_saved_xlabel = cur_x
        cur_y = ax_item.get_ylabel()
        if cur_y:
            ax_item._unilab_saved_ylabel = cur_y

        if show_labels is not None:
            if show_labels:
                saved_t = getattr(ax_item, '_unilab_saved_title', cur_t)
                saved_x = getattr(ax_item, '_unilab_saved_xlabel', cur_x)
                saved_y = getattr(ax_item, '_unilab_saved_ylabel', cur_y)
                if saved_t:
                    ax_item.set_title(saved_t, fontsize=fs + 1.5, fontweight='600', color=cfg['fg_color'])
                if saved_x:
                    ax_item.set_xlabel(saved_x, fontsize=fs, color=cfg['fg_color'])
                if saved_y:
                    ax_item.set_ylabel(saved_y, fontsize=fs, color=cfg['fg_color'])
            else:
                ax_item.set_title('')
                ax_item.set_xlabel('')
                ax_item.set_ylabel('')

        # Update font sizes and colors
        ax_item.title.set_fontsize(fs + 1.5)
        ax_item.title.set_color(cfg['fg_color'])
        ax_item.xaxis.label.set_fontsize(fs)
        ax_item.xaxis.label.set_color(cfg['fg_color'])
        ax_item.yaxis.label.set_fontsize(fs)
        ax_item.yaxis.label.set_color(cfg['fg_color'])
        ax_item.tick_params(axis='both', which='major', labelsize=max(7.0, fs - 1.0), colors=cfg['muted_fg_color'])

        # Update grid
        if show_grid is not None:
            if show_grid:
                ax_item.grid(True, which='both', linestyle='--', alpha=0.45, color=cfg['grid_color'], linewidth=0.75)
            else:
                ax_item.grid(False)

        # Update line widths and colormap on lines/collections/images
        data_lines = [
            ln for ln in ax_item.lines
            if ln.get_linestyle() not in (':', 'None') or ln.get_label() and not str(ln.get_label()).startswith('_')
        ]
        if line_width is not None:
            for ln in data_lines:
                ln.set_linewidth(lw)

        if colormap_name is not None:
            has_mappable = False
            for img in getattr(ax_item, 'images', []):
                try:
                    img.set_cmap(cmap_str)
                    has_mappable = True
                except Exception:
                    pass
            for coll in getattr(ax_item, 'collections', []):
                try:
                    if hasattr(coll, 'set_cmap'):
                        coll.set_cmap(cmap_str)
                        has_mappable = True
                except Exception:
                    pass
            if not has_mappable:
                for l_idx, ln in enumerate(data_lines):
                    ln.set_color(palette[l_idx % len(palette)])

        # Update legend
        if show_legend is not None:
            if show_legend:
                handles, labels = ax_item.get_legend_handles_labels()
                if not handles and data_lines:
                    for l_idx, ln in enumerate(data_lines):
                        lbl = ln.get_label()
                        if not lbl or str(lbl).startswith('_'):
                            ln.set_label(f'Series {l_idx + 1}')
                    handles, labels = ax_item.get_legend_handles_labels()
                if handles:
                    leg = ax_item.legend(
                        loc='best',
                        fontsize=max(7.5, fs - 1.0),
                        facecolor=cfg['axes_bg_color'],
                        edgecolor=cfg['spine_color'],
                        labelcolor=cfg['fg_color'],
                        framealpha=0.88,
                    )
            else:
                leg = ax_item.get_legend()
                if leg is not None:
                    leg.remove()
        else:
            leg = ax_item.get_legend()
            if leg is not None:
                for txt in leg.get_texts():
                    txt.set_fontsize(max(7.5, fs - 1.0))
                    txt.set_color(cfg['fg_color'])
                leg.get_frame().set_facecolor(cfg['axes_bg_color'])
                leg.get_frame().set_edgecolor(cfg['spine_color'])

    _unilab_update_fig_version(fig.number)
    return _unilab_refresh_graph(fig=fig)


def _unilab_update_fig_version(fig_num=None):
    global _unilab_fig_versions
    if fig_num is None:
        try:
            fig_num = plt.gcf().number
        except Exception:
            fig_num = 1
    _unilab_fig_versions[fig_num] = _unilab_fig_versions.get(fig_num, 0) + 1
    return _unilab_fig_versions[fig_num]


def _unilab_reset_runtime():
    global _unilab_hold, _unilab_plot_counter, _unilab_fig_versions
    _set_hold_state(False)
    _unilab_plot_counter = 0
    _unilab_fig_versions = {}
    _unilab_custom_fig_colors.clear()
    _sync_rcparams_from_config()
    try:
        import matplotlib.pyplot as plt
        plt.close('all')
    except Exception:
        pass


def _style_figure_before_save(fig):
    """Applies cohesive typography, spine colors, grid, and automatic layout to fig before saving."""
    cfg = _unilab_plot_config
    fs = float(cfg.get('font_size', 9.5))

    content_axes = [a for a in fig.axes if getattr(a, 'get_label', lambda: '')() != '<colorbar>']
    num_panels = len(content_axes)

    # Automatically give multi-subplot figures enough room so texts never collide
    cur_w, cur_h = fig.get_size_inches()
    if num_panels >= 3 and (cur_w < 8.4 or cur_h < 5.6):
        fig.set_size_inches(max(cur_w, 8.6), max(cur_h, 5.8))
    elif num_panels == 2 and (cur_w < 7.6 or cur_h < 5.0):
        fig.set_size_inches(max(cur_w, 7.6), max(cur_h, 5.0))
    elif num_panels == 1 and (cur_w < 6.4 or cur_h < 4.0):
        fig.set_size_inches(7.2, 4.6)

    has_custom_bg = fig.number in _unilab_custom_fig_colors
    save_bg = fig.get_facecolor() if has_custom_bg else cfg['bg_color']
    if not has_custom_bg:
        fig.set_facecolor(cfg['bg_color'])
        fig.patch.set_facecolor(cfg['bg_color'])

    for ax_item in fig.axes:
        is_cbar = getattr(ax_item, 'get_label', lambda: '')() == '<colorbar>'
        if not has_custom_bg and not is_cbar:
            ax_item.set_facecolor(cfg['axes_bg_color'])

        # Clamp any oversized fonts left by user scripts or legacy calls
        if hasattr(ax_item, 'title') and ax_item.title.get_text():
            cur_t = ax_item.title.get_text()
            ax_item._unilab_saved_title = cur_t
            cur_t_fs = ax_item.title.get_fontsize()
            if cur_t_fs > 15:
                ax_item.title.set_fontsize(fs + 1.5)
            if not has_custom_bg:
                ax_item.title.set_color(cfg['fg_color'])

        if hasattr(ax_item, 'xaxis') and hasattr(ax_item.xaxis, 'label') and ax_item.xaxis.label.get_text():
            cur_x = ax_item.xaxis.label.get_text()
            ax_item._unilab_saved_xlabel = cur_x
            if ax_item.xaxis.label.get_fontsize() > 13:
                ax_item.xaxis.label.set_fontsize(fs)
            if not has_custom_bg:
                ax_item.xaxis.label.set_color(cfg['fg_color'])

        if hasattr(ax_item, 'yaxis') and hasattr(ax_item.yaxis, 'label') and ax_item.yaxis.label.get_text():
            cur_y = ax_item.yaxis.label.get_text()
            ax_item._unilab_saved_ylabel = cur_y
            if ax_item.yaxis.label.get_fontsize() > 13:
                ax_item.yaxis.label.set_fontsize(fs)
            if not has_custom_bg:
                ax_item.yaxis.label.set_color(cfg['fg_color'])

        ax_item.tick_params(
            axis='both',
            which='major',
            labelsize=max(7.0, fs - 1.0),
            colors=cfg['muted_fg_color'] if not has_custom_bg else None,
        )

        if hasattr(ax_item, 'spines'):
            for sp in ax_item.spines.values():
                if not has_custom_bg:
                    sp.set_edgecolor(cfg['spine_color'])
                sp.set_linewidth(0.9)

        # Style 3D panes cleanly
        if getattr(ax_item, 'name', '') == '3d':
            try:
                pane_rgba = matplotlib.colors.to_rgba(cfg['axes_bg_color'], alpha=0.65)
                for axis_3d in (ax_item.xaxis, ax_item.yaxis, ax_item.zaxis):
                    axis_3d.set_pane_color(pane_rgba)
                    axis_3d._axinfo['grid']['color'] = matplotlib.colors.to_rgba(cfg['grid_color'], alpha=0.45)
                    axis_3d._axinfo['grid']['linewidth'] = 0.65
                ax_item.zaxis.label.set_fontsize(fs)
                if not has_custom_bg:
                    ax_item.zaxis.label.set_color(cfg['fg_color'])
                ax_item.tick_params(axis='z', labelsize=max(7.0, fs - 1.0), colors=cfg['muted_fg_color'])
            except Exception:
                pass

        leg = ax_item.get_legend()
        if leg is not None:
            for txt in leg.get_texts():
                if txt.get_fontsize() > 12:
                    txt.set_fontsize(max(7.5, fs - 1.0))
                if not has_custom_bg:
                    txt.set_color(cfg['fg_color'])
            if not has_custom_bg:
                leg.get_frame().set_facecolor(cfg['axes_bg_color'])
                leg.get_frame().set_edgecolor(cfg['spine_color'])

    try:
        fig.tight_layout(pad=1.15)
    except Exception:
        pass

    return save_bg


def _unilab_refresh_graph(fig=None):
    global _unilab_plot_counter
    try:
        import json
        import base64
        fig = fig or plt.gcf()
        if not fig.axes:
            return None
        content_axes = [
            a for a in fig.axes
            if getattr(a, 'get_label', lambda: '')() != '<colorbar>' and not hasattr(a, '_twinx_for')
        ]
        ax = content_axes[0] if content_axes else fig.axes[0]
        if ax is None:
            return None

        save_bg = _style_figure_before_save(fig)
        cfg = _unilab_plot_config

        # Check whether grid is visible on primary axes
        grid_lines = ax.xaxis.get_gridlines() + ax.yaxis.get_gridlines()
        has_grid = builtins.any(gl.get_visible() for gl in grid_lines) if grid_lines else bool(cfg.get('show_grid', True))
        has_legend = builtins.any(a.get_legend() is not None for a in fig.axes)

        meta = sanitize_for_json({
            "title": getattr(ax, '_unilab_saved_title', '') or ax.get_title() or (fig._suptitle.get_text() if getattr(fig, '_suptitle', None) else ""),
            "xlabel": getattr(content_axes[-1], '_unilab_saved_xlabel', '') or (content_axes[-1].get_xlabel() if content_axes else ax.get_xlabel()),
            "ylabel": getattr(ax, '_unilab_saved_ylabel', '') or ax.get_ylabel(),
            "zlabel": getattr(ax, '_unilab_saved_zlabel', '') or (ax.get_zlabel() if hasattr(ax, 'get_zlabel') else ""),
            "xmin": float(ax.get_xlim()[0]),
            "xmax": float(ax.get_xlim()[1]),
            "ymin": float(ax.get_ylim()[0]),
            "ymax": float(ax.get_ylim()[1]),
            "is_3d": getattr(ax, 'name', '') == '3d',
            "num_subplots": len(content_axes),
            "has_grid": bool(has_grid),
            "has_legend": bool(has_legend),
            "show_labels": bool(cfg.get('show_labels', True)),
            "colormap": str(cfg.get('colormap', 'viridis')),
            "line_width": float(cfg.get('line_width', 1.8)),
            "font_size": float(cfg.get('font_size', 9.5)),
            "theme_mode": str(cfg.get('theme_mode', 'theme')),
        })
        _unilab_plot_counter += 1
        plot_id = _unilab_plot_counter
        ws_path = unilab_workspace_ctx.get()

        if ws_path:
            ws_dir = pathlib.Path(ws_path)
            plots_dir = ws_dir / "plots"
            plots_dir.mkdir(parents=True, exist_ok=True)
            prefix = ws_dir.name.split('_')[-1][:6] + "_"
        else:
            ws_dir = pathlib.Path(unilab_cwd_ctx.get() or ".")
            plots_dir = ws_dir
            plots_dir.mkdir(parents=True, exist_ok=True)
            prefix = ""

        plot_type_marker = "3d_" if getattr(ax, 'name', '') == '3d' else ""
        filename = f"graph_{plot_type_marker}{prefix}{plot_id}_{int(time.time() * 1000)}.png"
        save_path = plots_dir / filename

        dpi_val = int(cfg.get('dpi', 130))
        fig.savefig(str(save_path), format='png', dpi=dpi_val, facecolor=save_bg, bbox_inches='tight', pad_inches=0.14, transparent=False)

        # Write 2D/general metadata JSON
        meta_path = save_path.with_suffix('.json')
        with open(str(meta_path), 'w', encoding='utf-8') as mf:
            json.dump(meta, mf, allow_nan=False)

        # Write 3D sidecar file (.3d.json) if 3D data exists for this figure
        store_3d = _get_3d_store()
        if getattr(ax, 'name', '') == '3d' and fig.number in store_3d:
            sidecar_3d_path = pathlib.Path(str(save_path)[:-4] + '.3d.json')
            clean_3d = sanitize_for_json(store_3d[fig.number])
            with open(str(sidecar_3d_path), 'w', encoding='utf-8') as f3d:
                json.dump(clean_3d, f3d, allow_nan=False)

        # Bridge emission (Base64)
        with open(str(save_path), 'rb') as img_file:
            b64_data = base64.b64encode(img_file.read()).decode('utf-8')
            data_uri = f'data:image/png;base64,{b64_data}'

        cb = unilab_event_ctx.get()
        if cb:
            cb('GRAPHICAL_PLOT', json.dumps({
                'filename': filename,
                'fig': fig.number,
                'ver': _unilab_fig_versions.get(fig.number, 1),
                'script': unilab_script_ctx.get(),
                'data': data_uri,
                'meta': meta,
            }, allow_nan=False))

        script_ctx = unilab_script_ctx.get()
        script_suffix = f'::SCRIPT::{script_ctx}' if script_ctx else ''
        print(f'::GRAPHICAL_PLOT::{filename}::FIG::{fig.number}{script_suffix}')
        return str(save_path)
    except Exception as e:
        print(f"Error saving graph: {e}")
        return None


_unilab_save_plot = _unilab_refresh_graph
_unilab_hold = False


def clf(*args):
    fig = plt.gcf()
    _unilab_custom_fig_colors.discard(fig.number)
    plt.clf()
    _unilab_update_fig_version()
    _unilab_refresh_graph()


def cla():
    """Clears the current axes."""
    plt.cla()
    _unilab_update_fig_version()
    _unilab_refresh_graph()


def close(*args):
    """Closes figures. Supports 'all' or specific figure numbers."""
    if not args:
        plt.close()
    elif str(args[0]).lower() == 'all':
        plt.close('all')
    else:
        plt.close(args[0])


def _parse_matlab_style_args(args, target_func=None):
    """
    Universal parser for MATLAB-style positional and Name-Value pair arguments.
    Converts MATLAB property names to Matplotlib kwargs and normalizes colors/sizes.
    """
    MATLAB_PROPS = {
        'linecolor', 'linewidth', 'lw', 'markerfacecolor', 'mfc', 'markeredgecolor', 'mec',
        'markersize', 'ms', 'displayname', 'label', 'location', 'loc', 'orientation', 'box',
        'numcolumns', 'ncol', 'name', 'position', 'color', 'edgecolor', 'facecolor',
        'marker', 'linestyle', 'ls', 'alpha', 'facealpha', 'edgealpha', 'interpreter',
        'fontweight', 'fontsize', 'numbertitle', 'units', 'visible', 'menubar', 'toolbar',
        'resize', 'windowstate', 'renderer', 'outerposition', 'paperposition', 'tag',
        'userdata', 'grid', 'title', 'xlabel', 'ylabel', 'zlabel', 'xlim', 'ylim',
        'colormap', 'cmap', 'barwidth', 'width', 'numbins', 'bins', 'binwidth',
        'normalization', 'levels', 'levellist', 'showtext', 'filled', ' basevalue',
    }
    LEGEND_LOC_MAP = {
        'northeast': 'upper right',
        'northwest': 'upper left',
        'southeast': 'lower right',
        'southwest': 'lower left',
        'north': 'upper center',
        'south': 'lower center',
        'east': 'center right',
        'west': 'center left',
        'northeastoutside': 'upper left',
        'northwestoutside': 'upper right',
        'southeastoutside': 'lower left',
        'southwestoutside': 'lower right',
        'best': 'best',
        'bestoutside': 'best',
    }

    pos_args, kwargs, i = [], {}, 0
    n_args = builtins.len(args)
    while i < n_args:
        item = args[i]
        if i + 1 < n_args and isinstance(item, str) and item.strip().lower() in MATLAB_PROPS:
            key = item.strip().lower()
            val = args[i + 1]
            if key in ('linewidth', 'lw', 'markersize', 'ms', 'fontsize', 'alpha', 'facealpha'):
                try:
                    val = float(np.asarray(val).item())
                except Exception:
                    pass
            if key in ('color', 'linecolor', 'facecolor', 'edgecolor', 'markerfacecolor', 'mfc', 'markeredgecolor', 'mec'):
                val = _normalize_matlab_color(val)

            if key in ('linewidth', 'lw'):
                kwargs['linewidth'] = val
            elif key in ('markersize', 'ms'):
                kwargs['markersize'] = val
            elif key in ('markerfacecolor', 'mfc'):
                kwargs['markerfacecolor'] = val
            elif key in ('markeredgecolor', 'mec'):
                kwargs['markeredgecolor'] = val
            elif key in ('linestyle', 'ls'):
                kwargs['linestyle'] = str(val)
            elif key == 'marker':
                kwargs['marker'] = str(val)
            elif key in ('displayname', 'label'):
                kwargs['label'] = str(val)
            elif key in ('color', 'linecolor'):
                kwargs['color'] = val
            elif key == 'facecolor':
                if target_func in ('bar', 'barh', 'hist', 'histogram', 'area'):
                    kwargs['color'] = val
                else:
                    kwargs['facecolor'] = val
            elif key == 'edgecolor':
                kwargs['edgecolor'] = val
            elif key in ('alpha', 'facealpha'):
                kwargs['alpha'] = val
            elif key == 'edgealpha':
                kwargs.setdefault('alpha', float(np.asarray(val).item()) if np.asarray(val).size == 1 else 0.8)
            elif key in ('location', 'loc'):
                loc_str = str(val).strip().lower()
                kwargs['loc'] = LEGEND_LOC_MAP.get(loc_str, loc_str)
            elif key == 'orientation':
                if str(val).strip().lower() == 'horizontal':
                    kwargs['ncol'] = 4
            elif key == 'box':
                kwargs['frameon'] = str(val).strip().lower() in ('on', 'true', '1')
            elif key in ('numcolumns', 'ncol'):
                kwargs['ncol'] = int(np.asarray(val).item())
            elif key in ('colormap', 'cmap'):
                kwargs['cmap'] = str(val).strip().lower()
            elif key in ('barwidth', 'width'):
                w_f = float(np.asarray(val).item())
                if target_func == 'barh':
                    kwargs['height'] = w_f
                else:
                    kwargs['width'] = w_f
            elif key in ('numbins', 'bins'):
                kwargs['bins'] = int(np.asarray(val).item()) if np.asarray(val).size == 1 else _unilab_vec(val)
            elif key == 'binwidth':
                kwargs['binwidth'] = float(np.asarray(val).item())
            elif key == 'normalization':
                norm_str = str(val).strip().lower()
                if norm_str in ('pdf', 'probability'):
                    kwargs['density'] = True
            elif key in ('levels', 'levellist'):
                kwargs['levels'] = int(np.asarray(val).item()) if np.asarray(val).size == 1 else _unilab_vec(val)
            elif key == 'showtext':
                kwargs['showtext'] = str(val).strip().lower() in ('on', 'true', '1') or val is True
            elif key in ('interpreter', 'numbertitle', 'units', 'visible', 'menubar', 'toolbar', 'resize', 'windowstate', 'renderer', 'outerposition', 'paperposition', 'tag', 'userdata', 'name', 'position'):
                # Silently consume figure/text metadata properties unsupported by Matplotlib artists
                pass
            else:
                kwargs[key] = val
            i += 2
        else:
            pos_args.append(_unilab_vec(item))
            i += 1
    return pos_args, kwargs


def text(*args, **kwargs):
    args_list = list(args)
    target_ax = plt.gca()
    if args_list and hasattr(args_list[0], 'text'):
        target_ax = args_list.pop(0)
    p_args, p_kwargs = _parse_matlab_style_args(args_list, target_func='text')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    if 'fontsize' in extra_opts:
        p_kwargs['fontsize'] = float(extra_opts['fontsize'])
    if 'fontweight' in extra_opts:
        p_kwargs['fontweight'] = extra_opts['fontweight']
    p_kwargs.setdefault('fontsize', _unilab_plot_config['font_size'])
    p_kwargs.setdefault('color', _unilab_plot_config['fg_color'])
    res = target_ax.text(*p_args, **p_kwargs)
    _unilab_refresh_graph()
    return res


def _run_2d_line_plot(method_name, *args, **kwargs):
    args_list = list(args)
    target_ax = None
    if args_list and hasattr(args_list[0], method_name) and not isinstance(args_list[0], (np.ndarray, list, tuple)):
        target_ax = args_list.pop(0)

    p_args, p_kwargs = _parse_matlab_style_args(args_list, target_func=method_name)
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)

    ax = target_ax if target_ax is not None else plt.gca()
    if target_ax is None and not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()

    p_kwargs.setdefault('linewidth', _unilab_plot_config['line_width'])
    plot_fn = getattr(ax, method_name)
    res = plot_fn(*p_args, **p_kwargs)

    if _unilab_plot_config.get('show_grid', True):
        ax.grid(True, which='both', linestyle='--', alpha=0.45, color=_unilab_plot_config['grid_color'])
    _apply_extra_axes_opts(ax, extra_opts)
    if ('label' in p_kwargs or _unilab_plot_config.get('show_legend', False)) and ax.get_legend_handles_labels()[0]:
        ax.legend(loc='best', fontsize=max(7.5, _unilab_plot_config['font_size'] - 1.0), framealpha=0.88)

    if target_ax is None:
        _unilab_refresh_graph()
    elif hasattr(target_ax, 'figure'):
        _unilab_refresh_graph(fig=target_ax.figure)
    return res


def plot(*args, **kwargs):
    return _run_2d_line_plot('plot', *args, **kwargs)


def semilogx(*args, **kwargs):
    return _run_2d_line_plot('semilogx', *args, **kwargs)


def semilogy(*args, **kwargs):
    return _run_2d_line_plot('semilogy', *args, **kwargs)


def loglog(*args, **kwargs):
    return _run_2d_line_plot('loglog', *args, **kwargs)


def errorbar(*args, **kwargs):
    args_list = list(args)
    target_ax = plt.gca()
    if args_list and hasattr(args_list[0], 'errorbar'):
        target_ax = args_list.pop(0)
    p_args, p_kwargs = _parse_matlab_style_args(args_list, target_func='errorbar')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    if not _get_hold_state():
        target_ax.cla()
        _unilab_update_fig_version()
    p_kwargs.setdefault('linewidth', _unilab_plot_config['line_width'])
    p_kwargs.setdefault('capsize', 3.5)
    # Handle LineSpec string if passed as 4th argument e.g. errorbar(x, y, err, 'o-')
    fmt = None
    clean_pos = []
    for a in p_args:
        if isinstance(a, str):
            fmt = a
        else:
            clean_pos.append(a)
    if fmt:
        p_kwargs['fmt'] = fmt
    res = target_ax.errorbar(*clean_pos, **p_kwargs)
    _apply_extra_axes_opts(target_ax, extra_opts)
    _unilab_refresh_graph()
    return res


def polarplot(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='polarplot')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    fig = plt.gcf()
    if not fig.axes or getattr(fig.gca(), 'name', '') != 'polar':
        if not _get_hold_state():
            fig.clf()
            _unilab_update_fig_version()
        ax = fig.add_subplot(111, projection='polar')
    else:
        ax = fig.gca()
        if not _get_hold_state():
            ax.cla()
            _unilab_update_fig_version()
    p_kwargs.setdefault('linewidth', _unilab_plot_config['line_width'])
    res = ax.plot(*p_args, **p_kwargs)
    _apply_extra_axes_opts(ax, extra_opts)
    _unilab_refresh_graph()
    return res


polar = polarplot


def pie(x, explode=None, labels=None, *args, **kwargs):
    _, p_kwargs = _parse_matlab_style_args(args, target_func='pie')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()
    x_vec = np.asarray(_unilab_vec(x), dtype=float).flatten()
    if isinstance(explode, (list, tuple)) and len(explode) > 0 and isinstance(explode[0], str):
        labels = explode
        explode = None
    exp_vec = np.asarray(_unilab_vec(explode), dtype=float).flatten() if explode is not None and np.asarray(explode).size > 0 else None
    lbl_list = [str(l) for l in (labels.flatten().tolist() if isinstance(labels, np.ndarray) else labels)] if labels is not None else None
    palette = _get_active_color_cycle()
    colors = [palette[i % len(palette)] for i in range(len(x_vec))]
    res = ax.pie(
        x_vec,
        explode=exp_vec,
        labels=lbl_list,
        colors=colors,
        autopct='%1.1f%%',
        textprops={'fontsize': _unilab_plot_config['font_size'], 'color': _unilab_plot_config['fg_color']},
    )
    _apply_extra_axes_opts(ax, extra_opts)
    _unilab_refresh_graph()
    return res


def fplot(fun, limits=None, *args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='plot')
    p_kwargs.update(kwargs)
    x_min, x_max = -5.0, 5.0
    if limits is not None:
        if isinstance(limits, str):
            p_args.insert(0, limits)
        else:
            lim_arr = np.asarray(limits, dtype=float).flatten()
            if lim_arr.size >= 2:
                x_min, x_max = float(lim_arr[0]), float(lim_arr[1])
    x_vals = np.linspace(x_min, x_max, 400)
    if _is_symbolic(fun):
        import sympy
        free_syms = sorted(list(fun.free_symbols), key=lambda s: s.name)
        var = free_syms[0] if free_syms else sympy.Symbol('x')
        f_num = sympy.lambdify(var, fun, 'numpy')
        y_vals = f_num(x_vals)
    elif callable(fun):
        try:
            y_vals = unilab_call(fun, x_vals)
        except Exception:
            y_vals = np.array([float(unilab_call(fun, xv)) for xv in x_vals])
    else:
        y_vals = np.asarray(fun)
    if np.isscalar(y_vals):
        y_vals = np.full_like(x_vals, float(y_vals))
    return plot(x_vals, y_vals, *p_args, **p_kwargs)


ezplot = fplot


def fill(*args, **kwargs):
    args_list = list(args)
    target_ax = plt.gca()
    if args_list and hasattr(args_list[0], 'fill'):
        target_ax = args_list.pop(0)
    p_args, p_kwargs = _parse_matlab_style_args(args_list, target_func='fill')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    if len(p_args) >= 3 and not isinstance(p_args[2], str):
        c_third = _normalize_matlab_color(p_args[2])
        if isinstance(c_third, (str, tuple)):
            p_kwargs.setdefault('facecolor', c_third)
            p_args = p_args[:2] + p_args[3:]
    if not _get_hold_state():
        target_ax.cla()
        _unilab_update_fig_version()
    res = target_ax.fill(*p_args, **p_kwargs)
    _apply_extra_axes_opts(target_ax, extra_opts)
    _unilab_refresh_graph()
    return res


patch = fill


def xlim(*args):
    args_list = list(args)
    target_ax = plt.gca()
    if args_list and hasattr(args_list[0], 'set_xlim'):
        target_ax = args_list.pop(0)
    if not args_list:
        return np.array(target_ax.get_xlim())
    val = args_list[0]
    if isinstance(val, str):
        if val.lower() == 'auto':
            target_ax.autoscale(enable=True, axis='x')
        elif val.lower() == 'tight':
            target_ax.autoscale(enable=True, axis='x', tight=True)
    elif isinstance(val, (list, tuple, np.ndarray)):
        val_arr = np.asarray(val, dtype=float).flatten()
        if len(val_arr) >= 2:
            target_ax.set_xlim(float(val_arr[0]), float(val_arr[1]))
    elif builtins.len(args_list) >= 2:
        target_ax.set_xlim(float(args_list[0]), float(args_list[1]))
    _unilab_refresh_graph()
    return np.array(target_ax.get_xlim())


def ylim(*args):
    args_list = list(args)
    target_ax = plt.gca()
    if args_list and hasattr(args_list[0], 'set_ylim'):
        target_ax = args_list.pop(0)
    if not args_list:
        return np.array(target_ax.get_ylim())
    val = args_list[0]
    if isinstance(val, str):
        if val.lower() == 'auto':
            target_ax.autoscale(enable=True, axis='y')
        elif val.lower() == 'tight':
            target_ax.autoscale(enable=True, axis='y', tight=True)
    elif isinstance(val, (list, tuple, np.ndarray)):
        val_arr = np.asarray(val, dtype=float).flatten()
        if len(val_arr) >= 2:
            target_ax.set_ylim(float(val_arr[0]), float(val_arr[1]))
    elif builtins.len(args_list) >= 2:
        target_ax.set_ylim(float(args_list[0]), float(args_list[1]))
    _unilab_refresh_graph()
    return np.array(target_ax.get_ylim())


def unilab_ascii_plot(y, x=None, height=20, width=60, plot_type='line'):
    try:
        if x is None or (isinstance(x, (list, np.ndarray)) and builtins.len(x) == 0):
            if isinstance(y, (list, np.ndarray)): x = np.arange(builtins.len(y))
            else: x = np.arange(1); y = [y]
        y = np.asarray(y).flatten()
        x = np.asarray(x).flatten()
        if y.size == 0: return ""
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
            if 0 <= cx < width and 0 <= cy < height: canvas[cy][cx] = char
        for i in range(builtins.len(x)):
            px = int((x[i] - xmin) / (xmax - xmin) * (width - 1))
            py = int((y[i] - ymin) / (ymax - ymin) * (height - 1))
            py = height - 1 - py
            if plot_type == 'line' and i > 0:
                prev_px = int((x[i-1] - xmin) / (xmax - xmin) * (width - 1))
                prev_py = height - 1 - int((y[i-1] - ymin) / (ymax - ymin) * (height - 1))
                dx = builtins.abs(px - prev_px)
                dy = builtins.abs(py - prev_py)
                sx = 1 if prev_px < px else -1
                sy = 1 if prev_py < py else -1
                err = dx - dy
                cx, cy = prev_px, prev_py
                while True:
                    set_pixel(cx, cy, '*')
                    if cx == px and cy == py: break
                    e2 = 2 * err
                    if e2 > -dy: err -= dy; cx += sx
                    if e2 < dx: err += dx; cy += sy
            elif plot_type == 'scatter': set_pixel(px, py, 'o')
            elif plot_type == 'bar':
                bar_top = py
                bar_bottom = height - 1 - int((0 - ymin) / (ymax - ymin) * (height - 1))
                bar_bottom = builtins.max(0, builtins.min(height - 1, bar_bottom))
                for sy in range(builtins.min(bar_top, bar_bottom), builtins.max(bar_top, bar_bottom) + 1): set_pixel(px, sy, '#')
            elif plot_type == 'stem':
                set_pixel(px, py, 'o')
                zero_y = height - 1 - int((0 - ymin) / (ymax - ymin) * (height - 1))
                zero_y = builtins.max(0, builtins.min(height - 1, zero_y))
                step_dir = 1 if py < zero_y else -1
                for sy in range(py + step_dir, zero_y + step_dir, step_dir): set_pixel(px, sy, '|')
            elif plot_type == 'stairs' and i > 0:
                prev_px = int((x[i-1] - xmin) / (xmax - xmin) * (width - 1))
                prev_py = height - 1 - int((y[i-1] - ymin) / (ymax - ymin) * (height - 1))
                for cx in range(builtins.min(prev_px, px), builtins.max(prev_px, px) + 1): set_pixel(cx, prev_py, '*')
                for cy in range(builtins.min(prev_py, py), builtins.max(prev_py, py) + 1): set_pixel(px, cy, '*')
            elif plot_type == 'area':
                set_pixel(px, py, '*')
                zero_y = height - 1 - int((0 - ymin) / (ymax - ymin) * (height - 1))
                zero_y = builtins.max(0, builtins.min(height - 1, zero_y))
                for sy in range(builtins.min(py, zero_y), builtins.max(py, zero_y) + 1): set_pixel(px, sy, '.')
            else: set_pixel(px, py, '*')
        res = [f" {ymax:8.2f} |" + "".join(canvas[0]) + "|"]
        for i in range(1, height - 1): res.append("          |" + "".join(canvas[i]) + "|")
        res.append(f" {ymin:8.2f} |" + "".join(canvas[height-1]) + "|")
        res.append("           +" + "-" * width + "+")
        xmin_str, xmax_str = f"{xmin:.2f}", f"{xmax:.2f}"
        res.append("            " + xmin_str + " " * (width - builtins.len(xmin_str) - builtins.len(xmax_str)) + xmax_str)
        return "\n".join(res)
    except Exception as e: return f"Error generating ASCII plot: {e}"


def unilab_ascii_heatmap(M, height=15, width=40):
    try:
        M = np.asarray(M)
        if M.size == 0: return ""
        m_min, m_max = np.min(M), np.max(M)
        if m_max == m_min: m_max += 1
        orig_h, orig_w = M.shape
        res_h, res_w = int(height), int(width)
        ramp = " .:-=+*#%@"
        res = ["+" + "-" * res_w + "+"]
        for r in range(res_h):
            row = "|"
            orig_r = int(r * orig_h / res_h)
            for c in range(res_w):
                orig_c = int(c * orig_w / res_w)
                idx = int((M[orig_r, orig_c] - m_min) / (m_max - m_min) * (builtins.len(ramp) - 1))
                row += ramp[builtins.max(0, builtins.min(builtins.len(ramp)-1, idx))]
            res.append(row + "|")
        res.append("+" + "-" * res_w + "+")
        return "\n".join(res)
    except Exception as e: return f"Error generating ASCII heatmap: {e}"


def is_web(): return os.environ.get('UNILAB_WEB_MODE') == '1'


def terminal_plot_hd(y, x=None, height=None, width=None, type='line', **kwargs):
    cfg = _unilab_plot_config
    grid_state = kwargs.pop('grid', cfg.get('show_grid', True))
    if x is None or (isinstance(x, (list, np.ndarray)) and builtins.len(x) == 0):
        if isinstance(y, (list, np.ndarray)): x = np.arange(builtins.len(y))
        else: x = np.arange(1); y = [y]
    x, y = _unilab_vec(x), _unilab_vec(y)
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()
    lw = float(cfg.get('line_width', 1.8))
    palette = _get_active_color_cycle()
    if type == 'line':
        ax.plot(x, y, linewidth=lw, color=palette[0])
    elif type == 'area':
        ax.fill_between(x, y, alpha=0.3, color=palette[0])
        ax.plot(x, y, linewidth=lw, color=palette[0])
    elif type == 'stairs':
        ax.step(x, y, where='mid', linewidth=lw, color=palette[0])
    elif type == 'scatter':
        ax.scatter(x, y, s=float(cfg.get('marker_size', 6.0)) ** 2 * 1.4, color=palette[0])
    elif type == 'bar':
        ax.bar(x, y, width=0.75, color=palette[0], edgecolor=cfg['spine_color'], linewidth=0.9)
    elif type == 'stem':
        markerline, stemlines, baseline = ax.stem(x, y)
        plt.setp(stemlines, 'linewidth', lw, 'color', palette[0])
        plt.setp(markerline, 'markersize', cfg.get('marker_size', 6.0), 'color', palette[0])
    elif type == 'box':
        ax.boxplot(y, patch_artist=True, boxprops=dict(linewidth=1.4, facecolor=palette[0], alpha=0.6), medianprops=dict(linewidth=1.8, color='#f7768e'))
    ax.grid(grid_state == 'on' or grid_state or grid_state == 1, linestyle='--', alpha=0.45, linewidth=0.75, color=cfg['grid_color'])
    _unilab_refresh_graph()


def terminal_heatmap_hd(M):
    cfg = _unilab_plot_config
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()
    im = ax.imshow(M, cmap=str(cfg.get('colormap', 'viridis')).lower(), interpolation='nearest', aspect='auto')
    if len(ax.figure.axes) <= 1:
        ax.figure.colorbar(im, ax=ax)
    _unilab_refresh_graph()


def stem(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='stem')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()
    p_args = [a for a in p_args if not (isinstance(a, str) and a.lower() == 'filled')]
    lw = float(p_kwargs.pop('linewidth', _unilab_plot_config['line_width']))
    ms = float(p_kwargs.pop('markersize', _unilab_plot_config['marker_size']))
    col = p_kwargs.pop('color', _get_active_color_cycle()[len(ax.lines) % len(_get_active_color_cycle())])
    linefmt = p_kwargs.pop('linestyle', '-')
    markerfmt = p_kwargs.pop('marker', 'o')
    lbl = p_kwargs.pop('label', None)
    # Extract positional LineSpec if present
    clean_pos = []
    for a in p_args:
        if isinstance(a, str):
            linefmt = a
        else:
            clean_pos.append(a)
    markerline, stemlines, baseline = ax.stem(*clean_pos, linefmt=linefmt, markerfmt=markerfmt, label=lbl)
    plt.setp(stemlines, 'linewidth', lw, 'color', col)
    plt.setp(markerline, 'markersize', ms, 'color', col, 'markerfacecolor', p_kwargs.get('markerfacecolor', col))
    plt.setp(baseline, 'linewidth', 1.0, 'color', _unilab_plot_config['spine_color'])
    _apply_extra_axes_opts(ax, extra_opts)
    if lbl:
        ax.legend(loc='best', fontsize=max(7.5, _unilab_plot_config['font_size'] - 1.0))
    _unilab_refresh_graph()
    return markerline, stemlines, baseline


def stairs(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='stairs')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()
    p_kwargs.setdefault('linewidth', _unilab_plot_config['line_width'])
    p_kwargs.setdefault('where', 'post')
    clean_pos = []
    fmt = None
    for a in p_args:
        if isinstance(a, str):
            fmt = a
        else:
            clean_pos.append(a)
    if len(clean_pos) == 1:
        y = np.asarray(clean_pos[0]).flatten()
        x = np.arange(1, len(y) + 1)
        clean_pos = [x, y]
    if fmt:
        res = ax.step(clean_pos[0], clean_pos[1], fmt, **p_kwargs)
    else:
        res = ax.step(clean_pos[0], clean_pos[1], **p_kwargs)
    _apply_extra_axes_opts(ax, extra_opts)
    if 'label' in p_kwargs:
        ax.legend(loc='best', fontsize=max(7.5, _unilab_plot_config['font_size'] - 1.0))
    _unilab_refresh_graph()
    return res


def area(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='area')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()
    p_kwargs.setdefault('alpha', 0.45)
    p_kwargs.setdefault('linewidth', _unilab_plot_config['line_width'])
    palette = _get_active_color_cycle()
    p_kwargs.setdefault('color', palette[len(ax.collections) % len(palette)])
    if builtins.len(p_args) == 1:
        y = np.asarray(p_args[0]).flatten()
        x = np.arange(1, builtins.len(y) + 1)
        res = ax.fill_between(x, y, **p_kwargs)
    elif builtins.len(p_args) >= 2:
        x, y = p_args[0], p_args[1]
        res = ax.fill_between(x, y, **p_kwargs)
    else:
        res = None
    _apply_extra_axes_opts(ax, extra_opts)
    if 'label' in p_kwargs:
        ax.legend(loc='best', fontsize=max(7.5, _unilab_plot_config['font_size'] - 1.0))
    _unilab_refresh_graph()
    return res


def scatter(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='scatter')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()
    p_args = [a for a in p_args if not (isinstance(a, str) and a.lower() == 'filled')]
    if 'markersize' in p_kwargs:
        p_kwargs['s'] = float(p_kwargs.pop('markersize'))
    if 'markerfacecolor' in p_kwargs:
        p_kwargs.setdefault('color', p_kwargs.pop('markerfacecolor'))
    if 'markeredgecolor' in p_kwargs:
        p_kwargs.setdefault('edgecolors', p_kwargs.pop('markeredgecolor'))
    if builtins.len(p_args) >= 4:
        c_arg = p_args[3]
        if isinstance(c_arg, str):
            p_kwargs.setdefault('color', _normalize_matlab_color(c_arg))
        else:
            p_kwargs.setdefault('c', c_arg)
            p_kwargs.setdefault('cmap', str(_unilab_plot_config.get('colormap', 'viridis')).lower())
        p_args = p_args[:3]
    if builtins.len(p_args) == 3:
        if isinstance(p_args[2], str):
            c_col = _normalize_matlab_color(p_args[2])
            p_kwargs.setdefault('color', c_col)
            p_args = p_args[:2]
        else:
            p_kwargs.setdefault('s', p_args[2])
            p_args = p_args[:2]
    p_kwargs.setdefault('s', float(_unilab_plot_config.get('marker_size', 6.0)) ** 2 * 1.3)
    p_kwargs.setdefault('alpha', 0.85)
    res = ax.scatter(*p_args, **p_kwargs)
    _apply_extra_axes_opts(ax, extra_opts)
    if 'label' in p_kwargs:
        ax.legend(loc='best', fontsize=max(7.5, _unilab_plot_config['font_size'] - 1.0))
    _unilab_refresh_graph()
    return res


def bar(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='bar')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()
    # Filter MATLAB bar style strings ('grouped', 'stacked', 'hist')
    bar_mode = 'grouped'
    clean_pos = []
    for a in p_args:
        if isinstance(a, str) and a.lower() in ('grouped', 'stacked', 'hist', 'histc'):
            bar_mode = a.lower()
        elif isinstance(a, str):
            p_kwargs.setdefault('color', _normalize_matlab_color(a))
        else:
            clean_pos.append(a)
    if len(clean_pos) == 1:
        y = np.asarray(clean_pos[0])
        if y.ndim == 2 and min(y.shape) > 1:
            # Multi-series bar chart
            n_groups, n_series = y.shape
            x_base = np.arange(1, n_groups + 1)
            palette = _get_active_color_cycle()
            res = []
            if bar_mode == 'stacked':
                bottom = np.zeros(n_groups)
                for s_i in range(n_series):
                    r = ax.bar(x_base, y[:, s_i], bottom=bottom, color=palette[s_i % len(palette)], label=f'Series {s_i + 1}')
                    bottom += y[:, s_i]
                    res.append(r)
            else:
                total_w = float(p_kwargs.pop('width', 0.8))
                bar_w = total_w / n_series
                for s_i in range(n_series):
                    offset = (s_i - (n_series - 1) / 2.0) * bar_w
                    r = ax.bar(x_base + offset, y[:, s_i], width=bar_w * 0.92, color=palette[s_i % len(palette)], label=f'Series {s_i + 1}')
                    res.append(r)
            _apply_extra_axes_opts(ax, extra_opts)
            _unilab_refresh_graph()
            return res
        y_flat = y.flatten()
        x = np.arange(1, len(y_flat) + 1)
        clean_pos = [x, y_flat]
    elif len(clean_pos) >= 3 and np.asarray(clean_pos[2]).size == 1:
        p_kwargs.setdefault('width', float(np.asarray(clean_pos[2]).item()))
        clean_pos = clean_pos[:2]
    p_kwargs.setdefault('edgecolor', _unilab_plot_config['spine_color'])
    p_kwargs.setdefault('linewidth', 0.8)
    p_kwargs.setdefault('alpha', 0.9)
    res = ax.bar(*clean_pos, **p_kwargs)
    _apply_extra_axes_opts(ax, extra_opts)
    if 'label' in p_kwargs:
        ax.legend(loc='best', fontsize=max(7.5, _unilab_plot_config['font_size'] - 1.0))
    _unilab_refresh_graph()
    return res


def barh(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='barh')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()
    clean_pos = [a for a in p_args if not isinstance(a, str)]
    p_kwargs.setdefault('edgecolor', _unilab_plot_config['spine_color'])
    p_kwargs.setdefault('linewidth', 0.8)
    p_kwargs.setdefault('alpha', 0.9)
    if builtins.len(clean_pos) == 1:
        y = np.asarray(clean_pos[0]).flatten()
        x = np.arange(1, len(y) + 1)
        res = ax.barh(x, y, **p_kwargs)
    else:
        res = ax.barh(clean_pos[0], clean_pos[1], **p_kwargs)
    _apply_extra_axes_opts(ax, extra_opts)
    _unilab_refresh_graph()
    return res


def hist(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='hist')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()
    if len(p_args) >= 1:
        data = np.asarray(p_args[0], dtype=float).flatten()
        if len(p_args) >= 2 and np.asarray(p_args[1]).size > 0:
            b_arg = p_args[1]
            p_kwargs['bins'] = int(np.asarray(b_arg).item()) if np.asarray(b_arg).size == 1 else _unilab_vec(b_arg)
        if 'binwidth' in p_kwargs:
            bw = float(p_kwargs.pop('binwidth'))
            if bw > 0 and data.size > 1:
                p_kwargs['bins'] = max(1, int(np.ceil((np.max(data) - np.min(data)) / bw)))
        p_args = [data]
    p_kwargs.setdefault('edgecolor', _unilab_plot_config['bg_color'])
    p_kwargs.setdefault('linewidth', 0.8)
    p_kwargs.setdefault('alpha', 0.85)
    counts, bin_edges, patches = ax.hist(*p_args, **p_kwargs)
    _apply_extra_axes_opts(ax, extra_opts)
    _unilab_refresh_graph()
    bin_centers = 0.5 * (bin_edges[:-1] + bin_edges[1:])
    return counts, bin_centers


histogram = hist


def boxplot(x, *args, **kwargs):
    _, p_kwargs = _parse_matlab_style_args(args, target_func='boxplot')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()
    palette = _get_active_color_cycle()
    res = ax.boxplot(
        np.asarray(x),
        patch_artist=True,
        boxprops=dict(facecolor=palette[0], alpha=0.55, edgecolor=_unilab_plot_config['fg_color'], linewidth=1.2),
        medianprops=dict(color='#f7768e', linewidth=1.8),
        whiskerprops=dict(color=_unilab_plot_config['muted_fg_color'], linewidth=1.1),
        capprops=dict(color=_unilab_plot_config['muted_fg_color'], linewidth=1.1),
    )
    _apply_extra_axes_opts(ax, extra_opts)
    _unilab_refresh_graph()
    return res


def title(*args, **kwargs):
    args_list = list(args)
    target = None
    if args_list and hasattr(args_list[0], 'set_title'):
        target = args_list.pop(0)
    p_args, p_kwargs = _parse_matlab_style_args(args_list, target_func='title')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    cfg = _unilab_plot_config
    fs = float(extra_opts.get('fontsize', cfg['font_size'] + 1.5))
    fw = extra_opts.get('fontweight', '600')
    p_kwargs.setdefault('fontsize', fs)
    p_kwargs.setdefault('fontweight', fw)
    p_kwargs.setdefault('color', cfg['fg_color'])
    txt = str(p_args[0]) if p_args else ""
    ax = target if target is not None else plt.gca()
    ax._unilab_saved_title = txt
    res = ax.set_title(txt if cfg.get('show_labels', True) else "", **p_kwargs)
    _unilab_refresh_graph()
    return res


def sgtitle(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='title')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    cfg = _unilab_plot_config
    fs = float(extra_opts.get('fontsize', cfg['font_size'] + 2.5))
    txt = str(p_args[0]) if p_args else ""
    res = plt.gcf().suptitle(txt, fontsize=fs, fontweight='600', color=cfg['fg_color'])
    _unilab_refresh_graph()
    return res


def xlabel(*args, **kwargs):
    args_list = list(args)
    target = None
    if args_list and hasattr(args_list[0], 'set_xlabel'):
        target = args_list.pop(0)
    p_args, p_kwargs = _parse_matlab_style_args(args_list, target_func='xlabel')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    cfg = _unilab_plot_config
    fs = float(extra_opts.get('fontsize', cfg['font_size']))
    p_kwargs.setdefault('fontsize', fs)
    p_kwargs.setdefault('color', cfg['fg_color'])
    txt = str(p_args[0]) if p_args else ""
    ax = target if target is not None else plt.gca()
    ax._unilab_saved_xlabel = txt
    res = ax.set_xlabel(txt if cfg.get('show_labels', True) else "", **p_kwargs)
    _unilab_refresh_graph()
    return res


def ylabel(*args, **kwargs):
    args_list = list(args)
    target = None
    if args_list and hasattr(args_list[0], 'set_ylabel'):
        target = args_list.pop(0)
    p_args, p_kwargs = _parse_matlab_style_args(args_list, target_func='ylabel')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    cfg = _unilab_plot_config
    fs = float(extra_opts.get('fontsize', cfg['font_size']))
    p_kwargs.setdefault('fontsize', fs)
    p_kwargs.setdefault('color', cfg['fg_color'])
    txt = str(p_args[0]) if p_args else ""
    ax = target if target is not None else plt.gca()
    ax._unilab_saved_ylabel = txt
    res = ax.set_ylabel(txt if cfg.get('show_labels', True) else "", **p_kwargs)
    _unilab_refresh_graph()
    return res


def zlabel(*args, **kwargs):
    args_list = list(args)
    target = None
    if args_list and hasattr(args_list[0], 'set_zlabel'):
        target = args_list.pop(0)
    p_args, p_kwargs = _parse_matlab_style_args(args_list, target_func='zlabel')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    cfg = _unilab_plot_config
    fs = float(extra_opts.get('fontsize', cfg['font_size']))
    p_kwargs.setdefault('fontsize', fs)
    p_kwargs.setdefault('color', cfg['fg_color'])
    txt = str(p_args[0]) if p_args else ""
    ax = target if target is not None else plt.gca()
    ax._unilab_saved_zlabel = txt
    res = ax.set_zlabel(txt if cfg.get('show_labels', True) else "", **p_kwargs) if hasattr(ax, 'set_zlabel') else None
    _unilab_refresh_graph()
    return res


def gca(): return plt.gca()
def gcf(): return plt.gcf()


def view(*args):
    ax = plt.gca()
    if not args:
        if hasattr(ax, 'azim') and hasattr(ax, 'elev'):
            return ax.azim, ax.elev
        return 0.0, 90.0
    if builtins.len(args) == 1:
        v = args[0]
        if isinstance(v, (list, tuple, np.ndarray)):
            v_flat = np.asarray(v, dtype=float).flatten()
            if builtins.len(v_flat) >= 2 and hasattr(ax, 'view_init'):
                ax.view_init(elev=float(v_flat[1]), azim=float(v_flat[0]))
        elif int(v) == 2 and hasattr(ax, 'view_init'):
            ax.view_init(elev=90.0, azim=-90.0)
        elif int(v) == 3 and hasattr(ax, 'view_init'):
            ax.view_init(elev=30.0, azim=-37.5)
    elif builtins.len(args) >= 2 and hasattr(ax, 'view_init'):
        ax.view_init(elev=float(args[1]), azim=float(args[0]))
    _unilab_refresh_graph()


def zlim(*args):
    args_list = list(args)
    target_ax = plt.gca()
    if args_list and hasattr(args_list[0], 'set_zlim'):
        target_ax = args_list.pop(0)
    if not args_list:
        return np.array(target_ax.get_zlim()) if hasattr(target_ax, 'get_zlim') else np.array([0.0, 1.0])
    val = args_list[0]
    res = None
    if hasattr(target_ax, 'set_zlim'):
        if isinstance(val, (list, tuple, np.ndarray)):
            val_arr = np.asarray(val, dtype=float).flatten()
            if builtins.len(val_arr) >= 2:
                res = target_ax.set_zlim(val_arr[0], val_arr[1])
        elif builtins.len(args_list) >= 2:
            res = target_ax.set_zlim(float(args_list[0]), float(args_list[1]))
    _unilab_refresh_graph()
    return res


def figure(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='figure')
    kwargs.update(p_kwargs)
    has_custom_color = False
    if 'color' in kwargs:
        c = _normalize_matlab_color(kwargs.pop('color'))
        if c is not None:
            kwargs['facecolor'] = c
            has_custom_color = True
    allowed_fig_kwargs = {
        'num', 'figsize', 'dpi', 'facecolor', 'edgecolor',
        'frameon', 'clear', 'layout', 'tight_layout', 'constrained_layout'
    }
    clean_kwargs = {k: v for k, v in kwargs.items() if k in allowed_fig_kwargs}
    clean_kwargs.setdefault('figsize', (7.2, 4.6))
    clean_kwargs.setdefault('dpi', int(_unilab_plot_config.get('dpi', 130)))
    if p_args and isinstance(p_args[0], (int, float, np.integer, np.floating)):
        fig = plt.figure(int(p_args[0]), **clean_kwargs)
    else:
        fig = plt.figure(**clean_kwargs)
    if has_custom_color:
        _unilab_custom_fig_colors.add(fig.number)
    return fig


def subplot(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='subplot')
    kwargs.update(p_kwargs)
    _extract_extra_axes_opts(kwargs)
    p_args = [int(a) if isinstance(a, (float, np.floating, np.integer)) else a for a in p_args]
    res = plt.subplot(*p_args, **kwargs)
    return res


def hold(*args):
    args_list = list(args)
    if args_list and hasattr(args_list[0], 'plot'):
        args_list.pop(0)
    state = args_list[0] if args_list else 'on'
    val = str(state).lower()
    _set_hold_state(val == 'on' or val == '1' or state is True)


def grid(*args, **kwargs):
    args_list = list(args)
    target = plt.gca()
    if args_list and hasattr(args_list[0], 'grid'):
        target = args_list.pop(0)
    state = args_list[0] if args_list else 'on'
    state_str = str(state).lower()
    cfg = _unilab_plot_config
    if state_str == 'minor':
        target.grid(True, which='both', linestyle='--', alpha=0.45, color=cfg['grid_color'])
        target.minorticks_on()
    else:
        visible = state_str in ('on', '1', 'true') or state is True
        if visible:
            target.grid(True, which='both', linestyle='--', alpha=0.45, color=cfg['grid_color'], **kwargs)
        else:
            target.grid(False)
    _unilab_refresh_graph()


def box(*args):
    args_list = list(args)
    ax = plt.gca()
    if args_list and hasattr(args_list[0], 'spines'):
        ax = args_list.pop(0)
    state = str(args_list[0]).lower() if args_list else 'on'
    show_box = state in ('on', '1', 'true')
    if hasattr(ax, 'spines'):
        if 'top' in ax.spines:
            ax.spines['top'].set_visible(show_box)
        if 'right' in ax.spines:
            ax.spines['right'].set_visible(show_box)
    _unilab_refresh_graph()


def axis(*args):
    args_list = list(args)
    target = plt.gca()
    if args_list and hasattr(args_list[0], 'axis'):
        target = args_list.pop(0)
    arg0 = args_list[0] if args_list else None
    if isinstance(arg0, np.ndarray):
        arg0 = arg0.flatten().tolist()
    res = target.axis(arg0) if args_list else target.axis()
    _unilab_refresh_graph()
    return res


def yyaxis(side='left'):
    fig = plt.gcf()
    ax = plt.gca()
    side_str = str(side).strip().lower()
    if side_str == 'right':
        twin = getattr(ax, '_unilab_twin_ax', None)
        if twin is None:
            twin = ax.twinx()
            ax._unilab_twin_ax = twin
            twin._unilab_parent_ax = ax
        plt.sca(twin)
        return twin
    else:
        parent = getattr(ax, '_unilab_parent_ax', None)
        if parent is not None:
            plt.sca(parent)
            return parent
        return ax


def xticks(ticks=None, labels=None):
    ax = plt.gca()
    if ticks is None:
        return np.array(ax.get_xticks())
    t_vec = _unilab_vec(ticks)
    if labels is not None:
        ax.set_xticks(t_vec, [str(l) for l in np.asarray(labels).flatten()])
    else:
        ax.set_xticks(t_vec)
    _unilab_refresh_graph()
    return np.array(t_vec)


def yticks(ticks=None, labels=None):
    ax = plt.gca()
    if ticks is None:
        return np.array(ax.get_yticks())
    t_vec = _unilab_vec(ticks)
    if labels is not None:
        ax.set_yticks(t_vec, [str(l) for l in np.asarray(labels).flatten()])
    else:
        ax.set_yticks(t_vec)
    _unilab_refresh_graph()
    return np.array(t_vec)


def xticklabels(labels):
    ax = plt.gca()
    lbls = [str(l) for l in (labels.flatten() if isinstance(labels, np.ndarray) else labels)]
    ax.set_xticklabels(lbls)
    _unilab_refresh_graph()


def yticklabels(labels):
    ax = plt.gca()
    lbls = [str(l) for l in (labels.flatten() if isinstance(labels, np.ndarray) else labels)]
    ax.set_yticklabels(lbls)
    _unilab_refresh_graph()


def xtickangle(angle):
    ax = plt.gca()
    ax.tick_params(axis='x', rotation=float(angle))
    _unilab_refresh_graph()


def ytickangle(angle):
    ax = plt.gca()
    ax.tick_params(axis='y', rotation=float(angle))
    _unilab_refresh_graph()


def caxis(limits=None):
    ax = plt.gca()
    mappable = None
    if getattr(ax, 'images', None):
        mappable = ax.images[-1]
    elif getattr(ax, 'collections', None):
        mappable = ax.collections[-1]
    if limits is None:
        return np.array(mappable.get_clim()) if mappable and hasattr(mappable, 'get_clim') else np.array([0.0, 1.0])
    lim_arr = np.asarray(limits, dtype=float).flatten()
    if mappable and hasattr(mappable, 'set_clim') and lim_arr.size >= 2:
        mappable.set_clim(float(lim_arr[0]), float(lim_arr[1]))
    _unilab_refresh_graph()


clim = caxis


def legend(*args, **kwargs):
    if len(args) == 1 and isinstance(args[0], str) and args[0].strip().lower() in ('off', 'hide', 'boxoff', 'boxon'):
        cmd = args[0].strip().lower()
        ax = plt.gca()
        leg = ax.get_legend()
        if cmd in ('off', 'hide') and leg is not None:
            leg.remove()
        elif cmd == 'boxoff' and leg is not None:
            leg.set_frame_on(False)
        elif cmd == 'boxon' and leg is not None:
            leg.set_frame_on(True)
        _unilab_refresh_graph()
        return
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='legend')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    cfg = _unilab_plot_config
    fs = float(extra_opts.get('fontsize', max(7.5, cfg['font_size'] - 1.0)))
    p_kwargs.setdefault('fontsize', fs)
    p_kwargs.setdefault('facecolor', cfg['axes_bg_color'])
    p_kwargs.setdefault('edgecolor', cfg['spine_color'])
    p_kwargs.setdefault('labelcolor', cfg['fg_color'])
    p_kwargs.setdefault('framealpha', 0.88)
    p_kwargs.setdefault('loc', 'best')
    if len(p_args) == 1 and isinstance(p_args[0], (list, tuple, np.ndarray)):
        lbls = [str(x) for x in (p_args[0].flatten().tolist() if isinstance(p_args[0], np.ndarray) else p_args[0])]
        p_args = [lbls]
    elif p_args and builtins.all(isinstance(a, str) for a in p_args):
        p_args = [list(p_args)]
    plt.gca().legend(*p_args, **p_kwargs)
    _unilab_refresh_graph()


def contour(*args, **kwargs):
    if len(args) > 0 and isinstance(args[0], str):
        return None
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='contour')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    show_text = p_kwargs.pop('showtext', False)
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()
    if builtins.len(p_args) >= 4 and isinstance(p_args[3], np.ndarray):
        p_args[3] = p_args[3].flatten() if p_args[3].size > 1 else int(p_args[3].item())
    p_kwargs.setdefault('cmap', str(_unilab_plot_config.get('colormap', 'viridis')).lower())
    p_kwargs.setdefault('linewidths', _unilab_plot_config['line_width'] * 0.85)
    res = ax.contour(*p_args, **p_kwargs)
    if show_text:
        ax.clabel(res, inline=True, fontsize=max(7.0, _unilab_plot_config['font_size'] - 1.5))
    _apply_extra_axes_opts(ax, extra_opts)
    _unilab_refresh_graph()
    return res


def contourf(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='contourf')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    show_text = p_kwargs.pop('showtext', False)
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()
    if builtins.len(p_args) >= 4 and isinstance(p_args[3], np.ndarray):
        p_args[3] = p_args[3].flatten() if p_args[3].size > 1 else int(p_args[3].item())
    p_kwargs.setdefault('cmap', str(_unilab_plot_config.get('colormap', 'viridis')).lower())
    res = ax.contourf(*p_args, **p_kwargs)
    if show_text:
        ax.clabel(res, inline=True, fontsize=max(7.0, _unilab_plot_config['font_size'] - 1.5))
    _apply_extra_axes_opts(ax, extra_opts)
    _unilab_refresh_graph()
    return res


def pcolor(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='pcolor')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()
    p_kwargs.setdefault('cmap', str(_unilab_plot_config.get('colormap', 'viridis')).lower())
    p_kwargs.setdefault('shading', 'auto')
    res = ax.pcolormesh(*p_args, **p_kwargs)
    _apply_extra_axes_opts(ax, extra_opts)
    _unilab_refresh_graph()
    return res


def quiver(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='quiver')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    fig = plt.gcf()
    if len(p_args) == 4 and fig.axes and getattr(fig.gca(), 'name', '') == '3d':
        fig.clf()
        _unilab_update_fig_version()
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()
    p_kwargs.setdefault('color', _get_active_color_cycle()[0])
    res = ax.quiver(*p_args, **p_kwargs)
    _apply_extra_axes_opts(ax, extra_opts)
    _unilab_refresh_graph()
    return res


def specgram(*args, **kwargs):
    return spectrogram(*args, **kwargs)


def colormap(*args):
    args_list = list(args)
    target_ax = args_list.pop(0) if args_list and hasattr(args_list[0], 'imshow') else None
    if not args_list:
        return _unilab_plot_config.get('colormap', 'viridis')
    cmap = args_list[0]
    if isinstance(cmap, np.ndarray):
        from matplotlib.colors import ListedColormap
        import matplotlib as mpl
        cmap_obj = ListedColormap(cmap, name='unilab_custom')
        try:
            mpl.colormaps.register(cmap_obj, force=True)
        except Exception:
            plt.register_cmap('unilab_custom', cmap_obj)
        cmap_name = 'unilab_custom'
    else:
        cmap_name = str(cmap).strip().lower()
        maps = {
            'parula': 'viridis', 'bone': 'bone', 'jet': 'jet', 'hot': 'hot',
            'cool': 'cool', 'spring': 'spring', 'summer': 'summer', 'winter': 'winter',
            'autumn': 'autumn', 'copper': 'copper', 'gray': 'gray', 'hsv': 'hsv',
            'turbo': 'turbo', 'viridis': 'viridis', 'plasma': 'plasma',
            'inferno': 'inferno', 'magma': 'magma', 'cividis': 'cividis', 'coolwarm': 'coolwarm',
        }
        cmap_name = maps.get(cmap_name, cmap_name)
        _unilab_plot_config['colormap'] = cmap_name

    if target_ax is None:
        plt.set_cmap(cmap_name)
        ax = plt.gca()
        for img in getattr(ax, 'images', []):
            img.set_cmap(cmap_name)
        for coll in getattr(ax, 'collections', []):
            if hasattr(coll, 'set_cmap'):
                coll.set_cmap(cmap_name)
        _unilab_refresh_graph()
    else:
        for img in getattr(target_ax, 'images', []):
            img.set_cmap(cmap_name)
        for coll in getattr(target_ax, 'collections', []):
            if hasattr(coll, 'set_cmap'):
                coll.set_cmap(cmap_name)
        _unilab_refresh_graph()


def heatmap(M, *args, **kwargs):
    _, p_kwargs = _parse_matlab_style_args(args, target_func='heatmap')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    ax = plt.gca()
    if not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()
    p_kwargs.setdefault('cmap', str(_unilab_plot_config.get('colormap', 'viridis')).lower())
    p_kwargs.setdefault('interpolation', 'nearest')
    p_kwargs.setdefault('aspect', 'auto')
    im = ax.imshow(np.asarray(M), **p_kwargs)
    if len(ax.figure.axes) <= 1:
        ax.figure.colorbar(im, ax=ax)
    _apply_extra_axes_opts(ax, extra_opts)
    _unilab_refresh_graph()
    return im


def imagesc(*args, **kwargs):
    args_list = list(args)
    target = args_list.pop(0) if args_list and hasattr(args_list[0], 'imshow') else None
    p_args, p_kwargs = _parse_matlab_style_args(args_list, target_func='imagesc')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    ax = target if target is not None else plt.gca()
    if target is None and not _get_hold_state():
        ax.cla()
        _unilab_update_fig_version()
    p_kwargs.setdefault('cmap', str(_unilab_plot_config.get('colormap', 'viridis')).lower())
    p_kwargs.setdefault('interpolation', 'nearest')
    p_kwargs.setdefault('aspect', 'auto')
    if builtins.len(p_args) == 1:
        res = ax.imshow(np.asarray(p_args[0]), **p_kwargs)
    elif builtins.len(p_args) >= 3:
        x_ext = np.asarray(p_args[0], dtype=float).flatten()
        y_ext = np.asarray(p_args[1], dtype=float).flatten()
        c_mat = np.asarray(p_args[2])
        p_kwargs['extent'] = [float(x_ext[0]), float(x_ext[-1]), float(y_ext[-1]), float(y_ext[0])]
        res = ax.imshow(c_mat, **p_kwargs)
    else:
        res = ax.imshow(*p_args, **p_kwargs)
    _apply_extra_axes_opts(ax, extra_opts)
    _unilab_refresh_graph()
    return res


def _get_or_create_3d_axes():
    fig = plt.gcf()
    if fig.axes and getattr(fig.gca(), 'name', '') == '3d':
        ax = fig.gca()
        if not _get_hold_state():
            ax.cla()
            _unilab_update_fig_version()
    else:
        cur_ax = fig.gca() if fig.axes else None
        if cur_ax is not None and len(fig.axes) > 1 and hasattr(cur_ax, 'get_subplotspec'):
            spec = cur_ax.get_subplotspec()
            fig.delaxes(cur_ax)
            ax = fig.add_subplot(spec, projection='3d')
        else:
            if not _get_hold_state():
                fig.clf()
                _unilab_update_fig_version()
            ax = fig.add_subplot(111, projection='3d')
    return fig, ax


def plot3(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='plot3')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    fig, ax = _get_or_create_3d_axes()
    p_args = [_unilab_vec(a) for a in p_args]
    p_kwargs.setdefault('linewidth', _unilab_plot_config['line_width'])
    res = ax.plot(*p_args, **p_kwargs)
    _apply_extra_axes_opts(ax, extra_opts)
    try:
        _get_3d_store()[fig.number] = {
            'type': 'scatter3d',
            'x': np.asarray(p_args[0]).tolist() if builtins.len(p_args) > 0 else [],
            'y': np.asarray(p_args[1]).tolist() if builtins.len(p_args) > 1 else [],
            'z': np.asarray(p_args[2]).tolist() if builtins.len(p_args) > 2 else [],
        }
    except Exception:
        pass
    _unilab_refresh_graph()
    return res


def scatter3(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='scatter3')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    p_args = [a for a in p_args if not (isinstance(a, str) and a.lower() == 'filled')]
    if 'markersize' in p_kwargs:
        p_kwargs['s'] = float(p_kwargs.pop('markersize'))
    if builtins.len(p_args) >= 5:
        c_arg = p_args[4]
        if isinstance(c_arg, str):
            p_kwargs.setdefault('color', _normalize_matlab_color(c_arg))
        else:
            p_kwargs.setdefault('c', c_arg)
            p_kwargs.setdefault('cmap', str(_unilab_plot_config.get('colormap', 'viridis')).lower())
        p_args = p_args[:4]
    if builtins.len(p_args) == 4:
        if isinstance(p_args[3], str):
            p_kwargs.setdefault('color', _normalize_matlab_color(p_args[3]))
        else:
            p_kwargs.setdefault('s', p_args[3])
        p_args = p_args[:3]
    p_kwargs.setdefault('s', float(_unilab_plot_config.get('marker_size', 6.0)) ** 2 * 1.3)
    fig, ax = _get_or_create_3d_axes()
    res = ax.scatter(*p_args, **p_kwargs)
    _apply_extra_axes_opts(ax, extra_opts)
    try:
        _get_3d_store()[fig.number] = {
            'type': 'scatter3d',
            'x': np.asarray(p_args[0]).tolist() if builtins.len(p_args) > 0 else [],
            'y': np.asarray(p_args[1]).tolist() if builtins.len(p_args) > 1 else [],
            'z': np.asarray(p_args[2]).tolist() if builtins.len(p_args) > 2 else [],
        }
    except Exception:
        pass
    _unilab_refresh_graph()
    return res


def stem3(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='stem3')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    fig, ax = _get_or_create_3d_axes()
    p_args = [a for a in p_args if not (isinstance(a, str) and a.lower() == 'filled')]
    res = ax.stem(*p_args[:3])
    _apply_extra_axes_opts(ax, extra_opts)
    _unilab_refresh_graph()
    return res


def quiver3(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='quiver3')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    fig, ax = _get_or_create_3d_axes()
    p_kwargs.setdefault('color', _get_active_color_cycle()[0])
    res = ax.quiver(*p_args, **p_kwargs)
    _apply_extra_axes_opts(ax, extra_opts)
    _unilab_refresh_graph()
    return res


def colorbar(*args, **kwargs):
    _, p_kwargs = _parse_matlab_style_args(args, target_func='colorbar')
    p_kwargs.update(kwargs)
    _extract_extra_axes_opts(p_kwargs)
    ax, mappable = plt.gca(), None
    if hasattr(ax, 'collections') and ax.collections:
        mappable = ax.collections[-1]
    elif hasattr(ax, 'images') and ax.images:
        mappable = ax.images[-1]
    res = plt.colorbar(mappable, ax=ax, **p_kwargs) if mappable else plt.colorbar(ax=ax, **p_kwargs)
    if res is not None:
        res.ax.tick_params(labelsize=max(7.0, _unilab_plot_config['font_size'] - 1.0), colors=_unilab_plot_config['muted_fg_color'])
    _unilab_refresh_graph()
    return res


def surf(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='surf')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    fig, ax = _get_or_create_3d_axes()
    if builtins.len(p_args) == 1 and isinstance(p_args[0], (tuple, list)) and builtins.len(p_args[0]) == 3:
        p_args = p_args[0]
    p_args = [_unilab_vec(a) for a in p_args]
    p_kwargs.setdefault('cmap', str(_unilab_plot_config.get('colormap', 'viridis')).lower())
    p_kwargs.setdefault('edgecolor', 'none')
    p_kwargs.setdefault('antialiased', True)
    X_out, Y_out, Z_out = None, None, None
    if builtins.len(p_args) == 1:
        Z = np.asarray(p_args[0])
        if Z.ndim == 1:
            Z = Z.reshape(1, -1)
        rows, cols = Z.shape
        X, Y = np.meshgrid(np.arange(cols), np.arange(rows))
        X_out, Y_out, Z_out = X, Y, Z
        res = ax.plot_surface(X, Y, Z, **p_kwargs)
    elif builtins.len(p_args) >= 3:
        X, Y, Z = p_args[0], p_args[1], p_args[2]
        if X.ndim == 1 and Y.ndim == 1:
            X, Y = np.meshgrid(X, Y)
        X_out, Y_out, Z_out = X, Y, Z
        res = ax.plot_surface(X, Y, Z, **p_kwargs)
    else:
        res = ax.plot_surface(*p_args, **p_kwargs)
    _apply_extra_axes_opts(ax, extra_opts)
    try:
        if X_out is not None:
            _get_3d_store()[fig.number] = {
                'type': 'surface',
                'x': np.asarray(X_out).tolist(),
                'y': np.asarray(Y_out).tolist(),
                'z': np.asarray(Z_out).tolist(),
            }
    except Exception:
        pass
    _unilab_refresh_graph()
    return res


def surfc(*args, **kwargs):
    res = surf(*args, **kwargs)
    try:
        ax = plt.gca()
        store = _get_3d_store().get(plt.gcf().number)
        if store and 'x' in store:
            X, Y, Z = np.asarray(store['x']), np.asarray(store['y']), np.asarray(store['z'])
            z_min = float(np.min(Z))
            ax.contour(X, Y, Z, zdir='z', offset=z_min, cmap=str(_unilab_plot_config.get('colormap', 'viridis')).lower(), alpha=0.65)
            _unilab_refresh_graph()
    except Exception:
        pass
    return res


def mesh(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='mesh')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    fig, ax = _get_or_create_3d_axes()
    p_args = [_unilab_vec(a) for a in p_args]
    p_kwargs.setdefault('linewidth', max(0.7, _unilab_plot_config['line_width'] * 0.55))
    p_kwargs.setdefault('color', _get_active_color_cycle()[0])
    X_out, Y_out, Z_out = None, None, None
    if builtins.len(p_args) == 1:
        Z = np.asarray(p_args[0])
        rows, cols = Z.shape
        X, Y = np.meshgrid(np.arange(cols), np.arange(rows))
        X_out, Y_out, Z_out = X, Y, Z
        res = ax.plot_wireframe(X, Y, Z, **p_kwargs)
    elif builtins.len(p_args) >= 3:
        X, Y, Z = p_args[0], p_args[1], p_args[2]
        if X.ndim == 1 and Y.ndim == 1:
            X, Y = np.meshgrid(X, Y)
        X_out, Y_out, Z_out = X, Y, Z
        res = ax.plot_wireframe(X, Y, Z, **p_kwargs)
    else:
        res = ax.plot_wireframe(*p_args, **p_kwargs)
    _apply_extra_axes_opts(ax, extra_opts)
    try:
        if X_out is not None:
            _get_3d_store()[fig.number] = {
                'type': 'wireframe',
                'x': np.asarray(X_out).tolist(),
                'y': np.asarray(Y_out).tolist(),
                'z': np.asarray(Z_out).tolist(),
            }
    except Exception:
        pass
    _unilab_refresh_graph()
    return res


def meshc(*args, **kwargs):
    res = mesh(*args, **kwargs)
    try:
        ax = plt.gca()
        store = _get_3d_store().get(plt.gcf().number)
        if store and 'x' in store:
            X, Y, Z = np.asarray(store['x']), np.asarray(store['y']), np.asarray(store['z'])
            z_min = float(np.min(Z))
            ax.contour(X, Y, Z, zdir='z', offset=z_min, cmap=str(_unilab_plot_config.get('colormap', 'viridis')).lower(), alpha=0.65)
            _unilab_refresh_graph()
    except Exception:
        pass
    return res


def contour3(*args, **kwargs):
    p_args, p_kwargs = _parse_matlab_style_args(args, target_func='contour3')
    p_kwargs.update(kwargs)
    extra_opts = _extract_extra_axes_opts(p_kwargs)
    fig, ax = _get_or_create_3d_axes()
    p_args = [_unilab_vec(a) for a in p_args]
    p_kwargs.setdefault('cmap', str(_unilab_plot_config.get('colormap', 'viridis')).lower())
    if builtins.len(p_args) == 1:
        Z = np.asarray(p_args[0])
        rows, cols = Z.shape
        X, Y = np.meshgrid(np.arange(cols), np.arange(rows))
        res = ax.contour3D(X, Y, Z, 20, **p_kwargs)
    elif builtins.len(p_args) >= 3:
        X, Y, Z = p_args[0], p_args[1], p_args[2]
        if X.ndim == 1 and Y.ndim == 1:
            X, Y = np.meshgrid(X, Y)
        n_lvl = int(p_args[3]) if builtins.len(p_args) >= 4 and np.asarray(p_args[3]).size == 1 else 20
        res = ax.contour3D(X, Y, Z, n_lvl, **p_kwargs)
    else:
        res = None
    _apply_extra_axes_opts(ax, extra_opts)
    _unilab_refresh_graph()
    return res

def plot_nn(layers, title="Neural Network Architecture"):
    from backend.stdlib.packages.ml.visualizers.nn_vis import plot_neural_network
    return plot_neural_network(layers, title=title)

def render_image_terminal(img_path, width=None):
    import os
    import json
    from PIL import Image, ImageOps, ImageEnhance
    from ..utils.terminal_graphics import get_terminal_graphics
    if os.environ.get("UNILAB_FORCE_FALLBACK", "0") != "1":
        high_res = get_terminal_graphics(img_path)
        if high_res: return f"\n\x1b[1;34m[ Graphical Plot View ]\x1b[0m\n{high_res}\n"
    try:
        meta_path = os.path.splitext(img_path)[0] + ".json"
        meta = {}
        if os.path.exists(meta_path):
            with open(meta_path, "r") as f: meta = json.load(f)
        im = Image.open(img_path).convert('RGB')
        bbox = ImageOps.invert(ImageOps.grayscale(im)).point(lambda p: 255 if p > 50 else 0).getbbox()
        if bbox: im = im.crop(bbox)
        im = ImageEnhance.Contrast(im).enhance(1.5)
        try: term_cols = os.get_terminal_size().columns
        except: term_cols = 80
        target_w = builtins.min(width or 100, term_cols - 4)
        target_h = builtins.max(20, builtins.min(50, int(target_w * (im.height / im.width) * 0.5)))
        img = im.resize((target_w, target_h), Image.Resampling.LANCZOS); pixels = img.load()
        ramp = " .'`^,:;Il!i><~+_-?][}{1)(|\\/tfjrxnuvczMW&8%B@$"
        grid_data = []
        for y in range(target_h):
            row = ""
            for x in range(target_w):
                r, g, b = pixels[x, y]; luma = 0.299*r + 0.587*g + 0.114*b
                if luma < 25: row += " "; continue
                idx = builtins.max(0, builtins.min(builtins.len(ramp)-1, int(luma * (builtins.len(ramp)-1) / 255)))
                row += f"\x1b[38;2;{r};{g};{b}m{ramp[idx]}\x1b[0m"
            grid_data.append(row)
        res = ["\n\x1b[1;36m[ Pastel Colored Plot ]\x1b[0m"]
        t_str = meta.get("title", "")
        if t_str: res.append(" " * 15 + f"\x1b[1m{t_str.center(target_w)}\x1b[0m")
        ymax, ymin = f"{meta.get('ymax', 1.0):.2f}", f"{meta.get('ymin', 0.0):.2f}"
        y_val_w = builtins.max(builtins.len(ymax), builtins.len(ymin))
        ylabel_padded = meta.get("ylabel", "").center(target_h)
        for i, row in enumerate(grid_data):
            yl = ylabel_padded[i] if i < builtins.len(ylabel_padded) else " "
            prefix = f"{yl} {ymax:>{y_val_w}} |" if i == 0 else (f"{yl} {ymin:>{y_val_w}} |" if i == target_h - 1 else f"{yl} {' ':>{y_val_w}} |")
            res.append(prefix + row + "|")
        xmin, xmax = f"{meta.get('xmin', 0.0):.2f}", f"{meta.get('xmax', 1.0):.2f}"
        res.append(" " * (y_val_w + 3) + "+" + "-" * target_w + "+")
        res.append(" " * (y_val_w + 3) + f"{xmin}{xmax:>{target_w + 1 - builtins.len(xmin)}}")
        xl_text = meta.get("xlabel", "")
        if xl_text: res.append(" " * (y_val_w + 3) + f"\x1b[3m{xl_text.center(target_w)}\x1b[0m")
        leg = meta.get("legend", [])
        if leg: res.append("\n" + " " * (y_val_w + 3) + "\x1b[1mLegend:\x1b[0m " + ", ".join(leg))
        return "\n".join(res)
    except Exception as e: return f"\n\x1b[1;31m[ Render failed: {e} ]\x1b[0m\n"

def list_libraries():
    import pathlib
    res = ["-" * 50, "🧪 UniLab Toolbox Explorer", "-" * 50]
    libs_dir = pathlib.Path(__file__).resolve().parent.parent / "stdlib" / "libraries"
    if not libs_dir.exists():
         return "Standard libraries directory not found."
         
    for item in sorted(libs_dir.iterdir()):
        if item.is_dir() and not item.name.startswith("__"):
            funcs = sorted([f.stem for f in item.glob("*.m")])
            if funcs:
                res.append(f"  > {item.name}:")
                line = "    "
                for i, f in enumerate(funcs):
                    if builtins.len(line) + builtins.len(f) + 2 > 80: res.append(line); line = "    "
                    line += f + (", " if i < builtins.len(funcs) - 1 else "")
                res.append(line)
    res.append("\n" + "-" * 50)
    return "\n".join(res)

def unilab_clear_workspace(g):
    print("::CLEAR_WORKSPACE::")
    import types
    import backend.core.runtime as rt
    keys_to_keep = {'np', 'plt', 'os', 'signal', 'fft', 'ifft', '__builtins__', 'addpath'}
    
    # Aliases injected by transpiler that need to be preserved/restored
    aliases = {
        'abs': rt.unilab_abs,
        'round': getattr(rt, 'round', builtins.round),
        'floor': getattr(rt, 'floor', np.floor),
        'ceil': getattr(rt, 'ceil', np.ceil),
        'max': rt.unilab_max,
        'min': rt.unilab_min,
        'sum': rt.unilab_sum,
        'mean': rt.unilab_mean,
        'any': rt.unilab_any,
        'all': rt.unilab_all,
        'prod': getattr(rt, 'unilab_prod', np.prod),
        'eig': rt.unilab_eig,
        'xcorr': rt.unilab_xcorr,
        'ode45': getattr(rt, 'ode45', None)
    }

    # Track runtime names to reset them later
    runtime_names = set()
    for name in dir(rt):
        if not name.startswith('_'): 
            keys_to_keep.add(name)
            runtime_names.add(name)
            
    keys_to_keep.update(aliases.keys())
            
    modules_to_keep = [k for k, v in g.items() if isinstance(v, types.ModuleType)]
    keys_to_keep.update(modules_to_keep)
    
    # Preserve user-defined functions
    functions_to_keep = [k for k, v in g.items() if isinstance(v, types.FunctionType)]
    keys_to_keep.update(functions_to_keep)
    
    to_remove = [k for k in g if k not in keys_to_keep and not k.startswith('__')]
    for k in to_remove: del g[k]
    
    # Reset constants and built-ins to ensure they weren't shadowed
    for name in runtime_names:
        if name in g:
            g[name] = getattr(rt, name)
            
    # Restore aliases
    for name, func in aliases.items():
        if func is not None:
            g[name] = func

def unilab_clear_variables(g, names):
    for name in names:
        if name in g: 
            print(f"::CLEAR_VAR::{name}")
            del g[name]

def unilab_iter(x):
    if isinstance(x, np.ndarray):
        if x.ndim == 0: return iter([x.item()])
        if x.ndim == 1: return iter(x)
        if x.ndim == 2:
            if x.shape[0] == 1:
                return (x[0, i] for i in range(x.shape[1]))
            if x.shape[1] == 1:
                return (x[i, 0] for i in range(x.shape[0]))
            return (x[:, i] for i in range(x.shape[1]))
        return (x[i] for i in range(x.shape[0]))
    return iter(x)

def struct(*args):
    res = {}
    for i in range(0, builtins.len(args), 2):
        if i+1 < builtins.len(args): res[args[i]] = args[i+1]
    return res

def error(msg): raise RuntimeError(str(msg))
def warning(msg): print(f"Warning: {msg}")
def unilab_not(x): return np.logical_not(x)
def unilab_xor(a, b): return np.logical_xor(a, b)

def length(x):
    if hasattr(x, '__len__'):
        if isinstance(x, np.ndarray):
            if x.size == 0: return 0
            if x.ndim == 0: return 1
            return int(builtins.max(np.shape(x)))
        return builtins.len(x)
    return 1

def size(x, dim=None):
    try: s = np.shape(x)
    except: s = (builtins.len(x),) if isinstance(x, list) else ()
    if builtins.len(s) == 0: s = (1, builtins.len(x)) if isinstance(x, (str, bytes, list)) else (1, 1)
    elif builtins.len(s) == 1: s = (1, s[0])
    if dim is not None: return s[dim-1] if dim <= builtins.len(s) else 1
    n = unilab_get_nargout()
    if n > 1: return tuple(s)
    return np.array([s]) if isinstance(s, tuple) else s

def numel(x):
    if isinstance(x, np.ndarray): return x.size
    if hasattr(x, '__len__'): return builtins.len(x)
    return 1

def unilab_prod(x, axis=None):
    if axis is not None:
        if isinstance(axis, (int, float)):
            axis = int(axis) - 1
    return np.prod(x, axis=axis, dtype=np.float64)

def unilab_any(a, axis=None):
    if not isinstance(a, np.ndarray) or a.ndim == 0:
        return bool(a)
    result = np.any(a, axis=axis)
    if isinstance(result, np.ndarray) and result.ndim == 0:
        return bool(result)
    return result

def unilab_all(a, axis=None):
    if not isinstance(a, np.ndarray) or a.ndim == 0:
        return bool(a)
    result = np.all(a, axis=axis)
    if isinstance(result, np.ndarray) and result.ndim == 0:
        return bool(result)
    return result

def find_peaks(x, min_height=-np.inf):
    x_arr = np.asarray(x).flatten()
    peaks = []
    locs = []
    for i in range(1, len(x_arr)-1):
        if x_arr[i] > x_arr[i-1] and x_arr[i] > x_arr[i+1] and x_arr[i] >= min_height:
            peaks.append(x_arr[i])
            locs.append(i + 1) # 1-based
            
    n_out = unilab_get_nargout()
    if n_out <= 1:
        return np.array(peaks).reshape(1, -1)
    return np.array(peaks).reshape(-1, 1), np.array(locs).reshape(-1, 1)


# Aliases and unified canonical math builtins
sum = unilab_sum
mean = unilab_mean
min = unilab_min
max = unilab_max
abs = unilab_abs
eig = unilab_eig

def mldivide(A, B): 
    A_mat = np.asarray(A)
    B_mat = np.asarray(B)
    if A_mat.ndim == 2 and B_mat.ndim == 2 and A_mat.shape[0] == A_mat.shape[1]:
        try:
            return np.linalg.solve(A_mat, B_mat)
        except np.linalg.LinAlgError:
            return np.linalg.lstsq(A_mat, B_mat, rcond=None)[0]
    return np.linalg.lstsq(A_mat, B_mat, rcond=None)[0]

def trapz(y, x=None, dim=None): 
    y_arr = np.asarray(y)
    if y_arr.ndim <= 1 or (y_arr.ndim == 2 and (y_arr.size == 0 or y_arr.shape[0] == 1 or y_arr.shape[1] == 1)):
        y_flat = y_arr.flatten()
        x_flat = np.asarray(x).flatten() if x is not None else None
        fn = getattr(np, 'trapezoid', getattr(np, 'trapz', None))
        res = fn(y_flat, x=x_flat)
        return res.item() if hasattr(res, 'item') and res.size == 1 else res
    if dim is not None:
        axis = _unilab_to_int(dim) - 1
    else:
        axis = 0
        for i, d in enumerate(y_arr.shape):
            if d > 1:
                axis = i
                break
    fn = getattr(np, 'trapezoid', getattr(np, 'trapz', None))
    res = fn(y_arr, x=x, axis=axis)
    return res.item() if hasattr(res, 'item') and res.size == 1 else res

def cumsum(x, axis=None): 
    arr = np.asarray(x)
    if axis is not None:
        axis = _unilab_to_int(axis) - 1
    elif arr.ndim >= 2:
        axis = 1 if arr.shape[0] == 1 else 0
    return np.cumsum(arr, axis=axis)

def strcmp(s1, s2): return bool(s1 == s2)
def isequal(a, b):
    try: return bool(np.array_equal(a, b))
    except: return bool(a == b)

fft = scipy_fft
ifft = scipy_ifft

def log2(x): return np.log2(x)
def isnan(x): return np.isnan(x)
def isinf(x): return np.isinf(x)
def isfinite(x): return np.isfinite(x)
def isreal(x):
    arr = np.asarray(x)
    return not np.iscomplexobj(arr) or np.all(np.imag(arr) == 0)

def isprime(n):
    def _is_prime(val):
        try: v = int(val)
        except: return False
        if v <= 1: return False
        if v <= 3: return True
        if v % 2 == 0 or v % 3 == 0: return False
        i = 5
        while i * i <= v:
            if v % i == 0 or v % (i + 2) == 0: return False
            i += 6
        return True
    arr = np.asarray(n)
    if arr.ndim == 0: return _is_prime(arr.item())
    return np.vectorize(_is_prime)(arr)

def repmat(A, *reps):
    arr = np.asarray(A)
    if len(reps) == 1 and isinstance(reps[0], (list, tuple, np.ndarray)):
        r = [_unilab_to_int(x) for x in reps[0]]
    elif len(reps) == 1:
        r = [_unilab_to_int(reps[0]), _unilab_to_int(reps[0])]
    else:
        r = [_unilab_to_int(x) for x in reps]
    while len(r) < 2:
        r.append(1)
    return np.tile(arr, tuple(r))

def bsxfun(fun, A, B):
    f = fun.func if isinstance(fun, UnilabHandle) else fun
    return f(A, B)

def plus(A, B): return np.add(A, B)

def cond(A, p=None):
    A_mat = np.atleast_2d(np.asarray(A))
    return float(np.linalg.cond(A_mat, p=p))

def unwrap(p, discont=np.pi, axis=-1):
    return np.unwrap(p, discont=discont, axis=axis)

def isfield(s, field):
    if not isinstance(s, dict): return False
    if isinstance(field, (list, tuple)): return [str(f) in s for f in field]
    return str(field) in s

def isstruct(s): return isinstance(s, dict)

def strtrim(s):
    if isinstance(s, str): return s.strip()
    if isinstance(s, list): return [strtrim(item) for item in s]
    return s

def strsplit(s, delimiter=None):
    if delimiter is None: return str(s).split()
    return str(s).split(str(delimiter))

def strfind(text, pattern):
    t_str = str(text)
    p_str = str(pattern)
    indices = []
    idx = t_str.find(p_str)
    while idx != -1:
        indices.append(idx + 1)
        idx = t_str.find(p_str, idx + 1)
    return np.array(indices, dtype=int).reshape(1, -1) if indices else np.array([], dtype=int)

def fwrite(fid, data, precision='uint8'):
    fid = int(fid)
    if fid not in _unilab_fid_map: return 0
    f = _unilab_fid_map[fid]
    if isinstance(data, (bytes, bytearray)): return f.write(data)
    if isinstance(data, str): return f.write(data.encode('utf-8'))
    arr = np.asarray(data)
    return f.write(arr.tobytes())

def fseek(fid, offset, origin=0):
    fid = int(fid)
    if fid not in _unilab_fid_map: return -1
    f = _unilab_fid_map[fid]
    if str(origin) in ('bof', '-1'): whence = 0
    elif str(origin) in ('cof', '0'): whence = 1
    elif str(origin) in ('eof', '1'): whence = 2
    else: whence = int(origin)
    f.seek(int(offset), whence)
    return 0

def ftell(fid):
    fid = int(fid)
    if fid not in _unilab_fid_map: return -1
    return float(_unilab_fid_map[fid].tell())

def feof(fid):
    fid = int(fid)
    if fid not in _unilab_fid_map: return 1
    f = _unilab_fid_map[fid]
    cur = f.tell()
    f.seek(0, 2)
    end = f.tell()
    f.seek(cur)
    return int(cur >= end)

def fgets(fid):
    fid = int(fid)
    if fid not in _unilab_fid_map: return -1
    line = _unilab_fid_map[fid].readline()
    return line if line else -1

def unilab_freqresp(sys, w):
    if hasattr(sys, 'freqresp'): return sys.freqresp(w)
    num, den = unilab_tfdata(sys)
    _, h = signal.freqs(num.flatten(), den.flatten(), worN=w)
    return h

class UnilabTable:
    def __init__(self, data_list, names):
        self.data = data_list
        self.names = names
    def __repr__(self):
        names = [str(n) for n in self.names]
        header = "    " + "    ".join(names)
        rows = []
        num_rows = len(self.data[0]) if self.data else 0
        for i in range(num_rows):
            row_data = [str(col[i]) for col in self.data]
            rows.append(f"{i+1}   " + "    ".join(row_data))
        return "\n".join([header] + rows)

class UnilabException:
    def __init__(self, e):
        self.message = str(e)
        self.identifier = type(e).__name__

def unilab_exception(e):
    return UnilabException(e)

_unilab_fid_map = {}
_unilab_next_fid = 3

def fopen(filename, mode='r'):
    global _unilab_next_fid
    # Map MATLAB modes to Python modes
    mode_map = {'r': 'r', 'w': 'w', 'a': 'a', 'r+': 'r+', 'w+': 'w+'}
    p_mode = mode_map.get(mode, 'r')
    try:
        f = open(filename, p_mode)
        fid = _unilab_next_fid
        _unilab_fid_map[fid] = f
        _unilab_next_fid += 1
        return float(fid)
    except Exception:
        return -1.0

def fclose(fid):
    fid = int(fid)
    if fid in _unilab_fid_map:
        _unilab_fid_map[fid].close()
        del _unilab_fid_map[fid]
        return 0.0
    return -1.0

def fread(fid, size=None, precision='*char'):
    fid = int(fid)
    if fid not in _unilab_fid_map: return None
    f = _unilab_fid_map[fid]
    if precision == '*char':
        data = f.read()
        return np.asarray([ord(c) for col in data for c in col]) if isinstance(data, list) else np.asarray([ord(c) for c in data])
    # Basic implementation for now
    return f.read()

def table(*args, **kwargs):
    # Very basic table implementation
    var_names = kwargs.get('VariableNames', [])
    data = []
    
    # Process positional arguments
    i = 0
    while i < len(args):
        arg = args[i]
        if isinstance(arg, (str, bytes)) and arg == 'VariableNames':
            if i + 1 < len(args):
                var_names = args[i+1]
                i += 2
                continue
        data.append(arg)
        i += 1
    
    if (isinstance(var_names, (list, np.ndarray)) and len(var_names) == 0) or var_names is None:
        var_names = [f"Var{j+1}" for j in range(len(data))]
    
    return UnilabTable(data, var_names)
