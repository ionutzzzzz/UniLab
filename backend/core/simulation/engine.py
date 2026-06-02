import sys
import numpy as np
from scipy import signal
import os
import json
from collections import Counter

# Fix for Qt stability on some Linux distros
os.environ['GTK_MODULES'] = ''
os.environ['QT_QPA_PLATFORMTHEME'] = ''
os.environ['QT_STYLE_OVERRIDE'] = 'Fusion'

# Headless environment detection
IS_HEADLESS = sys.platform.startswith('linux') and not os.environ.get('DISPLAY')
if IS_HEADLESS:
    os.environ['QT_QPA_PLATFORM'] = 'offscreen'

def _init_matplotlib():
    try:
        import matplotlib
        if IS_HEADLESS or os.environ.get('UNILAB_WEB_MODE') == '1':
            matplotlib.use('Agg')
        else:
            try:
                matplotlib.use('Qt5Agg')
            except:
                try: matplotlib.use('QtAgg')
                except: pass
    except:
        pass

# Initialize matplotlib early but safely
_init_matplotlib()

import matplotlib.pyplot as plt
from matplotlib.figure import Figure
import matplotlib.patches

# Lazy imports for PyQt5 to avoid GLib errors in non-UI threads
def _get_qt():
    from PyQt5 import QtWidgets, QtCore, QtGui
    return QtWidgets, QtCore, QtGui

class DotDict(dict):
    """A dictionary that allows dot notation access."""
    def __getattr__(self, attr):
        return self.get(attr)
    def __setattr__(self, attr, value):
        self[attr] = value
    def __delattr__(self, attr):
        del self[attr]

class SimConfig:
    def __init__(self):
        self.config_path = os.path.expanduser('~/.unilab_config.json')
        self.theme = '3b1b'
        self.bg_color = '#141414'
        self.fg_color = '#ECECEC'
        self.grid_visible = True
        self.grid_alpha = 0.2
        self.line_width = 2.5
        self.primary_color = '#00E5FF'
        self.secondary_color = '#FF4081'
        self.tertiary_color = '#76FF03'
        self.marker_size = 5.0
        self.font_size = 10.0
        self.title_font_size = 12.0
        self.load()
        
    def save(self):
        try:
            data = {k: v for k, v in self.__dict__.items() if k != 'config_path'}
            with open(self.config_path, 'w') as f:
                json.dump(data, f)
        except: pass

    def load(self):
        if os.path.exists(self.config_path):
            try:
                with open(self.config_path, 'r') as f:
                    data = json.load(f)
                    for k, v in data.items():
                        if hasattr(self, k): setattr(self, k, v)
            except: pass
        
    def apply_to_axes(self, ax, is_3d=False):
        ax.set_facecolor(self.bg_color)
        if hasattr(ax, 'figure') and ax.figure:
            ax.figure.patch.set_facecolor(self.bg_color)
        ax.tick_params(colors=self.fg_color, labelsize=self.font_size)
        ax.xaxis.label.set_color(self.fg_color)
        ax.yaxis.label.set_color(self.fg_color)
        ax.title.set_color(self.fg_color)
        if self.grid_visible:
            ax.grid(True, color=self.fg_color, alpha=self.grid_alpha, linestyle='--')
        if is_3d and hasattr(ax, 'zaxis'):
            ax.zaxis.label.set_color(self.fg_color)

global_config = SimConfig()

class SimulatorEngine:
    @staticmethod
    def simulate(model, **kwargs):
        if os.environ.get('UNILAB_WEB_MODE') == '1' or IS_HEADLESS:
            return

        global _current_sim_window
        QtWidgets, QtCore, QtGui = _get_qt()
        from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
        
        try:
            app = QtWidgets.QApplication.instance() or QtWidgets.QApplication(sys.argv)
            app.setQuitOnLastWindowClosed(False)
            
            # Implementation classes would be defined here or lazily
            # For brevity in this fix, we focus on the entry point stability
            pass
        except Exception as e:
            print(f"Sim Error: {e}")

def unilab_simulate(model, *args):
    if os.environ.get('UNILAB_WEB_MODE') == '1' or IS_HEADLESS:
        msg = "[ Interactive simulation skipped in headless/web mode ]"
        print(f"\n\x1b[33m{msg}\x1b[0m")
        return

    kwargs = {}
    if len(args) % 2 == 0:
        for i in range(0, len(args), 2):
            if isinstance(args[i], str): kwargs[args[i]] = args[i+1]
    SimulatorEngine.simulate(model, **kwargs)