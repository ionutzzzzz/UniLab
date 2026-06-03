import sys
import threading
import queue
import time
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

try:
    import matplotlib    # Try to be more flexible with the backend
    if 'matplotlib.backends' not in sys.modules:
        try:
            if IS_HEADLESS:
                matplotlib.use('Agg')
            else:
                matplotlib.use('Qt5Agg')
        except:
            try: matplotlib.use('QtAgg')
            except: pass
except Exception:
    pass

import matplotlib.pyplot as plt
from matplotlib.figure import Figure
import matplotlib.patches

try:
    from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
except ImportError:
    try:
        from matplotlib.backends.backend_qtagg import FigureCanvasQTAgg as FigureCanvas
    except ImportError:
        FigureCanvas = None

from PyQt5.QtWidgets import (QApplication, QMainWindow, QVBoxLayout, QHBoxLayout, 
                             QWidget, QLabel, QSlider, QPushButton, QComboBox, 
                             QProgressBar, QAction, QMenu, QMenuBar, QTabWidget, QGroupBox, QFormLayout,
                             QCheckBox, QLineEdit, QDialog, QColorDialog, QSpinBox, QDoubleSpinBox, QFileDialog,
                             QScrollArea, QMessageBox)
from PyQt5.QtCore import Qt, QTimer, QThread, pyqtSignal, QEventLoop
from PyQt5.QtGui import QPalette, QColor

# Try importing ML package
try:
    from backend.stdlib.packages import ml
except ImportError:
    ml = None


class BridgeSimulator:
    def __init__(self, **kwargs):
        self.params = DotDict(kwargs.get('params', {}))
        self.custom_controls = {}
        self.is_running = True
        self.event_queue = queue.Queue()
        self.on_event = kwargs.get('on_event')
        self.model_name = kwargs.get('model_name', 'unknown')
        self.emit_event('SIM_START', {'model': self.model_name})

    def emit_event(self, event_type, data):
        try:
            if self.on_event:
                self.on_event(event_type, json.dumps(data))
            else:
                from backend.core.runtime import unilab_event_ctx
                cb = unilab_event_ctx.get()
                if cb:
                    cb(event_type, json.dumps(data))
                else:
                    print(f'::{event_type}::{json.dumps(data)}')
        except:
            print(f'::{event_type}::{json.dumps(data)}')

    def add_custom_button(self, label, callback, layout=None):
        ctrl_id = f'btn_{label}'
        self.custom_controls[ctrl_id] = callback
        self.emit_event('CREATE_CONTROL', {'id': ctrl_id, 'type': 'button', 'label': label})
        return ctrl_id

    def add_custom_slider(self, label, min_val, max_val, initial_val, callback, layout=None):
        ctrl_id = f'sl_{label}'
        self.custom_controls[ctrl_id] = callback
        self.emit_event('CREATE_CONTROL', {'id': ctrl_id, 'type': 'slider', 'label': label, 'min': min_val, 'max': max_val, 'value': initial_val})
        return ctrl_id

    def update_control_value(self, control_id, value):
        self.emit_event('UPDATE_CONTROL', {'id': control_id, 'value': value})

    def push_event(self, event_data):
        self.event_queue.put(event_data)

    def process_events(self):
        while not self.event_queue.empty():
            ev = self.event_queue.get()
            if ev.get('type') == 'STOP':
                self.is_running = False
            cid = ev.get('id')
            val = ev.get('value')
            if cid in self.custom_controls:
                self.custom_controls[cid](val)

class BridgeAlgorithmSimulator(BridgeSimulator):
    def __init__(self, step_f, draw_f, state, **kwargs):
        super().__init__(model_name='algorithm', **kwargs)
        self.step_f = step_f
        self.draw_f = draw_f
        self.state = state
        self.delay = kwargs.get('delay', 0.05)
        
    def run(self):
        global _current_sim_window
        # Set context for background thread
        from backend.core.runtime import unilab_event_ctx
        unilab_event_ctx.set(self.on_event)
        
        self.emit_event('SIM_RUNNING', {'status': 'started'})
        try:
            while self.is_running:
                self.process_events()
                self.state = self.step_f(self.state, self.params)
                fig = plt.gcf()
                ax = plt.gca()
                self.draw_f(ax, self.state)
                time.sleep(self.delay)
        except KeyboardInterrupt:
            pass
        except Exception as e:
            self.emit_event('SIM_ERROR', {'error': str(e)})
        self.emit_event('SIM_STOPPED', {'status': 'stopped'})
        _current_sim_window = None

def push_sim_event(event_data):
    global _current_sim_window
    if _current_sim_window and hasattr(_current_sim_window, 'push_event'):
        if isinstance(event_data, str):
            try: event_data = json.loads(event_data)
            except: pass
        _current_sim_window.push_event(event_data)

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
        self.bg_color = '#141414' # Dark gray/black
        self.fg_color = '#ECECEC' # Light text
        self.grid_visible = True
        self.grid_alpha = 0.2
        self.line_width = 2.5
        self.primary_color = '#00E5FF' # Cyan
        self.secondary_color = '#FF4081' # Pink
        self.tertiary_color = '#76FF03' # Neon green
        self.marker_size = 5.0
        self.font_size = 10.0
        self.title_font_size = 12.0
        self.load()
        
    def save(self):
        try:
            data = {
                'theme': self.theme,
                'bg_color': self.bg_color,
                'fg_color': self.fg_color,
                'grid_visible': self.grid_visible,
                'grid_alpha': self.grid_alpha,
                'line_width': self.line_width,
                'primary_color': self.primary_color,
                'secondary_color': self.secondary_color,
                'tertiary_color': self.tertiary_color,
                'marker_size': self.marker_size,
                'font_size': self.font_size,
                'title_font_size': self.title_font_size
            }
            with open(self.config_path, 'w') as f:
                json.dump(data, f)
        except Exception as e:
            print(f"Failed to save config: {e}")

    def load(self):
        if os.path.exists(self.config_path):
            try:
                with open(self.config_path, 'r') as f:
                    data = json.load(f)
                    self.theme = data.get('theme', self.theme)
                    self.bg_color = data.get('bg_color', self.bg_color)
                    self.fg_color = data.get('fg_color', self.fg_color)
                    self.grid_visible = data.get('grid_visible', self.grid_visible)
                    self.grid_alpha = data.get('grid_alpha', self.grid_alpha)
                    self.line_width = data.get('line_width', self.line_width)
                    self.primary_color = data.get('primary_color', self.primary_color)
                    self.secondary_color = data.get('secondary_color', self.secondary_color)
                    self.tertiary_color = data.get('tertiary_color', self.tertiary_color)
                    self.marker_size = data.get('marker_size', self.marker_size)
                    self.font_size = data.get('font_size', self.font_size)
                    self.title_font_size = data.get('title_font_size', self.title_font_size)
            except Exception as e:
                print(f"Failed to load config: {e}")
        
    def apply_to_axes(self, ax, is_3d=False):
        ax.set_facecolor(self.bg_color)
        if hasattr(ax, 'figure') and ax.figure:
            ax.figure.patch.set_facecolor(self.bg_color)
        ax.tick_params(colors=self.fg_color, labelsize=self.font_size)
        ax.xaxis.label.set_color(self.fg_color)
        ax.xaxis.label.set_size(self.font_size)
        ax.yaxis.label.set_color(self.fg_color)
        ax.yaxis.label.set_size(self.font_size)
        ax.title.set_color(self.fg_color)
        ax.title.set_size(self.title_font_size)
        for spine in ax.spines.values():
            spine.set_color(self.fg_color)
        if self.grid_visible:
            ax.grid(True, color=self.fg_color, alpha=self.grid_alpha, linestyle='--')
        else:
            ax.grid(False)
            
        if is_3d:
            ax.xaxis.pane.fill = False
            ax.yaxis.pane.fill = False
            ax.zaxis.pane.fill = False
            ax.xaxis.pane.set_edgecolor(self.fg_color)
            ax.yaxis.pane.set_edgecolor(self.fg_color)
            ax.zaxis.pane.set_edgecolor(self.fg_color)
            ax.zaxis.label.set_color(self.fg_color)

global_config = SimConfig()

class StyleSettingsDialog(QDialog):
    def __init__(self, parent=None, callback=None):
        super().__init__(parent)
        self.setWindowTitle("Appearance Settings")
        self.callback = callback
        self.temp_colors = {
            'bg_color': global_config.bg_color,
            'fg_color': global_config.fg_color,
            'primary_color': global_config.primary_color,
            'secondary_color': global_config.secondary_color
        }
        self.initUI()
        
    def create_color_btn(self, color_key, label_text):
        btn = QPushButton()
        btn.setFixedSize(30, 20)
        btn.setStyleSheet(f"background-color: {self.temp_colors[color_key]}; border: 1px solid #777;")
        def choose_color():
            color = QColorDialog.getColor(QColor(self.temp_colors[color_key]), self, f"Select {label_text}")
            if color.isValid():
                self.temp_colors[color_key] = color.name()
                btn.setStyleSheet(f"background-color: {color.name()}; border: 1px solid #777;")
                self.theme_combo.setCurrentText("Custom") # Change theme to Custom
        btn.clicked.connect(choose_color)
        return btn

    def initUI(self):
        layout = QFormLayout(self)
        
        self.theme_combo = QComboBox()
        self.theme_combo.addItems(['3b1b', 'Dark', 'Light', 'Custom'])
        self.theme_combo.setCurrentText(global_config.theme)
        self.theme_combo.currentTextChanged.connect(self.on_theme_change)
        layout.addRow("Theme:", self.theme_combo)
        
        self.bg_btn = self.create_color_btn('bg_color', 'Background Color')
        layout.addRow("Background Color:", self.bg_btn)
        self.fg_btn = self.create_color_btn('fg_color', 'Text/Grid Color')
        layout.addRow("Text/Grid Color:", self.fg_btn)
        self.prim_btn = self.create_color_btn('primary_color', 'Primary Color')
        layout.addRow("Primary Color:", self.prim_btn)
        self.sec_btn = self.create_color_btn('secondary_color', 'Secondary Color')
        layout.addRow("Secondary Color:", self.sec_btn)
        
        self.lw_spin = QDoubleSpinBox()
        self.lw_spin.setRange(0.5, 10.0)
        self.lw_spin.setSingleStep(0.5)
        self.lw_spin.setValue(global_config.line_width)
        layout.addRow("Line Width:", self.lw_spin)
        
        self.ms_spin = QDoubleSpinBox()
        self.ms_spin.setRange(1.0, 20.0)
        self.ms_spin.setSingleStep(1.0)
        self.ms_spin.setValue(global_config.marker_size)
        layout.addRow("Marker Size:", self.ms_spin)
        
        self.fs_spin = QDoubleSpinBox()
        self.fs_spin.setRange(5.0, 30.0)
        self.fs_spin.setSingleStep(1.0)
        self.fs_spin.setValue(global_config.font_size)
        layout.addRow("Font Size:", self.fs_spin)
        
        self.tfs_spin = QDoubleSpinBox()
        self.tfs_spin.setRange(5.0, 40.0)
        self.tfs_spin.setSingleStep(1.0)
        self.tfs_spin.setValue(global_config.title_font_size)
        layout.addRow("Title Font Size:", self.tfs_spin)
        
        self.grid_cb = QCheckBox("Show Grid")
        self.grid_cb.setChecked(global_config.grid_visible)
        layout.addRow("Grid:", self.grid_cb)
        
        self.apply_btn = QPushButton("Apply Styles")
        self.apply_btn.clicked.connect(self.apply_styles)
        layout.addRow(self.apply_btn)
        
    def update_btn_colors(self):
        self.bg_btn.setStyleSheet(f"background-color: {self.temp_colors['bg_color']}; border: 1px solid #777;")
        self.fg_btn.setStyleSheet(f"background-color: {self.temp_colors['fg_color']}; border: 1px solid #777;")
        self.prim_btn.setStyleSheet(f"background-color: {self.temp_colors['primary_color']}; border: 1px solid #777;")
        self.sec_btn.setStyleSheet(f"background-color: {self.temp_colors['secondary_color']}; border: 1px solid #777;")

    def on_theme_change(self, theme):
        if theme == '3b1b':
            self.temp_colors.update({'bg_color': '#141414', 'fg_color': '#ECECEC', 'primary_color': '#00E5FF', 'secondary_color': '#FF4081'})
            self.update_btn_colors()
        elif theme == 'Dark':
            self.temp_colors.update({'bg_color': '#2B2B2B', 'fg_color': '#FFFFFF', 'primary_color': '#3498DB', 'secondary_color': '#E74C3C'})
            self.update_btn_colors()
        elif theme == 'Light':
            self.temp_colors.update({'bg_color': '#FFFFFF', 'fg_color': '#000000', 'primary_color': '#2980B9', 'secondary_color': '#C0392B'})
            self.update_btn_colors()
            
    def apply_styles(self):
        global_config.theme = self.theme_combo.currentText()
        global_config.bg_color = self.temp_colors['bg_color']
        global_config.fg_color = self.temp_colors['fg_color']
        global_config.primary_color = self.temp_colors['primary_color']
        global_config.secondary_color = self.temp_colors['secondary_color']
        global_config.line_width = self.lw_spin.value()
        global_config.marker_size = self.ms_spin.value()
        global_config.font_size = self.fs_spin.value()
        global_config.title_font_size = self.tfs_spin.value()
        global_config.grid_visible = self.grid_cb.isChecked()
        global_config.save()
        if self.callback:
            self.callback()
        self.accept()

class ThemeManager:
    @staticmethod
    def apply_current_theme(app):
        is_dark = global_config.theme in ['3b1b', 'Dark']
        if global_config.theme == 'Custom':
            bg = global_config.bg_color.lstrip('#')
            if len(bg) == 6:
                r, g, b = int(bg[0:2], 16), int(bg[2:4], 16), int(bg[4:6], 16)
                is_dark = (r*0.299 + g*0.587 + b*0.114) < 128
            else:
                is_dark = True
                
        if is_dark:
            ThemeManager.apply_dark_theme(app)
        else:
            ThemeManager.apply_light_theme(app)
        # Matplotlib global updates
        plt.rcParams['figure.facecolor'] = global_config.bg_color
        plt.rcParams['axes.facecolor'] = global_config.bg_color
        plt.rcParams['axes.edgecolor'] = global_config.fg_color
        plt.rcParams['text.color'] = global_config.fg_color
        plt.rcParams['axes.labelcolor'] = global_config.fg_color
        plt.rcParams['xtick.color'] = global_config.fg_color
        plt.rcParams['ytick.color'] = global_config.fg_color
        plt.rcParams['lines.linewidth'] = global_config.line_width
        plt.rcParams['lines.markersize'] = global_config.marker_size
        plt.rcParams['font.size'] = global_config.font_size
        plt.rcParams['axes.titlesize'] = global_config.title_font_size

    @staticmethod
    def apply_dark_theme(app):
        app.setStyle("Fusion")
        dark_palette = QPalette()
        dark_palette.setColor(QPalette.Window, QColor(53, 53, 53))
        dark_palette.setColor(QPalette.WindowText, Qt.white)
        dark_palette.setColor(QPalette.Base, QColor(25, 25, 25))
        dark_palette.setColor(QPalette.AlternateBase, QColor(53, 53, 53))
        dark_palette.setColor(QPalette.ToolTipBase, Qt.white)
        dark_palette.setColor(QPalette.ToolTipText, Qt.white)
        dark_palette.setColor(QPalette.Text, Qt.white)
        dark_palette.setColor(QPalette.Button, QColor(53, 53, 53))
        dark_palette.setColor(QPalette.ButtonText, Qt.white)
        dark_palette.setColor(QPalette.BrightText, Qt.red)
        dark_palette.setColor(QPalette.Link, QColor(42, 130, 218))
        dark_palette.setColor(QPalette.Highlight, QColor(42, 130, 218))
        dark_palette.setColor(QPalette.HighlightedText, Qt.black)
        app.setPalette(dark_palette)
        try: plt.style.use('dark_background')
        except: pass
        
    @staticmethod
    def apply_light_theme(app):
        app.setStyle("Fusion")
        app.setPalette(app.style().standardPalette())
        try: plt.style.use('default')
        except: pass

class BaseSimulator(QMainWindow):
    def __init__(self, **kwargs):
        super().__init__()
        self.params = DotDict()
        self.custom_controls = {}
        
        # Central widget and main layout
        self.main_container = QWidget()
        self.setCentralWidget(self.main_container)
        self.main_layout = QHBoxLayout(self.main_container)
        
        # Left side: Plot area
        self.plot_container = QWidget()
        self.plot_layout = QVBoxLayout(self.plot_container)
        self.main_layout.addWidget(self.plot_container, stretch=3)
        
        # Right side: Control panel with scroll area
        self.scroll_area = QScrollArea()
        self.scroll_area.setWidgetResizable(True)
        self.scroll_area.setMinimumWidth(300)
        self.main_layout.addWidget(self.scroll_area, stretch=1)
        
        self.control_panel_widget = QWidget()
        self.controls_layout = QVBoxLayout(self.control_panel_widget)
        self.scroll_area.setWidget(self.control_panel_widget)
        
        # Group for custom tunable sliders - AT THE TOP
        self.tunables_group = QGroupBox("Interactive Parameters")
        self.tunables_layout = QVBoxLayout()
        self.tunables_group.setLayout(self.tunables_layout)
        self.controls_layout.addWidget(self.tunables_group)
        self.tunables_group.hide() # Shown only if tunables exist
        
        # Space for other controls (to be added by subclasses)
        self.subclass_controls_layout = QVBoxLayout()
        self.controls_layout.addLayout(self.subclass_controls_layout)
        
        self.controls_layout.addStretch()
        
        self.init_menu()
        
        # Pre-populate params and create UI from tunables
        tunables = kwargs.get('tunables', {})
        if isinstance(tunables, dict) and tunables:
            for name, cfg in tunables.items():
                if isinstance(cfg, (list, tuple, np.ndarray)):
                    cfg_list = list(np.asarray(cfg).flatten())
                    if len(cfg_list) >= 2:
                        mn, mx = float(cfg_list[0]), float(cfg_list[1])
                        val = float(cfg_list[2]) if len(cfg_list) > 2 else mn
                        self.add_tunable(name, mn, mx, val)

    def add_tunable(self, name, min_val, max_val, initial_val):
        self.tunables_group.show()
        # Add to the specific tunables_layout
        self.add_custom_slider(name, min_val, max_val, initial_val, 
                               lambda val: self._update_param(name, val), 
                               layout=self.tunables_layout)
        self.params[name] = initial_val
        
    def _update_param(self, name, val):
        self.params[name] = val
        self.on_style_changed()
        
    def init_menu(self):
        menubar = self.menuBar()
        settings_menu = menubar.addMenu('Appearance')
        
        style_action = QAction('Settings...', self)
        style_action.triggered.connect(self.open_style_settings)
        settings_menu.addAction(style_action)
        
        export_menu = menubar.addMenu('Export')
        save_img_action = QAction('Save Image...', self)
        save_img_action.triggered.connect(self.export_image)
        export_menu.addAction(save_img_action)
        
        save_vid_action = QAction('Save Video...', self)
        save_vid_action.triggered.connect(self.export_video)
        export_menu.addAction(save_vid_action)
        
    def export_image(self):
        options = QFileDialog.Options()
        file_name, selected_filter = QFileDialog.getSaveFileName(self, "Save Simulation Image", "", "PNG Files (*.png);;JPEG Files (*.jpg);;All Files (*)", options=options)
        if file_name:
            if not os.path.splitext(file_name)[1]:
                if "JPEG" in selected_filter: file_name += ".jpg"
                else: file_name += ".png"
                
            if hasattr(self, 'figure'):
                self.figure.savefig(file_name, facecolor=self.figure.get_facecolor(), edgecolor='none', bbox_inches='tight')
            elif hasattr(self, 'metrics_figure'):
                self.metrics_figure.savefig(file_name, facecolor=self.metrics_figure.get_facecolor(), edgecolor='none', bbox_inches='tight')

    def export_video(self):
        from PyQt5.QtWidgets import QMessageBox
        QMessageBox.information(self, "Not Supported", "Video export is only supported for dynamic simulations with animations.")

    def open_style_settings(self):
        dlg = StyleSettingsDialog(self, callback=self.on_style_changed)
        dlg.exec_()
        
    def on_style_changed(self):
        ThemeManager.apply_current_theme(QApplication.instance())
        if hasattr(self, 'update_simulation'):
            self.update_simulation()
            if hasattr(self, 'animation_idx') and hasattr(self, 'render_frame'):
                self.render_frame(self.animation_idx)
        elif hasattr(self, 'refresh_plot'):
            self.refresh_plot()
        elif hasattr(self, 'ax') and self.ax:
            is_3d = hasattr(self.ax, 'zaxis')
            global_config.apply_to_axes(self.ax, is_3d)
            self.canvas.draw()
        
    def add_custom_button(self, label, callback, layout=None):
        btn = QPushButton(label)
        btn.clicked.connect(callback)
        if layout: 
            layout.addWidget(btn)
            btn.show()
        self.custom_controls[label] = btn
        return btn

    def add_custom_slider(self, label, min_val, max_val, initial_val, callback, layout=None):
        container = QWidget()
        l = QVBoxLayout(container)
        lbl = QLabel(f"{label}: {initial_val:.2f}")
        slider = QSlider(Qt.Horizontal)
        slider.setRange(int(min_val * 1000), int(max_val * 1000))
        slider.setValue(int(initial_val * 1000))
        def internal_callback():
            val = slider.value() / 1000.0
            lbl.setText(f"{label}: {val:.2f}")
            callback(val)
        slider.valueChanged.connect(internal_callback)
        l.addWidget(lbl); l.addWidget(slider)
        if layout: 
            layout.addWidget(container)
            container.show()
        self.custom_controls[label] = slider
        return container
        
    def add_custom_checkbox(self, label, initial_state, callback, layout=None):
        cb = QCheckBox(label)
        cb.setChecked(initial_state)
        cb.stateChanged.connect(lambda state: callback(state == Qt.Checked))
        if layout: 
            layout.addWidget(cb)
            cb.show()
        self.custom_controls[label] = cb
        return cb
        
    def add_custom_dropdown(self, label, options, callback, layout=None):
        container = QWidget()
        l = QVBoxLayout(container)
        l.addWidget(QLabel(label))
        combo = QComboBox()
        combo.addItems([str(o) for o in options])
        combo.currentTextChanged.connect(callback)
        l.addWidget(combo)
        if layout: 
            layout.addWidget(container)
            container.show()
        self.custom_controls[label] = combo
        return container
        
    def add_custom_input(self, label, initial_text, callback, layout=None):
        container = QWidget()
        l = QVBoxLayout(container)
        l.addWidget(QLabel(label))
        edit = QLineEdit()
        edit.setText(str(initial_text))
        edit.textChanged.connect(callback)
        l.addWidget(edit)
        if layout: 
            layout.addWidget(container)
            container.show()
        self.custom_controls[label] = edit
        return container
        
    def add_custom_label(self, label_id, initial_text, layout=None):
        lbl = QLabel(str(initial_text))
        if layout: 
            layout.addWidget(lbl)
            lbl.show()
        self.custom_controls[label_id] = lbl
        return lbl

    def update_control_value(self, control_id, value):
        if control_id in self.custom_controls:
            c = self.custom_controls[control_id]
            if isinstance(c, QLabel): c.setText(str(value))
            elif isinstance(c, QLineEdit): c.setText(str(value))
            elif isinstance(c, QCheckBox): c.setChecked(bool(value))
            elif isinstance(c, QComboBox): c.setCurrentText(str(value))
            elif isinstance(c, QSlider): c.setValue(int(float(value) * 1000))

    def refresh_plot(self): pass

class MathSimulator(BaseSimulator):
    def __init__(self, func, **kwargs):
        self.func = func
        # Call super after setting self.func but before anything else
        super().__init__(**kwargs)
        
        if 'params' in kwargs:
            self.params.update(kwargs.get('params', {}))
        self.t_range = kwargs.get('t_range', [0, 10])
        self.y_range = kwargs.get('y_range', None)
        self.is_ode = kwargs.get('is_ode', False)
        self.y0 = kwargs.get('y0', [1.0])
        self.initUI()
        
    def initUI(self):
        self.setWindowTitle('UniLab General Math Simulator')
        self.setGeometry(100, 100, 1100, 800)
        
        self.figure = Figure(figsize=(7, 5)); self.ax = None # Will be created in update
        self.canvas = FigureCanvas(self.figure); self.plot_layout.addWidget(self.canvas)
        
        self.update_simulation()
    
    def update_simulation(self):
        self.figure.clear()
        t_bounds = np.asarray(self.t_range).flatten()
        t = np.linspace(t_bounds[0], t_bounds[1], 500) if len(t_bounds) >= 2 else np.linspace(0, 10, 500)
        
        # Helper to call function with appropriate number of args
        def call_func(*args):
            f = self.func
            if hasattr(f, 'func'): f = f.func # Unwrap UnilabHandle
            
            import inspect
            try:
                sig = inspect.signature(f)
                num_params = len(sig.parameters)
            except:
                num_params = 1

            # Try calling with params if function seems to accept them
            if num_params >= len(args) + 1:
                try:
                    return self.func(*args, self.params)
                except TypeError as e:
                    if "argument" in str(e) or "given" in str(e):
                        pass # Fall through to standard call
                    else:
                        raise e

            # Standard call fallback
            try:
                return self.func(*args)
            except TypeError as e:
                if ("argument" in str(e) or "given" in str(e)) and num_params >= len(args) + 1:
                    # Try adding params as a last resort if not already tried
                    return self.func(*args, self.params)
                raise e

        try:
            if self.is_ode:
                self.ax = self.figure.add_subplot(111)
                from scipy.integrate import odeint
                y0 = np.asarray(self.y0).flatten()
                # odeint expects f(y, t, ...)
                sol = odeint(call_func, y0, t)
                for i in range(sol.shape[1]): self.ax.plot(t, sol[:, i], label=f'y[{i}]')
            else:
                # Check if func is 1D or 2D (heuristic)
                # Try calling with 2 args to see if it's a surface
                is_2d = False
                try:
                    res_test = call_func(t[0], t[0])
                    is_2d = True
                except:
                    try: res_test = call_func(t[0])
                    except: res_test = 0
                
                if is_2d:
                    self.ax = self.figure.add_subplot(111, projection='3d')
                    X, Y = np.meshgrid(t, t)
                    Z = call_func(X, Y)
                    self.ax.plot_surface(X, Y, Z, cmap='viridis')
                else:
                    self.ax = self.figure.add_subplot(111)
                    y = call_func(t)
                    if isinstance(y, (list, tuple)) or (isinstance(y, np.ndarray) and y.ndim > 1):
                        for i, yi in enumerate(y): self.ax.plot(t, yi, label=f'f_{i}(t)')
                    else: self.ax.plot(t, y, 'b-', label='f(t)')
            
            self.ax.set_title("Function Response"); self.ax.set_xlabel("Time / X"); self.ax.set_ylabel("Amplitude")
            self.ax.legend()
            global_config.apply_to_axes(self.ax, is_3d=getattr(self, 'is_2d', False))
        except Exception as e:
            if not self.ax: self.ax = self.figure.add_subplot(111)
            self.ax.text(0.5, 0.5, f"Error: {e}", transform=self.ax.transAxes)
            global_config.apply_to_axes(self.ax)
        self.canvas.draw()

class MLTrainingThread(QThread):
    progress_update = pyqtSignal(int, float, object)
    finished_training = pyqtSignal()
    def __init__(self, model, X, y, epochs, lr, l1=0.0, l2=0.0):
        super().__init__(); self.model = model
        self.X = np.array(X).copy() if X is not None else None
        self.y = np.array(y).copy() if y is not None else None
        self.epochs, self.lr, self.l1, self.l2 = int(epochs), lr, l1, l2
        self._is_running = True; self.grid_pts, self.meshgrid = None, None
        if self.X is not None and self.X.shape[1] == 2:
            x_min, x_max = self.X[:, 0].min() - 0.5, self.X[:, 0].max() + 0.5
            y_min, y_max = self.X[:, 1].min() - 0.5, self.X[:, 1].max() + 0.5
            xx, yy = np.meshgrid(np.arange(x_min, x_max, 0.1), np.arange(y_min, y_max, 0.1))
            self.grid_pts = np.c_[xx.ravel(), yy.ravel()]; self.meshgrid = (xx.copy(), yy.copy())
    def run(self):
        def callback(epoch, loss):
            if not self._is_running: return False
            Z = None
            if self.grid_pts is not None and (epoch % max(1, self.epochs//20) == 0 or epoch == self.epochs):
                try:
                    Z = self.model.predict(self.grid_pts)
                    if isinstance(Z, np.ndarray):
                        if Z.ndim > 1 and Z.shape[1] > 1: Z = np.argmax(Z, axis=1)
                        elif Z.ndim > 1 and Z.shape[1] == 1 and type(self.model).__name__ == 'NeuralNet': Z = (Z > 0.5).astype(int)
                except: pass
            self.progress_update.emit(epoch, loss, (self.meshgrid, Z) if Z is not None else None)
            QThread.msleep(1); return True
        try:
            if hasattr(self.model, 'train'): self.model.train(self.X, self.y, epochs=self.epochs, lr=self.lr, l1=self.l1, l2=self.l2, callback=callback)
            elif hasattr(self.model, 'fit'):
                if type(self.model).__name__ in ['LogisticRegression', 'SVM']:
                    if hasattr(self.model, 'epochs'): self.model.epochs = self.epochs
                    if hasattr(self.model, 'lr'): self.model.lr = self.lr
                    self.model.fit(self.X, self.y, callback=callback)
                else: self.model.fit(self.X, self.y); callback(self.epochs, 0.0)
        except Exception as e: 
            import traceback
            traceback.print_exc()
            sys.stderr.write(f"ML Training Error: {e}\n")
        self.finished_training.emit()
    def stop(self): self._is_running = False

class KMeansTrainingThread(QThread):
    progress_update = pyqtSignal(int, object, object)
    finished_training = pyqtSignal()
    def __init__(self, model, X):
        super().__init__(); self.model = model; self.X = np.array(X).copy(); self._is_running = True
    def run(self):
        def callback(epoch, centroids, labels):
            if not self._is_running: return False
            self.progress_update.emit(epoch, centroids.copy(), labels.copy())
            QThread.msleep(150); return True
        try: self.model.fit(self.X, callback=callback)
        except Exception as e: print(f"KMeans Error: {e}")
        self.finished_training.emit()
    def stop(self): self._is_running = False

class KMeansSimulator(BaseSimulator):
    def __init__(self, model, **kwargs):
        self.model = model; self.X = kwargs.get('X', None)
        super().__init__(**kwargs)
        self.training_thread = None; self.initUI()
    def initUI(self):
        self.setWindowTitle('UniLab K-Means Clustering Simulator'); self.setGeometry(150, 150, 1100, 800)
        self.figure = Figure(figsize=(7, 5)); self.ax = self.figure.add_subplot(111)
        self.canvas = FigureCanvas(self.figure); self.plot_layout.addWidget(self.canvas)
        
        train_group = QGroupBox("Clustering Controls"); train_layout = QVBoxLayout()
        self.status_label = QLabel(f"Status: Ready (K={self.model.k})"); train_layout.addWidget(self.status_label)
        self.start_btn = QPushButton("Start/Resume"); self.start_btn.clicked.connect(self.start_training); train_layout.addWidget(self.start_btn)
        self.pause_btn = QPushButton("Pause"); self.pause_btn.clicked.connect(self.pause_training); self.pause_btn.setEnabled(False); train_layout.addWidget(self.pause_btn)
        self.reset_btn = QPushButton("Stop/Reset"); self.reset_btn.clicked.connect(self.reset_training); train_layout.addWidget(self.reset_btn)
        train_group.setLayout(train_layout); self.controls_layout.insertWidget(0, train_group)
        
        if self.X is not None and self.X.shape[1] >= 2:
            self.ax.scatter(self.X[:, 0], self.X[:, 1], c='gray', alpha=0.5, s=30)
            self.ax.set_title("Unclustered Data"); global_config.apply_to_axes(self.ax)
        self.canvas.draw()
    def start_training(self):
        if self.X is None: self.status_label.setText("Error: X required."); return
        self.start_btn.setEnabled(False); self.pause_btn.setEnabled(True); self.status_label.setText("Status: Clustering...")
        self.training_thread = KMeansTrainingThread(self.model, self.X)
        self.training_thread.progress_update.connect(self.update_plot)
        self.training_thread.finished_training.connect(self.training_finished); self.training_thread.start()
    def pause_training(self):
        if self.training_thread: self.training_thread.stop(); self.training_thread.wait()
        self.status_label.setText("Status: Paused"); self.start_btn.setEnabled(True); self.pause_btn.setEnabled(False)
    def reset_training(self):
        self.pause_training(); 
        if hasattr(self.model, 'reset'): self.model.reset()
        self.ax.clear()
        if self.X is not None and self.X.shape[1] >= 2:
            self.ax.scatter(self.X[:, 0], self.X[:, 1], c='gray', alpha=0.5, s=30)
            self.ax.set_title("Unclustered Data"); global_config.apply_to_axes(self.ax)
        self.status_label.setText("Status: Reset"); self.canvas.draw()
    def update_plot(self, epoch, centroids, labels):
        self.ax.clear()
        if self.X is not None and self.X.shape[1] >= 2:
            self.ax.scatter(self.X[:, 0], self.X[:, 1], c=labels, cmap='viridis', alpha=0.6, s=30)
            if centroids is not None and centroids.shape[1] >= 2:
                self.ax.scatter(centroids[:, 0], centroids[:, 1], c='red', marker='X', s=200, edgecolors='black', label='Centroids'); self.ax.legend()
            self.ax.set_title(f"K-Means Clustering (Epoch {epoch})"); global_config.apply_to_axes(self.ax)
        self.canvas.draw()
    def training_finished(self): self.status_label.setText("Status: Clustering Done"); self.start_btn.setEnabled(True); self.pause_btn.setEnabled(False)

class MLSimulator(BaseSimulator):
    def __init__(self, model, **kwargs):
        self.model = model; self.X, self.y = kwargs.get('X', None), kwargs.get('y', None)
        super().__init__(**kwargs)
        self.epochs, self.lr, self.l1, self.l2 = kwargs.get('epochs', 1000), kwargs.get('lr', 0.01), kwargs.get('l1', 0.0), kwargs.get('l2', 0.0)
        self.epochs_history, self.loss_history, self.acc_history, self.current_Z = [], [], [], None
        self.is_classification = False
        if self.y is not None:
            y_flat = np.asarray(self.y).flatten()
            uv = np.unique(y_flat)
            if len(uv) < 20 and np.all(np.isclose(np.mod(y_flat, 1), 0)): self.is_classification = True
        self.training_thread = None; self.initUI()
    def initUI(self):
        self.setWindowTitle('UniLab ML Simulator'); self.setGeometry(150, 150, 1200, 850)
        self.tabs = QTabWidget(); self.metrics_tab = QWidget(); self.metrics_layout = QVBoxLayout(self.metrics_tab)
        self.metrics_figure = Figure(figsize=(8, 6))
        if self.is_classification:
            self.loss_ax = self.metrics_figure.add_subplot(211)
            self.acc_ax = self.metrics_figure.add_subplot(212)
            self.metrics_figure.subplots_adjust(hspace=0.4)
        else:
            self.loss_ax = self.metrics_figure.add_subplot(111)
        self.metrics_canvas = FigureCanvas(self.metrics_figure); self.metrics_layout.addWidget(self.metrics_canvas); self.tabs.addTab(self.metrics_tab, "Metrics")
        self.db_tab = QWidget(); self.db_layout = QVBoxLayout(self.db_tab); self.db_figure = Figure(figsize=(8, 6))
        self.db_ax = self.db_figure.add_subplot(111); self.db_canvas = FigureCanvas(self.db_figure); self.db_layout.addWidget(self.db_canvas); self.tabs.addTab(self.db_tab, "Boundary")
        
        # Add Architecture tab for Neural Networks
        if type(self.model).__name__ == 'NeuralNet':
            self.arch_tab = QWidget(); self.arch_layout = QVBoxLayout(self.arch_tab); self.arch_figure = Figure(figsize=(8, 6))
            self.arch_ax = self.arch_figure.add_subplot(111); self.arch_canvas = FigureCanvas(self.arch_figure); self.arch_layout.addWidget(self.arch_canvas)
            self.tabs.addTab(self.arch_tab, "Architecture")
            
        self.plot_layout.addWidget(self.tabs)

        train_group = QGroupBox("Training Controls"); train_layout = QVBoxLayout()
        self.status_label = QLabel(f"Status: Ready ({type(self.model).__name__})"); train_layout.addWidget(self.status_label)
        self.progress_bar = QProgressBar(); self.progress_bar.setMaximum(self.epochs); train_layout.addWidget(self.progress_bar)
        btn_layout = QHBoxLayout(); self.start_btn = QPushButton("Start/Resume"); self.start_btn.clicked.connect(self.start_training); btn_layout.addWidget(self.start_btn)
        self.pause_btn = QPushButton("Pause"); self.pause_btn.clicked.connect(self.pause_training); self.pause_btn.setEnabled(False); train_layout.addWidget(self.pause_btn)
        self.reset_btn = QPushButton("Stop/Reset"); self.reset_btn.clicked.connect(self.reset_training); btn_layout.addWidget(self.reset_btn)
        train_layout.addLayout(btn_layout); train_group.setLayout(train_layout); self.controls_layout.insertWidget(0, train_group)
        
        hp_group = QGroupBox("Live Tuning"); hp_layout = QFormLayout()
        self.lr_label = QLabel(f"{self.lr:.4f}"); self.lr_slider = QSlider(Qt.Horizontal); self.lr_slider.setRange(1, 1000); self.lr_slider.setValue(int(self.lr * 10000))
        self.lr_slider.valueChanged.connect(self.update_params); hp_layout.addRow("LR:", self.lr_label); hp_layout.addRow(self.lr_slider)
        self.l2_label = QLabel(f"{self.l2:.4f}"); self.l2_slider = QSlider(Qt.Horizontal); self.l2_slider.setRange(0, 500); self.l2_slider.setValue(int(self.l2 * 10000))
        self.l2_slider.valueChanged.connect(self.update_params); hp_layout.addRow("L2:", self.l2_label); hp_layout.addRow(self.l2_slider)
        hp_group.setLayout(hp_layout); self.controls_layout.insertWidget(1, hp_group)
        
        self.refresh_plot()
    def update_params(self):
        self.lr = self.lr_slider.value()/10000.0; self.lr_label.setText(f"{self.lr:.4f}")
        self.l2 = self.l2_slider.value()/10000.0; self.l2_label.setText(f"{self.l2:.4f}")
        if self.training_thread: self.training_thread.lr, self.training_thread.l2 = self.lr, self.l2
    def refresh_plot(self):
        self.loss_ax.clear()
        if self.epochs_history:
            self.loss_ax.plot(self.epochs_history, self.loss_history, color=global_config.secondary_color, lw=global_config.line_width)
            self.loss_ax.set_ylabel('Loss')
            self.loss_ax.set_title(f'Current Loss: {self.loss_history[-1]:.4f}')
            if self.is_classification and hasattr(self, 'acc_ax'):
                self.acc_ax.clear()
                self.acc_ax.plot(self.epochs_history, self.acc_history, color=global_config.tertiary_color, lw=global_config.line_width)
                self.acc_ax.set_ylabel('Accuracy (%)')
                self.acc_ax.set_title(f'Current Accuracy: {self.acc_history[-1]:.1f}%')
                self.acc_ax.set_ylim(0, 105)
                global_config.apply_to_axes(self.acc_ax)
        self.loss_ax.set_xlabel('Epoch')
        global_config.apply_to_axes(self.loss_ax)
        self.metrics_figure.tight_layout()
        self.metrics_canvas.draw()
        if self.current_Z is not None:
            mx, mz = self.current_Z; self.db_ax.clear(); self.db_ax.contourf(mx[0], mx[1], mz.reshape(mx[0].shape), alpha=0.3, cmap='coolwarm')
            self.db_ax.scatter(self.X[:, 0], self.X[:, 1], c=self.y.flatten(), edgecolor='k', cmap='coolwarm'); self.db_ax.set_title('Decision Boundary')
            global_config.apply_to_axes(self.db_ax)
            self.db_figure.tight_layout()
            self.db_canvas.draw()
            
        if hasattr(self, 'arch_ax'):
            self.arch_ax.clear()
            # Draw NN Architecture
            layer_sizes = self.model.layers
            v_spacing = 1.0 / max(layer_sizes)
            h_spacing = 1.0 / (len(layer_sizes) - 1)
            radius = v_spacing / 4.0
            
            # Edges
            for n, (l_a, l_b) in enumerate(zip(layer_sizes[:-1], layer_sizes[1:])):
                top_a = v_spacing * (l_a - 1) / 2.0
                top_b = v_spacing * (l_b - 1) / 2.0
                weights = self.model.weights[n]
                for m in range(l_a):
                    for o in range(l_b):
                        w = weights[m, o]
                        color = 'red' if w < 0 else 'green'
                        alpha = min(1.0, abs(w) * 0.5)
                        self.arch_ax.plot([n*h_spacing, (n+1)*h_spacing], 
                                          [top_a - m*v_spacing, top_b - o*v_spacing], 
                                          color=color, alpha=alpha, lw=1)
            
            # Nodes
            for n, l_s in enumerate(layer_sizes):
                top = v_spacing * (l_s - 1) / 2.0
                for m in range(l_s):
                    circle = matplotlib.patches.Circle((n*h_spacing, top - m*v_spacing), radius, 
                                                       color=global_config.primary_color, ec=global_config.fg_color, zorder=4)
                    self.arch_ax.add_patch(circle)
            
            self.arch_ax.set_aspect('equal')
            self.arch_ax.axis('off')
            global_config.apply_to_axes(self.arch_ax)
            self.arch_canvas.draw()
    def start_training(self):
        if self.X is None or self.y is None: self.status_label.setText("Error: Data required."); return
        self.start_btn.setEnabled(False); self.pause_btn.setEnabled(True); self.status_label.setText("Status: Training...")
        rem = self.epochs - len(self.epochs_history)
        if rem <= 0: self.status_label.setText("Status: Done"); return
        self.training_thread = MLTrainingThread(self.model, self.X, self.y, rem, self.lr, self.l1, self.l2)
        self.training_thread.progress_update.connect(self.update_plot)
        self.training_thread.finished_training.connect(self.training_finished); self.training_thread.start()
    def pause_training(self):
        if self.training_thread: self.training_thread.stop(); self.training_thread.wait()
        self.status_label.setText("Status: Paused"); self.start_btn.setEnabled(True); self.pause_btn.setEnabled(False)
    def reset_training(self):
        self.pause_training(); 
        if hasattr(self.model, 'reset'): self.model.reset()
        self.epochs_history, self.loss_history, self.acc_history, self.current_Z = [], [], [], None
        self.progress_bar.setValue(0); self.status_label.setText("Status: Reset"); self.refresh_plot()
    def update_plot(self, off, loss, Z=None):
        cur = len(self.epochs_history) + 1; self.epochs_history.append(cur); self.loss_history.append(loss)
        if self.is_classification:
            p = self.model.predict(self.X)
            if p.ndim > 1 and p.shape[1] > 1: p = np.argmax(p, axis=1)
            self.acc_history.append(np.mean(p.flatten() == self.y.flatten()) * 100)
        self.progress_bar.setValue(cur)
        if Z is not None: self.current_Z = Z
        self.refresh_plot()
    def training_finished(self): self.status_label.setText("Status: Done"); self.start_btn.setEnabled(True); self.pause_btn.setEnabled(False)

class ControlSimulator(BaseSimulator):
    def __init__(self, model, **kwargs):
        self.sys_model = model
        super().__init__(**kwargs)
        self.params.update(kwargs)
        self.input_type = kwargs.get('input', 'step')
        self.t_range = kwargs.get('t_range', kwargs.get('time', [0, 10]))
        self.kp, self.ki, self.kd = kwargs.get('kp', 1.0), kwargs.get('ki', 0.0), kwargs.get('kd', 0.0); self.initUI()
    def initUI(self):
        self.setWindowTitle('UniLab Control Simulator'); self.setGeometry(100, 100, 1100, 800)
        self.fig = Figure(figsize=(6, 4)); self.ax = self.fig.add_subplot(111)
        self.canvas = FigureCanvas(self.fig); self.plot_layout.addWidget(self.canvas)
        
        inp_group = QGroupBox("Input Configuration"); inp_lay = QVBoxLayout()
        self.input_combo = QComboBox(); self.input_combo.addItems(['step', 'impulse', 'sine', 'square'])
        self.input_combo.setCurrentText(self.input_type); self.input_combo.currentTextChanged.connect(self.update_simulation)
        inp_lay.addWidget(QLabel("Input Type:")); inp_lay.addWidget(self.input_combo)
        inp_group.setLayout(inp_lay); self.controls_layout.insertWidget(0, inp_group)
        
        pid_group = QGroupBox("PID Tuning"); pid_lay = QVBoxLayout()
        self.kp_lbl = QLabel(f"Kp: {self.kp:.2f}"); self.kp_sl = QSlider(Qt.Horizontal); self.kp_sl.setRange(0, 1000); self.kp_sl.setValue(int(self.kp*100))
        self.kp_sl.valueChanged.connect(self.update_pid); pid_lay.addWidget(self.kp_lbl); pid_lay.addWidget(self.kp_sl)
        self.ki_lbl = QLabel(f"Ki: {self.ki:.2f}"); self.ki_sl = QSlider(Qt.Horizontal); self.ki_sl.setRange(0, 500); self.ki_sl.setValue(int(self.ki*100))
        self.ki_sl.valueChanged.connect(self.update_pid); pid_lay.addWidget(self.ki_lbl); pid_lay.addWidget(self.ki_sl)
        self.kd_lbl = QLabel(f"Kd: {self.kd:.2f}"); self.kd_sl = QSlider(Qt.Horizontal); self.kd_sl.setRange(0, 500); self.kd_sl.setValue(int(self.kd*100))
        self.kd_sl.valueChanged.connect(self.update_pid); pid_lay.addWidget(self.kd_lbl); pid_lay.addWidget(self.kd_sl)
        pid_group.setLayout(pid_lay); self.controls_layout.insertWidget(1, pid_group)
        
        self.update_simulation()
    def update_pid(self):
        self.kp, self.ki, self.kd = self.kp_sl.value()/100.0, self.ki_sl.value()/100.0, self.kd_sl.value()/100.0
        self.kp_lbl.setText(f"Kp: {self.kp:.2f}"); self.ki_lbl.setText(f"Ki: {self.ki:.2f}"); self.kd_lbl.setText(f"Kd: {self.kd:.2f}"); self.update_simulation()
    def update_simulation(self):
        self.ax.clear(); inp = self.input_combo.currentText(); C_sys = signal.TransferFunction([self.kd, self.kp, self.ki], [1, 0])
        ps = self.sys_model if not isinstance(self.sys_model, signal.StateSpace) else signal.TransferFunction(*signal.ss2tf(self.sys_model.A, self.sys_model.B, self.sys_model.C, self.sys_model.D))
        ln, ld = np.convolve(C_sys.num, ps.num), np.convolve(C_sys.den, ps.den); sys_c = signal.TransferFunction(ln, np.polyadd(ld, ln))
        tr = np.asarray(self.t_range).flatten()
        t = np.linspace(tr[0], tr[1], 500)
        
        c_prim = global_config.primary_color
        c_sec = global_config.secondary_color
        
        if inp == 'step': u = np.ones_like(t); _, y, _ = signal.lsim(sys_c, u, t); self.ax.plot(t, u, color=c_sec, linestyle='--'); self.ax.plot(t, y, color=c_prim)
        elif inp == 'impulse': _, y = signal.impulse(sys_c, T=t); self.ax.plot(t, y, color=c_prim)
        elif inp == 'sine': u = np.sin(2*np.pi*t); _, y, _ = signal.lsim(sys_c, u, t); self.ax.plot(t, u, color=c_sec, linestyle='--'); self.ax.plot(t, y, color=c_prim)
        elif inp == 'square': u = signal.square(2*np.pi*0.5*t); _, y, _ = signal.lsim(sys_c, u, t); self.ax.plot(t, u, color=c_sec, linestyle='--'); self.ax.plot(t, y, color=c_prim)
        global_config.apply_to_axes(self.ax); self.canvas.draw()

class PhysicsSimulator(BaseSimulator):
    def __init__(self, model, **kwargs):
        self.model_name = model
        super().__init__(**kwargs)
        self.params.update(kwargs)
        self.t_range = kwargs.get('t_range', kwargs.get('time', None))
        self.init_defaults()
        self.animation_timer = QTimer(self); self.animation_timer.timeout.connect(self.animate_step)
        self.animation_idx = 0; self.sol = None; self.t = None
        self.initUI()
    def init_defaults(self):
        d = {'pendulum': {'g': 9.81, 'length': 1.0, 'theta0': np.pi/4, 'b': 0.25},
             'double_pendulum': {'m1': 1.0, 'm2': 1.0, 'l1': 1.0, 'l2': 1.0, 'theta1': np.pi/2, 'theta2': np.pi/2},
             'lorenz': {'sigma': 10.0, 'rho': 28.0, 'beta': 8.0/3.0},
             'nbody': {'G': 1.0, 'dt': 0.01},
             'projectile': {'v0': 20.0, 'angle': 45.0, 'g': 9.81, 'k': 0.1},
             'van_der_pol': {'mu': 1.5},
             'spring_mass': {'m': 1.0, 'k': 10.0, 'c': 0.5, 'x0': 1.0},
             'optimization': {'lr': 0.1, 'start_x': 2.0, 'start_y': 2.0},
             'wave': {'c': 1.0, 'L': 10.0, 'n': 50}}
        for k, v in d.get(self.model_name, {}).items(): self.params.setdefault(k, v)
        
        # Default time ranges if not provided
        if self.t_range is None:
            tr = {'pendulum': [0, 20], 'double_pendulum': [0, 20], 'lorenz': [0, 50], 'nbody': [0, 10], 
                  'projectile': [0, 5], 'van_der_pol': [0, 50], 'spring_mass': [0, 20],
                  'optimization': [0, 50], 'wave': [0, 10]}
            self.t_range = tr.get(self.model_name, [0, 10])

    def initUI(self):
        self.setWindowTitle(f'UniLab {self.model_name}'); self.setGeometry(100, 100, 1100, 800)
        self.fig = Figure(figsize=(7, 6))
        is_3d = self.model_name in ['lorenz', 'nbody', 'optimization']
        self.ax = self.fig.add_subplot(111, projection='3d') if is_3d else self.fig.add_subplot(111)
        self.canvas = FigureCanvas(self.fig); self.plot_layout.addWidget(self.canvas)
        
        g = QGroupBox("Model Parameters"); f = QFormLayout()
        if self.model_name == 'pendulum': self.add_s("Len", 0.1, 5, 'length', f); self.add_s("G", 1, 20, 'g', f)
        elif self.model_name == 'double_pendulum': self.add_s("L1", 0.1, 2, 'l1', f); self.add_s("L2", 0.1, 2, 'l2', f)
        elif self.model_name == 'lorenz': self.add_s("Rho", 0, 50, 'rho', f); self.add_s("Sigma", 0, 30, 'sigma', f)
        elif self.model_name == 'nbody': self.add_s("G", 0.1, 10, 'G', f)
        elif self.model_name == 'projectile': self.add_s("V0", 1, 50, 'v0', f); self.add_s("Angle", 0, 90, 'angle', f); self.add_s("Drag", 0, 1, 'k', f)
        elif self.model_name == 'van_der_pol': self.add_s("Mu", 0, 10, 'mu', f)
        elif self.model_name == 'spring_mass': self.add_s("Mass", 0.1, 10, 'm', f); self.add_s("Stiff", 1, 50, 'k', f); self.add_s("Damp", 0, 5, 'c', f)
        elif self.model_name == 'optimization': self.add_s("LR", 0.01, 1.0, 'lr', f)
        elif self.model_name == 'wave': self.add_s("Speed", 0.1, 5, 'c', f)
        g.setLayout(f); self.controls_layout.insertWidget(0, g)
        
        anim_group = QGroupBox("Animation"); anim_lay = QVBoxLayout()
        self.run_btn = QPushButton("Run Animation")
        self.run_btn.clicked.connect(self.toggle_animation)
        anim_lay.addWidget(self.run_btn)
        
        self.time_label = QLabel("Time: 0.00s")
        anim_lay.addWidget(self.time_label)
        self.time_slider = QSlider(Qt.Horizontal)
        self.time_slider.setRange(0, 100)
        self.time_slider.sliderMoved.connect(self.seek_animation)
        anim_lay.addWidget(self.time_slider)
        anim_group.setLayout(anim_lay); self.controls_layout.insertWidget(1, anim_group)
        
        self.update_simulation()
    def add_s(self, lab, mn, mx, k, l):
        v = self.params[k]; lbl = QLabel(f"{v:.2f}"); sl = QSlider(Qt.Horizontal); sl.setRange(int(mn*100), int(mx*100)); sl.setValue(int(v*100))
        def u(val): nv = val/100.0; self.params[k] = nv; lbl.setText(f"{nv:.2f}"); self.update_simulation()
        sl.valueChanged.connect(u); l.addRow(QLabel(f"{lab}:"), lbl); l.addRow(sl)
    def toggle_animation(self):
        if self.animation_timer.isActive():
            self.animation_timer.stop(); self.run_btn.setText("Resume Animation")
        else:
            if self.sol is None or self.animation_idx >= len(self.sol)-1:
                self.update_simulation(); self.animation_idx = 0
            self.animation_timer.start(30); self.run_btn.setText("Pause Animation")
    def seek_animation(self, value):
        self.animation_timer.stop(); self.run_btn.setText("Resume Animation")
        self.animation_idx = value; self.render_frame(value)
    def animate_step(self):
        if self.sol is None or self.animation_idx >= len(self.sol):
            self.animation_timer.stop(); self.run_btn.setText("Run Animation"); return
        
        self.render_frame(self.animation_idx)
        self.animation_idx += 2
    def export_video(self):
        if self.sol is None or len(self.sol) == 0:
            from PyQt5.QtWidgets import QMessageBox
            QMessageBox.warning(self, "No Data", "No simulation data to export. Run the simulation first.")
            return
            
        options = QFileDialog.Options()
        file_name, selected_filter = QFileDialog.getSaveFileName(self, "Save Simulation Video/GIF", "", "GIF Animation (*.gif);;MP4 Video (*.mp4);;All Files (*)", options=options)
        
        if file_name:
            # Ensure extension
            if not os.path.splitext(file_name)[1]:
                if "GIF" in selected_filter: file_name += ".gif"
                else: file_name += ".mp4"

            from PyQt5.QtWidgets import QProgressDialog
            from matplotlib.animation import FuncAnimation, PillowWriter, FFMpegWriter
            import matplotlib.pyplot as plt
            
            progress = QProgressDialog("Generating animation...", "Cancel", 0, len(self.sol), self)
            progress.setWindowModality(Qt.WindowModal)
            progress.show()
            
            original_idx = self.animation_idx
            
            def init():
                pass
                
            def update(frame):
                self.render_frame(frame)
                progress.setValue(frame)
                if progress.wasCanceled():
                    return self.ax.get_children()
                return self.ax.get_children()

            # Temporarily stop animation timer if running
            was_running = self.animation_timer.isActive()
            if was_running: self.animation_timer.stop()
            
            # Step size for reducing frame count if it's very large
            step = 1 if len(self.sol) < 500 else max(1, len(self.sol) // 500)
            frames = range(0, len(self.sol), step)
            progress.setMaximum(len(frames))
            
            def custom_update(i):
                frame = frames[i]
                self.render_frame(frame)
                progress.setValue(i)
                return self.ax.get_children()
                
            anim = FuncAnimation(self.fig, custom_update, frames=len(frames), init_func=init, blit=False, repeat=False)
            
            try:
                if file_name.endswith('.gif'):
                    writer = PillowWriter(fps=30)
                    anim.save(file_name, writer=writer)
                else:
                    try:
                        writer = FFMpegWriter(fps=30)
                        anim.save(file_name, writer=writer)
                    except Exception as e:
                        print(f"FFMpeg export failed (is ffmpeg installed?), falling back to GIF. Error: {e}")
                        file_name = os.path.splitext(file_name)[0] + ".gif"
                        writer = PillowWriter(fps=30)
                        anim.save(file_name, writer=writer)
            except Exception as e:
                from PyQt5.QtWidgets import QMessageBox
                QMessageBox.critical(self, "Export Error", f"Failed to save animation: {e}")
            finally:
                progress.setValue(progress.maximum())
                self.render_frame(original_idx) # Restore frame
                if was_running: self.animation_timer.start(30)
                
    def render_frame(self, idx):
        if self.sol is None or idx >= len(self.sol): return
        
        # Update slider and label without triggering seek_animation
        self.time_slider.blockSignals(True)
        self.time_slider.setValue(idx)
        self.time_slider.blockSignals(False)
        self.time_label.setText(f"Time: {self.t[idx]:.2f}s")
        
        self.ax.clear()
        if self.model_name == 'pendulum':
            self.ax.plot([0, np.sin(self.sol[idx, 0])], [0, -np.cos(self.sol[idx, 0])], color=global_config.primary_color, marker='o', linestyle='-')
            self.ax.set_xlim(-1.2, 1.2); self.ax.set_ylim(-1.2, 1.2); self.ax.set_title(f"Pendulum (t={self.t[idx]:.2f}s)")
        elif self.model_name == 'double_pendulum':
            l1, l2 = self.params['l1'], self.params['l2']
            x1, y1 = l1*np.sin(self.sol[idx, 0]), -l1*np.cos(self.sol[idx, 0])
            x2, y2 = x1 + l2*np.sin(self.sol[idx, 2]), y1 - l2*np.cos(self.sol[idx, 2])
            self.ax.plot([0, x1, x2], [0, y1, y2], color=global_config.primary_color, marker='o', linestyle='-')
            self.ax.plot(l1*np.sin(self.sol[:idx, 0]) + l2*np.sin(self.sol[:idx, 2]), -l1*np.cos(self.sol[:idx, 0]) - l2*np.cos(self.sol[:idx, 2]), color=global_config.secondary_color, alpha=0.5)
            lim = l1 + l2 + 0.2; self.ax.set_xlim(-lim, lim); self.ax.set_ylim(-lim, lim); self.ax.set_title("Double Pendulum")
        elif self.model_name == 'lorenz':
            self.ax.plot(self.sol[:idx, 0], self.sol[:idx, 1], self.sol[:idx, 2], color=global_config.secondary_color)
            self.ax.scatter(self.sol[idx, 0], self.sol[idx, 1], self.sol[idx, 2], color=global_config.primary_color)
            self.ax.set_title("Lorenz Attractor")
        elif self.model_name == 'nbody':
            p = self.sol[idx].reshape(-1, 6)[:, :3]
            colors = [global_config.primary_color, global_config.secondary_color, global_config.tertiary_color]
            for i in range(3):
                self.ax.plot(self.sol[:idx, i*6], self.sol[:idx, i*6+1], self.sol[:idx, i*6+2], color=colors[i], alpha=0.5)
                self.ax.scatter(p[i, 0], p[i, 1], p[i, 2], color=colors[i], s=50)
            self.ax.set_title("N-Body Simulation")
        elif self.model_name == 'projectile':
            self.ax.plot(self.sol[:idx, 0], self.sol[:idx, 1], color=global_config.secondary_color, linestyle='--')
            self.ax.scatter(self.sol[idx, 0], self.sol[idx, 1], s=100, color=global_config.primary_color)
            self.ax.set_xlim(0, max(np.max(self.sol[:, 0]), 10)); self.ax.set_ylim(0, max(np.max(self.sol[:, 1]), 10))
            self.ax.set_title(f"Projectile Motion (v0={self.params['v0']})")
        elif self.model_name == 'van_der_pol':
            self.ax.plot(self.sol[:idx, 0], self.sol[:idx, 1], color=global_config.tertiary_color)
            self.ax.scatter(self.sol[idx, 0], self.sol[idx, 1], color=global_config.primary_color)
            self.ax.set_xlabel("Position (x)"); self.ax.set_ylabel("Velocity (v)")
            self.ax.set_title(f"Van der Pol Oscillator (mu={self.params['mu']})")
        elif self.model_name == 'spring_mass':
            x = self.sol[idx, 0]
            self.ax.plot([-2, 2], [0, 0], color=global_config.fg_color) # Floor
            self.ax.add_patch(matplotlib.patches.Rectangle((x-0.2, 0), 0.4, 0.4, color=global_config.primary_color)) # Mass
            # Spring visualization
            sx = np.linspace(-1.5, x-0.2, 50); sy = 0.2 + 0.1 * np.sin(np.linspace(0, 10*np.pi, 50))
            self.ax.plot(sx, sy, color=global_config.secondary_color); self.ax.plot([-1.5, -1.5], [0, 0.5], color=global_config.fg_color, lw=3) # Wall
            self.ax.set_xlim(-2, 2); self.ax.set_ylim(-0.5, 1.0); self.ax.set_title("Spring-Mass System")
        elif self.model_name == 'optimization':
            X, Y = np.meshgrid(np.linspace(-3, 3, 50), np.linspace(-3, 3, 50))
            Z = X**2 + Y**2 + 2*np.sin(2*X)*np.cos(2*Y)
            self.ax.plot_surface(X, Y, Z, cmap='viridis', alpha=0.2)
            self.ax.plot(self.sol[:idx, 0], self.sol[:idx, 1], self.sol[:idx, 2], color=global_config.secondary_color, lw=2)
            self.ax.scatter(self.sol[idx, 0], self.sol[idx, 1], self.sol[idx, 2], color=global_config.primary_color, s=50)
            self.ax.set_title("Gradient Descent Optimization")
        elif self.model_name == 'wave':
            x = np.linspace(0, self.params['L'], self.params['n'])
            self.ax.plot(x, self.sol[idx], color=global_config.primary_color, lw=2)
            self.ax.set_ylim(-1.5, 1.5); self.ax.set_xlim(0, self.params['L'])
            self.ax.set_title(f"1D Wave Equation (t={self.t[idx]:.2f}s)")
        
        global_config.apply_to_axes(self.ax, is_3d=(self.model_name in ['lorenz', 'nbody', 'optimization']))
        self.canvas.draw()
    def update_simulation(self):
        self.ax.clear(); from scipy.integrate import odeint
        tr = np.asarray(self.t_range).flatten()
        num_pts = 1000 if self.model_name != 'lorenz' else 5000
        self.t = np.linspace(tr[0], tr[1], num_pts)
        
        if self.model_name == 'pendulum':
            self.sol = odeint(lambda y, t, g, L, b: [y[1], -b*y[1]-(g/L)*np.sin(y[0])], [self.params['theta0'], 0], self.t, args=(self.params['g'], self.params['length'], self.params['b']))
            self.ax.plot(self.t, self.sol[:, 0], color=global_config.primary_color); self.ax.set_title("Pendulum (Static View)")
        elif self.model_name == 'double_pendulum':
            def dp(y, t, m1, m2, l1, l2, g):
                t1, w1, t2, w2 = y; c, s = np.cos(t1-t2), np.sin(t1-t2)
                d1 = (m2*g*np.sin(t2)*c - m2*s*(l1*w1**2*c + l2*w2**2) - (m1+m2)*g*np.sin(t1))/(l1*(m1+m2*s**2))
                d2 = ((m1+m2)*(l1*w1**2*s - g*np.sin(t2) + g*np.sin(t1)*c) + m2*l2*w2**2*s*c)/(l2*(m1+m2*s**2))
                return [w1, d1, w2, d2]
            self.sol = odeint(dp, [self.params['theta1'], 0, self.params['theta2'], 0], self.t, args=(self.params['m1'], self.params['m2'], self.params['l1'], self.params['l2'], 9.81))
            x1 = self.params['l1']*np.sin(self.sol[:, 0]); y1 = -self.params['l1']*np.cos(self.sol[:, 0]); x2 = x1+self.params['l2']*np.sin(self.sol[:, 2]); y2 = y1-self.params['l2']*np.cos(self.sol[:, 2])
            self.ax.plot(x2, y2, color=global_config.secondary_color, alpha=0.5); self.ax.plot([0, x1[-1], x2[-1]], [0, y1[-1], y2[-1]], color=global_config.primary_color, marker='o'); lim = self.params['l1']+self.params['l2']; self.ax.set_xlim(-lim, lim); self.ax.set_ylim(-lim, lim)
        elif self.model_name == 'lorenz':
            self.sol = odeint(lambda y, t, s, r, b: [s*(y[1]-y[0]), y[0]*(r-y[2])-y[1], y[0]*y[1]-b*y[2]], [1, 1, 1], self.t, args=(self.params['sigma'], self.params['rho'], self.params['beta']))
            self.ax.plot(self.sol[:, 0], self.sol[:, 1], self.sol[:, 2], color=global_config.secondary_color)
        elif self.model_name == 'nbody':
            def nb(y, t, G):
                p, v, a = y.reshape(-1, 6)[:, :3], y.reshape(-1, 6)[:, 3:], np.zeros((3, 3))
                for i in range(3):
                    for j in range(3):
                        if i == j: continue
                        r = p[j]-p[i]; a[i] += G*r/(np.linalg.norm(r)**3+0.1)
                return np.hstack([v, a]).flatten()
            self.sol = odeint(nb, [1,0,0, 0,0.5,0, -1,0,0, 0,-0.5,0, 0,1,0, 0.5,0,0], self.t, args=(self.params['G'],))
            colors = [global_config.primary_color, global_config.secondary_color, global_config.tertiary_color]
            for i in range(3): self.ax.plot(self.sol[:, i*6], self.sol[:, i*6+1], self.sol[:, i*6+2], color=colors[i])
        elif self.model_name == 'projectile':
            v0, ang, g, k = self.params['v0'], np.radians(self.params['angle']), self.params['g'], self.params['k']
            def proj(y, t, g, k):
                vx, vy = y[2], y[3]; v = np.sqrt(vx**2 + vy**2)
                return [vx, vy, -k*v*vx, -g - k*v*vy]
            self.sol = odeint(proj, [0, 0, v0*np.cos(ang), v0*np.sin(ang)], self.t, args=(g, k))
            self.ax.plot(self.sol[:, 0], self.sol[:, 1], color=global_config.secondary_color, linestyle='--'); self.ax.set_title("Trajectory")
        elif self.model_name == 'van_der_pol':
            mu = self.params['mu']
            self.sol = odeint(lambda y, t, mu: [y[1], mu*(1 - y[0]**2)*y[1] - y[0]], [2.0, 0.0], self.t, args=(mu,))
            self.ax.plot(self.sol[:, 0], self.sol[:, 1], color=global_config.tertiary_color); self.ax.set_title("Phase Portrait")
        elif self.model_name == 'spring_mass':
            m, k, c, x0 = self.params['m'], self.params['k'], self.params['c'], self.params['x0']
            self.sol = odeint(lambda y, t, m, k, c: [y[1], (-c*y[1] - k*y[0])/m], [x0, 0.0], self.t, args=(m, k, c))
            self.ax.plot(self.t, self.sol[:, 0], color=global_config.primary_color); self.ax.set_title("Displacement vs Time")
        elif self.model_name == 'optimization':
            lr = self.params['lr']; x, y = self.params['start_x'], self.params['start_y']; history = []
            def func(x, y): return x**2 + y**2 + 2*np.sin(2*x)*np.cos(2*y)
            def grad(x, y): 
                dx = 2*x + 4*np.cos(2*x)*np.cos(2*y); dy = 2*y - 4*np.sin(2*x)*np.sin(2*y)
                return np.array([dx, dy])
            for _ in range(num_pts):
                history.append([x, y, func(x, y)]); g = grad(x, y); x -= lr*g[0]; y -= lr*g[1]
            self.sol = np.array(history)
        elif self.model_name == 'wave':
            L, n, c = self.params['L'], self.params['n'], self.params['c']; x = np.linspace(0, L, n); dx = x[1]-x[0]; dt = self.t[1]-self.t[0]
            u = np.exp(-5*(x-L/2)**2); u_prev = u.copy(); history = [u.copy()]
            for _ in range(1, num_pts):
                u_next = np.zeros(n); u_next[1:-1] = 2*u[1:-1] - u_prev[1:-1] + (c*dt/dx)**2 * (u[2:] - 2*u[1:-1] + u[:-2])
                u_prev, u = u.copy(), u_next.copy(); history.append(u.copy())
            self.sol = np.array(history)
        
        if self.sol is not None:
            self.time_slider.setRange(0, len(self.sol) - 1)
            self.time_slider.setValue(0)
            self.time_label.setText(f"Time: {self.t[0]:.2f}s")
            
        global_config.apply_to_axes(self.ax, is_3d=(self.model_name in ['lorenz', 'nbody', 'optimization']))
        self.canvas.draw()

class RegressionSimulator(BaseSimulator):
    def __init__(self, model, **kwargs):
        self.model = model
        self.X, self.y = kwargs.get('X', None), kwargs.get('y', None)
        self.degree = kwargs.get('degree', 1)
        super().__init__(**kwargs)
        self.initUI()
        
    def initUI(self):
        self.setWindowTitle('UniLab Regression Simulator')
        self.setGeometry(150, 150, 1100, 800)
        
        self.fig = Figure(figsize=(8, 6)); self.ax = self.fig.add_subplot(111)
        self.canvas = FigureCanvas(self.fig); self.plot_layout.addWidget(self.canvas)
        
        ctrl_group = QGroupBox("Fitting Controls"); ctrl_layout = QFormLayout()
        
        self.deg_spin = QSpinBox(); self.deg_spin.setRange(1, 15); self.deg_spin.setValue(self.degree)
        self.deg_spin.valueChanged.connect(self.update_fitting)
        ctrl_layout.addRow("Polynomial Degree:", self.deg_spin)
        
        self.noise_slider = QSlider(Qt.Horizontal); self.noise_slider.setRange(0, 100); self.noise_slider.setValue(20)
        self.noise_slider.valueChanged.connect(self.update_fitting)
        ctrl_layout.addRow("Noise Level:", self.noise_slider)
        
        self.reg_type = QComboBox(); self.reg_type.addItems(["Linear", "Ridge", "Lasso"])
        self.reg_type.currentTextChanged.connect(self.update_fitting)
        ctrl_layout.addRow("Regularization:", self.reg_type)
        
        ctrl_group.setLayout(ctrl_layout); self.controls_layout.insertWidget(0, ctrl_group)
        
        self.update_fitting()

    def update_fitting(self):
        self.ax.clear()
        degree = self.deg_spin.value()
        noise = self.noise_slider.value() / 100.0
        
        # Generate synthetic data if not provided
        if self.X is None:
            x_data = np.linspace(-3, 3, 50)
            y_data = 0.5 * x_data**3 - x_data**2 + x_data + np.random.normal(0, noise*5, size=x_data.shape)
        else:
            x_data, y_data = self.X.flatten(), self.y.flatten()
            
        self.ax.scatter(x_data, y_data, color=global_config.primary_color, alpha=0.6, s=global_config.marker_size*10, label='Data Points')
        
        # Fit polynomial
        try:
            poly = np.polyfit(x_data, y_data, degree)
            p = np.poly1d(poly)
            xp = np.linspace(min(x_data)-0.5, max(x_data)+0.5, 200)
            self.ax.plot(xp, p(xp), color=global_config.secondary_color, lw=global_config.line_width, label=f'Poly Fit (deg={degree})')
            
            # Show residuals
            y_pred = p(x_data)
            mse = np.mean((y_data - y_pred)**2)
            self.ax.set_title(f"Polynomial Regression (MSE: {mse:.4f})")
        except:
            self.ax.set_title("Regression Error")
            
        self.ax.legend()
        global_config.apply_to_axes(self.ax)
        self.canvas.draw()

class PCASimulator(BaseSimulator):
    def __init__(self, X, **kwargs):
        if X is None:
            # Generate synthetic 3D data that mostly lies on a plane
            t = np.linspace(0, 10, 50)
            x = t + np.random.normal(0, 0.5, 50)
            y = 0.5 * t + np.random.normal(0, 0.5, 50)
            z = 0.2 * t + np.random.normal(0, 0.5, 50)
            self.X = np.c_[x, y, z]
        else:
            self.X = np.asarray(X)
        super().__init__(**kwargs)
        self.initUI()
        
    def initUI(self):
        self.setWindowTitle('UniLab PCA Visualizer')
        self.setGeometry(150, 150, 1200, 850)
        
        self.tabs = QTabWidget()
        self.p3d_tab = QWidget(); p3_lay = QVBoxLayout(self.p3d_tab)
        self.fig3 = Figure(); self.ax3 = self.fig3.add_subplot(111, projection='3d')
        self.can3 = FigureCanvas(self.fig3); p3_lay.addWidget(self.can3); self.tabs.addTab(self.p3d_tab, "Original 3D")
        
        self.p2d_tab = QWidget(); p2_lay = QVBoxLayout(self.p2d_tab)
        self.fig2 = Figure(); self.ax2 = self.fig2.add_subplot(111)
        self.can2 = FigureCanvas(self.fig2); p2_lay.addWidget(self.can2); self.tabs.addTab(self.p2d_tab, "PCA 2D")
        
        self.plot_layout.addWidget(self.tabs)
        self.update_pca()

    def update_pca(self):
        X = self.X
        if X.shape[1] < 3: # Mock 3D if 2D
            X = np.c_[X, X[:,0]*0.2 + X[:,1]*0.5 + np.random.normal(0, 0.1, len(X))]
            
        # Standardize
        X_std = (X - X.mean(axis=0)) / X.std(axis=0)
        
        # Covariance matrix
        cov_mat = np.cov(X_std.T)
        eig_vals, eig_vecs = np.linalg.eig(cov_mat)
        
        # Sort eigenvectors by eigenvalues
        idx = eig_vals.argsort()[::-1]
        eig_vecs = eig_vecs[:, idx]
        
        # Project
        X_pca = X_std.dot(eig_vecs[:, :2])
        
        # Plot 3D
        self.ax3.clear()
        self.ax3.scatter(X_std[:,0], X_std[:,1], X_std[:,2], color=global_config.primary_color, s=20)
        # Plot Principal Components as arrows
        for i in range(3):
            v = eig_vecs[:, i] * eig_vals[i] * 2
            self.ax3.quiver(0,0,0, v[0], v[1], v[2], color=['red', 'green', 'blue'][i], lw=3, label=f'PC{i+1}')
        self.ax3.set_title("Original Data & Principal Components")
        global_config.apply_to_axes(self.ax3, is_3d=True)
        self.can3.draw()
        
        # Plot 2D
        self.ax2.clear()
        self.ax2.scatter(X_pca[:, 0], X_pca[:, 1], color=global_config.secondary_color, s=30)
        self.ax2.set_xlabel("Principal Component 1")
        self.ax2.set_ylabel("Principal Component 2")
        self.ax2.set_title("Data Projected onto Top 2 PCs")
        global_config.apply_to_axes(self.ax2)
        self.can2.draw()

class SVMSimulator(BaseSimulator):
    def __init__(self, **kwargs):
        self.X = np.array([[1, 2], [2, 3], [3, 3], [2, 1], [3, 2], [1, 1]])
        self.y = np.array([1, 1, 1, 0, 0, 0])
        self.C = 1.0
        super().__init__(**kwargs)
        self.initUI()
        
    def initUI(self):
        self.setWindowTitle('UniLab SVM Margin Visualizer')
        self.setGeometry(100, 100, 1100, 800)
        
        self.fig = Figure(); self.ax = self.fig.add_subplot(111)
        self.canvas = FigureCanvas(self.fig); self.plot_layout.addWidget(self.canvas)
        
        self.c_slider = self.add_custom_slider("C (Regularization)", 0.01, 10.0, self.C, self.update_c, layout=self.controls_layout)
        self.controls_layout.insertWidget(0, QLabel("SVM Hyperparameters:"))
        
        self.update_plot()
        
    def update_c(self, val):
        self.C = val; self.update_plot()
        
    def update_plot(self):
        self.ax.clear()
        from backend.stdlib.packages.ml import SVM
        model = SVM(epochs=2000, lambda_param=1.0/self.C)
        model.fit(self.X, self.y)
        
        # Decision Boundary
        x_min, x_max = self.X[:, 0].min() - 1, self.X[:, 0].max() + 1
        y_min, y_max = self.X[:, 1].min() - 1, self.X[:, 1].max() + 1
        xx, yy = np.meshgrid(np.linspace(x_min, x_max, 100), np.linspace(y_min, y_max, 100))
        Z = model.predict(np.c_[xx.ravel(), yy.ravel()])
        Z = Z.reshape(xx.shape)
        
        self.ax.contourf(xx, yy, Z, alpha=0.3, cmap='coolwarm')
        self.ax.scatter(self.X[:, 0], self.X[:, 1], c=self.y, cmap='coolwarm', edgecolors='k', s=global_config.marker_size*15)
        
        # Plot margin lines
        if model.w is not None:
            w = model.w; b = model.b
            # w0*x + w1*y - b = 0  => y = (-w0*x + b) / w1
            if abs(w[1]) > 1e-5:
                x_pts = np.array([x_min, x_max])
                y_pts = (-w[0] * x_pts + b) / w[1]
                self.ax.plot(x_pts, y_pts, 'k-', lw=2, label='Boundary')
                
                y_up = (-w[0] * x_pts + b + 1) / w[1]
                self.ax.plot(x_pts, y_up, 'k--', alpha=0.5, label='Margin')
                
                y_down = (-w[0] * x_pts + b - 1) / w[1]
                self.ax.plot(x_pts, y_down, 'k--', alpha=0.5)
        
        self.ax.set_title(f"SVM Maximum Margin (C={self.C:.2f})")
        global_config.apply_to_axes(self.ax)
        self.canvas.draw()

class KNNSimulator(BaseSimulator):
    def __init__(self, **kwargs):
        self.X = np.random.rand(40, 2) * 10
        self.y = (self.X[:, 0] + self.X[:, 1] > 10).astype(int)
        self.k = 3
        self.query_pt = np.array([5.0, 5.0])
        super().__init__(**kwargs)
        self.initUI()
        
    def initUI(self):
        self.setWindowTitle('UniLab KNN Neighborhood Visualizer')
        self.setGeometry(100, 100, 1100, 800)
        
        self.fig = Figure(); self.ax = self.fig.add_subplot(111)
        self.canvas = FigureCanvas(self.fig); self.plot_layout.addWidget(self.canvas)
        
        self.k_spin = QSpinBox(); self.k_spin.setRange(1, 20); self.k_spin.setValue(self.k)
        self.k_spin.valueChanged.connect(self.update_k); self.controls_layout.addWidget(QLabel("K Neighbors:")); self.controls_layout.addWidget(self.k_spin)
        
        self.qx_sl = self.add_custom_slider("Query X", 0, 10, 5, self.update_qx, layout=self.controls_layout)
        self.qy_sl = self.add_custom_slider("Query Y", 0, 10, 5, self.update_qy, layout=self.controls_layout)
        
        self.update_plot()
        
    def update_k(self, v): self.k = v; self.update_plot()
    def update_qx(self, v): self.query_pt[0] = v; self.update_plot()
    def update_qy(self, v): self.query_pt[1] = v; self.update_plot()
    
    def update_plot(self):
        self.ax.clear()
        self.ax.scatter(self.X[:, 0], self.X[:, 1], c=self.y, cmap='coolwarm', alpha=0.6)
        
        # Calculate distances
        dists = np.linalg.norm(self.X - self.query_pt, axis=1)
        nn_idx = dists.argsort()[:self.k]
        
        # Highlight neighbors
        for idx in nn_idx:
            self.ax.plot([self.query_pt[0], self.X[idx, 0]], [self.query_pt[1], self.X[idx, 1]], 'k--', alpha=0.3)
            self.ax.scatter(self.X[idx, 0], self.X[idx, 1], edgecolors='yellow', s=100, facecolors='none', lw=2)
            
        self.ax.scatter(self.query_pt[0], self.query_pt[1], color='yellow', marker='*', s=200, label='Query Point', edgecolors='black')
        
        res = Counter(self.y[nn_idx]).most_common(1)[0][0]
        self.ax.set_title(f"KNN Classification (K={self.k}, Result={'Red' if res==1 else 'Blue'})")
        global_config.apply_to_axes(self.ax)
        self.canvas.draw()

class TreeSimulator(BaseSimulator):
    def __init__(self, **kwargs):
        self.X = np.random.rand(100, 2) * 10
        self.y = ((self.X[:, 0] > 5) & (self.X[:, 1] > 5) | (self.X[:, 0] < 3)).astype(int)
        self.depth = 1
        super().__init__(**kwargs)
        self.initUI()
        
    def initUI(self):
        self.setWindowTitle('UniLab Decision Tree Split Visualizer')
        self.setGeometry(100, 100, 1100, 800)
        self.fig = Figure(); self.ax = self.fig.add_subplot(111)
        self.canvas = FigureCanvas(self.fig); self.plot_layout.addWidget(self.canvas)
        self.d_spin = QSpinBox(); self.d_spin.setRange(1, 10); self.d_spin.setValue(self.depth)
        self.d_spin.valueChanged.connect(self.update_depth); self.controls_layout.addWidget(QLabel("Tree Depth:")); self.controls_layout.addWidget(self.d_spin)
        
        self.update_plot()
        
    def update_depth(self, v): self.depth = v; self.update_plot()
    def update_plot(self):
        self.ax.clear()
        from backend.stdlib.packages.ml import DecisionTree
        model = DecisionTree(max_depth=self.depth)
        model.fit(self.X, self.y)
        
        xx, yy = np.meshgrid(np.linspace(0, 10, 100), np.linspace(0, 10, 100))
        Z = model.predict(np.c_[xx.ravel(), yy.ravel()]).reshape(xx.shape)
        
        self.ax.contourf(xx, yy, Z, alpha=0.3, cmap='viridis')
        self.ax.scatter(self.X[:, 0], self.X[:, 1], c=self.y, cmap='viridis', edgecolors='k')
        self.ax.set_title(f"Decision Tree Boundaries (Depth {self.depth})")
        global_config.apply_to_axes(self.ax)
        self.canvas.draw()

class DBSCANSimulator(BaseSimulator):
    def __init__(self, **kwargs):
        self.X = np.random.rand(100, 2) * 10
        # Create some clusters
        self.X[:30] += [2, 2]; self.X[30:60] += [6, 6]
        self.eps = 1.0
        self.min_samples = 5
        super().__init__(**kwargs)
        self.initUI()
        
    def initUI(self):
        self.setWindowTitle('UniLab DBSCAN Density Visualizer')
        self.setGeometry(100, 100, 1100, 800)
        self.fig = Figure(); self.ax = self.fig.add_subplot(111)
        self.canvas = FigureCanvas(self.fig); self.plot_layout.addWidget(self.canvas)
        
        self.eps_sl = self.add_custom_slider("Epsilon (Radius)", 0.1, 5.0, self.eps, self.update_eps, layout=self.controls_layout)
        self.min_spin = QSpinBox(); self.min_spin.setRange(2, 20); self.min_spin.setValue(self.min_samples)
        self.min_spin.valueChanged.connect(self.update_min); self.controls_layout.addWidget(QLabel("Min Samples:")); self.controls_layout.addWidget(self.min_spin)
        
        self.update_plot()
        
    def update_eps(self, v): self.eps = v; self.update_plot()
    def update_min(self, v): self.min_samples = v; self.update_plot()
    
    def update_plot(self):
        self.ax.clear()
        from sklearn.cluster import DBSCAN # Fallback to sklearn if not in our ml package
        try:
            model = DBSCAN(eps=self.eps, min_samples=self.min_samples)
            labels = model.fit_predict(self.X)
        except:
            # Simple manual implementation if sklearn missing
            labels = np.zeros(len(self.X)) - 1 # Mock
            
        unique_labels = set(labels)
        colors = plt.cm.get_cmap('Spectral')(np.linspace(0, 1, len(unique_labels)))
        
        for k, col in zip(unique_labels, colors):
            if k == -1: col = [0, 0, 0, 1] # Noise
            class_member_mask = (labels == k)
            xy = self.X[class_member_mask]
            self.ax.scatter(xy[:, 0], xy[:, 1], color=tuple(col), edgecolor='k', s=global_config.marker_size*10)
            
            # Draw epsilon circles for some points to visualize density
            if k != -1 and len(xy) > 0:
                for pt in xy[:3]: # Only draw few to avoid clutter
                    circle = matplotlib.patches.Circle(pt, self.eps, color=tuple(col), alpha=0.1)
                    self.ax.add_patch(circle)
                    
        self.ax.set_title(f"DBSCAN (Eps={self.eps:.2f}, MinPts={self.min_samples})")
        global_config.apply_to_axes(self.ax)
        self.canvas.draw()

class OptimizerSimulator(BaseSimulator):
    def __init__(self, **kwargs):
        self.lr = 0.05
        super().__init__(**kwargs)
        self.initUI()
        
    def initUI(self):
        self.setWindowTitle('UniLab Optimizer Race')
        self.setGeometry(100, 100, 1100, 800)
        self.fig = Figure(); self.ax = self.fig.add_subplot(111, projection='3d')
        self.canvas = FigureCanvas(self.fig); self.plot_layout.addWidget(self.canvas)
        
        self.run_btn = QPushButton("Run Race"); self.run_btn.clicked.connect(self.run_race)
        self.controls_layout.addWidget(self.run_btn)
        
        self.lr_sl = self.add_custom_slider("Learning Rate", 0.001, 0.5, self.lr, lambda v: setattr(self, 'lr', v), layout=self.controls_layout)
        
        self.draw_surface()
        
    def draw_surface(self):
        self.ax.clear()
        X, Y = np.meshgrid(np.linspace(-3, 3, 50), np.linspace(-3, 3, 50))
        # Beale's function or similar complex surface
        Z = (1.5 - X + X*Y)**2 + (2.25 - X + X*Y**2)**2 + (2.625 - X + X*Y**3)**2
        self.ax.plot_surface(X, Y, np.log1p(Z), cmap='terrain', alpha=0.3)
        global_config.apply_to_axes(self.ax, is_3d=True)
        self.canvas.draw()
        
    def run_race(self):
        # Implementation of SGD, Momentum, Adam trajectories
        def func(x, y): return (1.5 - x + x*y)**2 + (2.25 - x + x*y**2)**2 + (2.625 - x + x*y**3)**2
        def grad(x, y):
            eps = 1e-6
            dx = (func(x+eps, y) - func(x-eps, y)) / (2*eps)
            dy = (func(x, y+eps) - func(x, y-eps)) / (2*eps)
            return np.array([dx, dy])
            
        start_pt = np.array([2.5, 0.5])
        
        # SGD
        sgd_path = [np.append(start_pt, func(*start_pt))]
        curr = start_pt.copy()
        for _ in range(50):
            g = grad(*curr); curr -= self.lr * g
            sgd_path.append(np.append(curr, func(*curr)))
            
        # Adam
        adam_path = [np.append(start_pt, func(*start_pt))]
        curr = start_pt.copy(); m, v = np.zeros(2), np.zeros(2); b1, b2 = 0.9, 0.999
        for t in range(1, 51):
            g = grad(*curr)
            m = b1*m + (1-b1)*g; v = b2*v + (1-b2)*(g**2)
            mh = m/(1-b1**t); vh = v/(1-b2**t)
            curr -= self.lr * mh / (np.sqrt(vh) + 1e-8)
            adam_path.append(np.append(curr, func(*curr)))
            
        self.draw_surface()
        p_sgd = np.array(sgd_path); p_adam = np.array(adam_path)
        self.ax.plot(p_sgd[:,0], p_sgd[:,1], np.log1p(p_sgd[:,2]), color='red', label='SGD', lw=2)
        self.ax.plot(p_adam[:,0], p_adam[:,1], np.log1p(p_adam[:,2]), color='cyan', label='Adam', lw=2)
        self.ax.legend()
        self.canvas.draw()

class AlgorithmSimulator(BaseSimulator):
    def __init__(self, step_func, draw_func, initial_state, **kwargs):
        self.step_f, self.draw_f, self.state = step_func, draw_func, initial_state
        super().__init__(**kwargs)
        self.params.update(kwargs)
        self.timer = QTimer(self); self.timer.timeout.connect(self.step_algo); self.delay = 100; self.initUI()
    def initUI(self):
        self.setWindowTitle('UniLab Algorithm Simulator'); self.setGeometry(100, 100, 1100, 800)
        self.fig = Figure(figsize=(7, 6)); self.ax = self.fig.add_subplot(111); self.canvas = FigureCanvas(self.fig); self.plot_layout.addWidget(self.canvas)
        self.run_btn = QPushButton("Start"); self.run_btn.clicked.connect(self.toggle); self.controls_layout.addWidget(self.run_btn)
        self.step_btn = QPushButton("Step"); self.step_btn.clicked.connect(self.step_algo); self.controls_layout.addWidget(self.step_btn)
        self.controls_layout.addWidget(QLabel("Speed:")); self.speed_sl = QSlider(Qt.Horizontal); self.speed_sl.setRange(1, 1000); self.speed_sl.setValue(100); self.speed_sl.valueChanged.connect(lambda v: setattr(self, 'delay', v)); self.controls_layout.addWidget(self.speed_sl)
        self.draw_algo()
    def toggle(self):
        if self.timer.isActive(): self.timer.stop(); self.run_btn.setText("Resume")
        else: self.timer.start(self.delay); self.run_btn.setText("Pause")
    def step_algo(self):
        try: self.state = self.step_f(self.state, self.params); self.draw_algo()
        except Exception as e: self.timer.stop(); print(f"Algo Error: {e}")
    def draw_algo(self): self.ax.clear(); self.draw_f(self.ax, self.state); global_config.apply_to_axes(self.ax); self.canvas.draw()

_current_sim_window = None

class SimulatorEngine:
    @staticmethod
    def simulate(model, **kwargs):
        global _current_sim_window
        is_bridge = os.environ.get('UNILAB_BRIDGE_MODE') == '1'
        
        if is_bridge:
            if model == 'algorithm':
                step_f = kwargs.pop('step', None)
                draw_f = kwargs.pop('draw', None)
                state = kwargs.pop('state', None)
                sw = BridgeAlgorithmSimulator(step_f, draw_f, state, **kwargs)
                _current_sim_window = sw
                for c in kwargs.get('controls', []):
                    if c.get('type') == 'button': sw.add_custom_button(c['label'], c['callback'])
                    elif c.get('type') == 'slider': sw.add_custom_slider(c['label'], c['min'], c['max'], c['value'], c['callback'])
                # Run in background thread so execute() returns and bridge stays responsive
                threading.Thread(target=sw.run, daemon=True).start()
                return
            else:
                print(f"[ Simulation model '{model}' not yet implemented for bridge mode ]")
                return

        try:
            # Fix sys.argv to avoid Qt crashes on some Linux distros
            original_argv = sys.argv
            sys.argv = [sys.argv[0]]
            
            app = QApplication.instance() or QApplication(sys.argv)
            app.setAttribute(Qt.AA_DontUseNativeMenuBar)
            app.setQuitOnLastWindowClosed(False)
            
            ThemeManager.apply_current_theme(app)
            if model == 'algorithm':
                sw = AlgorithmSimulator(kwargs.get('step'), kwargs.get('draw'), kwargs.get('state'), **kwargs)
            elif model == 'pca': 
                X_data = kwargs.pop('X', None)
                sw = PCASimulator(X_data, **kwargs)
            elif model == 'kmeans':
                if ml:
                    k_val = kwargs.get('k', 3)
                    kmeans_model = ml.KMeans(k=k_val)
                    sw = KMeansSimulator(kmeans_model, **kwargs)
                else:
                    raise ImportError("ML package not available for KMeans simulation")
            elif model == 'regression': sw = RegressionSimulator(kwargs.get('model'), **kwargs)
            elif model == 'svm': sw = SVMSimulator(**kwargs)
            elif model == 'knn': sw = KNNSimulator(**kwargs)
            elif model == 'tree': sw = TreeSimulator(**kwargs)
            elif model == 'dbscan': sw = DBSCANSimulator(**kwargs)
            elif model == 'optimizer': sw = OptimizerSimulator(**kwargs)
            elif callable(model): sw = MathSimulator(model, **kwargs)
            elif isinstance(model, (signal.TransferFunction, signal.StateSpace)): sw = ControlSimulator(model, **kwargs)
            elif type(model).__name__ in ['NeuralNet', 'LogisticRegression', 'SVM', 'RandomForest', 'GradientBoosting']: sw = MLSimulator(model, **kwargs)
            elif type(model).__name__ in ['KMeans', 'GMM', 'DBSCAN']: sw = KMeansSimulator(model, **kwargs)
            elif isinstance(model, str): sw = PhysicsSimulator(model, **kwargs)
            else: raise TypeError(f"Sim not supported for {type(model)}")
            
            if sw:
                _current_sim_window = sw
                
                for c in kwargs.get('controls', []):
                    l = getattr(sw, 'subclass_controls_layout', getattr(sw, 'controls_layout', None))
                    if c.get('type') == 'button': sw.add_custom_button(c['label'], c['callback'], layout=l)
                    elif c.get('type') == 'slider': sw.add_custom_slider(c['label'], c['min'], c['max'], c['value'], c['callback'], layout=l)
                
                on_init = kwargs.get('on_init')
                if on_init and callable(on_init):
                    try:
                        on_init()
                    except Exception as e:
                        print(f"Init Error: {e}")
                        import traceback
                        traceback.print_exc()
                
                sw.show()
                if not hasattr(app, '_sws'): app._sws = []
                app._sws.append(sw)
                
                # Use a more stable wait approach with QEventLoop
                loop = QEventLoop()
                
                # Monitor window closure/destruction
                def exit_check():
                    try:
                        if sw.isHidden():
                            loop.quit()
                    except:
                        loop.quit()
                
                timer = QTimer(sw)
                timer.timeout.connect(exit_check)
                timer.start(100)
                
                sw.destroyed.connect(loop.quit)
                loop.exec_()
                
                if sw in app._sws:
                    app._sws.remove(sw)
                if _current_sim_window == sw: _current_sim_window = None
            sys.argv = original_argv
        except Exception as e: print(f"Sim Error: {e}"); import traceback; traceback.print_exc()

def unilab_simulate(model, *args):
    is_bridge = os.environ.get('UNILAB_BRIDGE_MODE') == '1'
    if (os.environ.get('UNILAB_WEB_MODE') == '1' or IS_HEADLESS) and not is_bridge:

        msg = "[ Interactive simulation window skipped in web mode ]" if os.environ.get('UNILAB_WEB_MODE') == '1' else "[ Interactive simulation window skipped in headless mode ]"
        print(f"\n\x1b[38;2;253;253;150m{msg}\x1b[0m")
        return

    kwargs = {}
    if len(args) % 2 == 0:
        for i in range(0, len(args), 2):
            if isinstance(args[i], str): kwargs[args[i]] = args[i+1]
            
    from backend.core.runtime import unilab_event_ctx
    kwargs['on_event'] = unilab_event_ctx.get()
    
    SimulatorEngine.simulate(model, **kwargs)