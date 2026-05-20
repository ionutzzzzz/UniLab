import sys
import numpy as np
from scipy import signal
import os

# Fix for Qt stability on some Linux distros
os.environ['GTK_MODULES'] = ''
os.environ['QT_QPA_PLATFORMTHEME'] = ''
os.environ['QT_STYLE_OVERRIDE'] = 'Fusion'

try:
    import matplotlib    # Try to be more flexible with the backend
    if 'matplotlib.backends' not in sys.modules:
        try:
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
                             QCheckBox, QLineEdit)
from PyQt5.QtCore import Qt, QTimer, QThread, pyqtSignal, QEventLoop
from PyQt5.QtGui import QPalette, QColor

# Try importing ML package
try:
    from backend.packages import ml
except ImportError:
    ml = None

class ThemeManager:
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
    def __init__(self):
        super().__init__()
        self.custom_controls = {}
        self.init_menu()
        
    def init_menu(self):
        menubar = self.menuBar()
        settings_menu = menubar.addMenu('Settings')
        theme_menu = settings_menu.addMenu('Theme')
        dark_action = QAction('Dark Mode', self)
        dark_action.triggered.connect(self.set_dark_theme)
        theme_menu.addAction(dark_action)
        light_action = QAction('Light Mode', self)
        light_action.triggered.connect(self.set_light_theme)
        theme_menu.addAction(light_action)
        
    def set_dark_theme(self):
        ThemeManager.apply_dark_theme(QApplication.instance())
        self.refresh_plot()
        
    def set_light_theme(self):
        ThemeManager.apply_light_theme(QApplication.instance())
        self.refresh_plot()
        
    def add_custom_button(self, label, callback, layout=None):
        btn = QPushButton(label)
        btn.clicked.connect(callback)
        if layout: layout.addWidget(btn)
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
        if layout: layout.addWidget(container)
        self.custom_controls[label] = slider
        return slider
        
    def add_custom_checkbox(self, label, initial_state, callback, layout=None):
        cb = QCheckBox(label)
        cb.setChecked(initial_state)
        cb.stateChanged.connect(lambda state: callback(state == Qt.Checked))
        if layout: layout.addWidget(cb)
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
        if layout: layout.addWidget(container)
        self.custom_controls[label] = combo
        return combo
        
    def add_custom_input(self, label, initial_text, callback, layout=None):
        container = QWidget()
        l = QVBoxLayout(container)
        l.addWidget(QLabel(label))
        edit = QLineEdit()
        edit.setText(str(initial_text))
        edit.textChanged.connect(callback)
        l.addWidget(edit)
        if layout: layout.addWidget(container)
        self.custom_controls[label] = edit
        return edit
        
    def add_custom_label(self, label_id, initial_text, layout=None):
        lbl = QLabel(str(initial_text))
        if layout: layout.addWidget(lbl)
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
        super().__init__()
        self.func = func
        self.params = kwargs.get('params', {})
        self.t_range = kwargs.get('t_range', [0, 10])
        self.y_range = kwargs.get('y_range', None)
        self.is_ode = kwargs.get('is_ode', False)
        self.y0 = kwargs.get('y0', [1.0])
        self.initUI()
        
    def initUI(self):
        self.setWindowTitle('UniLab General Math Simulator')
        self.setGeometry(100, 100, 900, 700)
        main_widget = QWidget(); self.setCentralWidget(main_widget)
        main_layout = QHBoxLayout(main_widget)
        plot_container = QWidget(); plot_layout = QVBoxLayout(plot_container)
        self.figure = Figure(figsize=(7, 5)); self.ax = None # Will be created in update
        self.canvas = FigureCanvas(self.figure); plot_layout.addWidget(self.canvas)
        main_layout.addWidget(plot_container, stretch=3)
        
        self.right_panel = QWidget(); self.controls_layout = QVBoxLayout(self.right_panel)
        self.custom_layout = QVBoxLayout(); self.controls_layout.addLayout(self.custom_layout)
        self.controls_layout.addStretch(); main_layout.addWidget(self.right_panel, stretch=1)
        self.update_simulation()
    
    def update_simulation(self):
        self.figure.clear()
        t_bounds = np.asarray(self.t_range).flatten()
        t = np.linspace(t_bounds[0], t_bounds[1], 500) if len(t_bounds) >= 2 else np.linspace(0, 10, 500)
        try:
            if self.is_ode:
                self.ax = self.figure.add_subplot(111)
                from scipy.integrate import odeint
                y0 = np.asarray(self.y0).flatten()
                sol = odeint(self.func, y0, t, args=(self.params,))
                for i in range(sol.shape[1]): self.ax.plot(t, sol[:, i], label=f'y[{i}]')
            else:
                # Check if func is 1D or 2D (heuristic)
                try:
                    res = self.func(t[0], self.params)
                except: res = 0
                
                if isinstance(res, np.ndarray) and res.ndim >= 2:
                    self.ax = self.figure.add_subplot(111, projection='3d')
                    X, Y = np.meshgrid(t, t)
                    Z = self.func(X, Y, self.params)
                    self.ax.plot_surface(X, Y, Z, cmap='viridis')
                else:
                    self.ax = self.figure.add_subplot(111)
                    y = self.func(t, self.params)
                    if isinstance(y, (list, tuple)) or (isinstance(y, np.ndarray) and y.ndim > 1):
                        for i, yi in enumerate(y): self.ax.plot(t, yi, label=f'f_{i}(t)')
                    else: self.ax.plot(t, y, 'b-', label='f(t)')
            
            self.ax.set_title("Function Response"); self.ax.set_xlabel("Time / X"); self.ax.set_ylabel("Amplitude")
            self.ax.grid(True); self.ax.legend()
        except Exception as e:
            if not self.ax: self.ax = self.figure.add_subplot(111)
            self.ax.text(0.5, 0.5, f"Error: {e}", transform=self.ax.transAxes)
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
        except Exception as e: sys.stderr.write(f"ML Training Error: {e}\n")
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
        super().__init__(); self.model = model; self.X = kwargs.get('X', None)
        self.training_thread = None; self.initUI()
    def initUI(self):
        self.setWindowTitle('UniLab K-Means Clustering Simulator'); self.setGeometry(150, 150, 950, 750)
        main_widget = QWidget(); self.setCentralWidget(main_widget); main_layout = QHBoxLayout(main_widget)
        plot_container = QWidget(); plot_layout = QVBoxLayout(plot_container)
        self.figure = Figure(figsize=(7, 5)); self.ax = self.figure.add_subplot(111)
        self.canvas = FigureCanvas(self.figure); plot_layout.addWidget(self.canvas)
        main_layout.addWidget(plot_container, stretch=3)
        right_panel = QWidget(); right_layout = QVBoxLayout(right_panel)
        train_group = QGroupBox("Clustering Controls"); train_layout = QVBoxLayout()
        self.status_label = QLabel(f"Status: Ready (K={self.model.k})"); train_layout.addWidget(self.status_label)
        self.start_btn = QPushButton("Start/Resume"); self.start_btn.clicked.connect(self.start_training); train_layout.addWidget(self.start_btn)
        self.pause_btn = QPushButton("Pause"); self.pause_btn.clicked.connect(self.pause_training); self.pause_btn.setEnabled(False); train_layout.addWidget(self.pause_btn)
        self.reset_btn = QPushButton("Stop/Reset"); self.reset_btn.clicked.connect(self.reset_training); train_layout.addWidget(self.reset_btn)
        train_group.setLayout(train_layout); right_layout.addWidget(train_group)
        self.custom_layout = QVBoxLayout(); right_layout.addLayout(self.custom_layout)
        right_layout.addStretch(); main_layout.addWidget(right_panel, stretch=1)
        if self.X is not None and self.X.shape[1] >= 2:
            self.ax.scatter(self.X[:, 0], self.X[:, 1], c='gray', alpha=0.5, s=30)
            self.ax.set_title("Unclustered Data"); self.ax.grid(True)
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
            self.ax.set_title("Unclustered Data"); self.ax.grid(True)
        self.status_label.setText("Status: Reset"); self.canvas.draw()
    def update_plot(self, epoch, centroids, labels):
        self.ax.clear()
        if self.X is not None and self.X.shape[1] >= 2:
            self.ax.scatter(self.X[:, 0], self.X[:, 1], c=labels, cmap='viridis', alpha=0.6, s=30)
            if centroids is not None and centroids.shape[1] >= 2:
                self.ax.scatter(centroids[:, 0], centroids[:, 1], c='red', marker='X', s=200, edgecolors='black', label='Centroids'); self.ax.legend()
            self.ax.set_title(f"K-Means Clustering (Epoch {epoch})"); self.ax.grid(True)
        self.canvas.draw()
    def training_finished(self): self.status_label.setText("Status: Clustering Done"); self.start_btn.setEnabled(True); self.pause_btn.setEnabled(False)

class MLSimulator(BaseSimulator):
    def __init__(self, model, **kwargs):
        super().__init__(); self.model = model; self.X, self.y = kwargs.get('X', None), kwargs.get('y', None)
        self.epochs, self.lr, self.l1, self.l2 = kwargs.get('epochs', 1000), kwargs.get('lr', 0.01), kwargs.get('l1', 0.0), kwargs.get('l2', 0.0)
        self.epochs_history, self.loss_history, self.acc_history, self.current_Z = [], [], [], None
        self.is_classification = False
        if self.y is not None:
            uv = np.unique(self.y)
            if len(uv) < 20 and np.all(np.equal(np.mod(uv, 1), 0)): self.is_classification = True
        self.training_thread = None; self.initUI()
    def initUI(self):
        self.setWindowTitle('UniLab ML Simulator'); self.setGeometry(150, 150, 1100, 800)
        main_widget = QWidget(); self.setCentralWidget(main_widget); main_layout = QHBoxLayout(main_widget)
        self.tabs = QTabWidget(); self.metrics_tab = QWidget(); self.metrics_layout = QVBoxLayout(self.metrics_tab)
        self.metrics_figure = Figure(figsize=(6, 5))
        self.loss_ax = self.metrics_figure.add_subplot(211 if self.is_classification else 111)
        if self.is_classification: self.acc_ax = self.metrics_figure.add_subplot(212)
        self.metrics_canvas = FigureCanvas(self.metrics_figure); self.metrics_layout.addWidget(self.metrics_canvas); self.tabs.addTab(self.metrics_tab, "Metrics")
        self.db_tab = QWidget(); self.db_layout = QVBoxLayout(self.db_tab); self.db_figure = Figure(figsize=(6, 5))
        self.db_ax = self.db_figure.add_subplot(111); self.db_canvas = FigureCanvas(self.db_figure); self.db_layout.addWidget(self.db_canvas); self.tabs.addTab(self.db_tab, "Boundary")
        main_layout.addWidget(self.tabs, stretch=3)
        right_panel = QWidget(); right_layout = QVBoxLayout(right_panel)
        train_group = QGroupBox("Training Controls"); train_layout = QVBoxLayout()
        self.status_label = QLabel(f"Status: Ready ({type(self.model).__name__})"); train_layout.addWidget(self.status_label)
        self.progress_bar = QProgressBar(); self.progress_bar.setMaximum(self.epochs); train_layout.addWidget(self.progress_bar)
        btn_layout = QHBoxLayout(); self.start_btn = QPushButton("Start/Resume"); self.start_btn.clicked.connect(self.start_training); btn_layout.addWidget(self.start_btn)
        self.pause_btn = QPushButton("Pause"); self.pause_btn.clicked.connect(self.pause_training); self.pause_btn.setEnabled(False); train_layout.addWidget(self.pause_btn)
        self.reset_btn = QPushButton("Stop/Reset"); self.reset_btn.clicked.connect(self.reset_training); btn_layout.addWidget(self.reset_btn)
        train_layout.addLayout(btn_layout); train_group.setLayout(train_layout); right_layout.addWidget(train_group)
        hp_group = QGroupBox("Live Tuning"); hp_layout = QFormLayout()
        self.lr_label = QLabel(f"{self.lr:.4f}"); self.lr_slider = QSlider(Qt.Horizontal); self.lr_slider.setRange(1, 1000); self.lr_slider.setValue(int(self.lr * 10000))
        self.lr_slider.valueChanged.connect(self.update_params); hp_layout.addRow("LR:", self.lr_label); hp_layout.addRow(self.lr_slider)
        self.l2_label = QLabel(f"{self.l2:.4f}"); self.l2_slider = QSlider(Qt.Horizontal); self.l2_slider.setRange(0, 500); self.l2_slider.setValue(int(self.l2 * 10000))
        self.l2_slider.valueChanged.connect(self.update_params); hp_layout.addRow("L2:", self.l2_label); hp_layout.addRow(self.l2_slider)
        hp_group.setLayout(hp_layout); right_layout.addWidget(hp_group)
        self.custom_layout = QVBoxLayout(); right_layout.addLayout(self.custom_layout)
        right_layout.addStretch(); main_layout.addWidget(right_panel, stretch=1); self.refresh_plot()
    def update_params(self):
        self.lr = self.lr_slider.value()/10000.0; self.lr_label.setText(f"{self.lr:.4f}")
        self.l2 = self.l2_slider.value()/10000.0; self.l2_label.setText(f"{self.l2:.4f}")
        if self.training_thread: self.training_thread.lr, self.training_thread.l2 = self.lr, self.l2
    def refresh_plot(self):
        self.loss_ax.clear()
        if self.epochs_history:
            self.loss_ax.plot(self.epochs_history, self.loss_history, 'b-'); self.loss_ax.set_title(f'Loss: {self.loss_history[-1]:.4f}')
            if self.is_classification: self.acc_ax.clear(); self.acc_ax.plot(self.epochs_history, self.acc_history, 'g-'); self.acc_ax.set_title(f'Acc: {self.acc_history[-1]:.1f}%'); self.acc_ax.set_ylim(0, 105); self.acc_ax.grid(True)
        self.loss_ax.set_xlabel('Epoch'); self.loss_ax.grid(True); self.metrics_canvas.draw()
        if self.current_Z is not None:
            mx, mz = self.current_Z; self.db_ax.clear(); self.db_ax.contourf(mx[0], mx[1], mz.reshape(mx[0].shape), alpha=0.3, cmap='coolwarm')
            self.db_ax.scatter(self.X[:, 0], self.X[:, 1], c=self.y.flatten(), edgecolor='k', cmap='coolwarm'); self.db_ax.set_title('Boundary'); self.db_ax.grid(True); self.db_canvas.draw()
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
        super().__init__(); self.sys_model = model; self.input_type = kwargs.get('input', 'step')
        self.t_range = kwargs.get('t_range', kwargs.get('time', [0, 10]))
        self.kp, self.ki, self.kd = kwargs.get('kp', 1.0), kwargs.get('ki', 0.0), kwargs.get('kd', 0.0); self.initUI()
    def initUI(self):
        self.setWindowTitle('UniLab Control Simulator'); self.setGeometry(100, 100, 900, 650)
        w = QWidget(); self.setCentralWidget(w); l = QVBoxLayout(w); self.fig = Figure(figsize=(6, 4)); self.ax = self.fig.add_subplot(111)
        self.canvas = FigureCanvas(self.fig); l.addWidget(self.canvas); cl = QHBoxLayout()
        il = QVBoxLayout(); self.input_combo = QComboBox(); self.input_combo.addItems(['step', 'impulse', 'sine', 'square'])
        self.input_combo.setCurrentText(self.input_type); self.input_combo.currentTextChanged.connect(self.update_simulation)
        il.addWidget(QLabel("Input:")); il.addWidget(self.input_combo); cl.addLayout(il)
        pl = QVBoxLayout(); self.kp_lbl = QLabel(f"Kp: {self.kp:.2f}"); self.kp_sl = QSlider(Qt.Horizontal); self.kp_sl.setRange(0, 1000); self.kp_sl.setValue(int(self.kp*100))
        self.kp_sl.valueChanged.connect(self.update_pid); pl.addWidget(self.kp_lbl); pl.addWidget(self.kp_sl)
        self.ki_lbl = QLabel(f"Ki: {self.ki:.2f}"); self.ki_sl = QSlider(Qt.Horizontal); self.ki_sl.setRange(0, 500); self.ki_sl.setValue(int(self.ki*100))
        self.ki_sl.valueChanged.connect(self.update_pid); pl.addWidget(self.ki_lbl); pl.addWidget(self.ki_sl)
        self.kd_lbl = QLabel(f"Kd: {self.kd:.2f}"); self.kd_sl = QSlider(Qt.Horizontal); self.kd_sl.setRange(0, 500); self.kd_sl.setValue(int(self.kd*100))
        self.kd_sl.valueChanged.connect(self.update_pid); pl.addWidget(self.kd_lbl); pl.addWidget(self.kd_sl)
        cl.addLayout(pl); l.addLayout(cl)
        
        self.custom_layout = QVBoxLayout()
        l.addLayout(self.custom_layout)
        
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
        if inp == 'step': u = np.ones_like(t); _, y, _ = signal.lsim(sys_c, u, t); self.ax.plot(t, u, 'g--'); self.ax.plot(t, y, 'b-')
        elif inp == 'impulse': _, y = signal.impulse(sys_c, T=t); self.ax.plot(t, y, 'r-')
        elif inp == 'sine': u = np.sin(2*np.pi*t); _, y, _ = signal.lsim(sys_c, u, t); self.ax.plot(t, u, 'g--'); self.ax.plot(t, y, 'b-')
        elif inp == 'square': u = signal.square(2*np.pi*0.5*t); _, y, _ = signal.lsim(sys_c, u, t); self.ax.plot(t, u, 'g--'); self.ax.plot(t, y, 'b-')
        self.ax.grid(True); self.canvas.draw()

class PhysicsSimulator(BaseSimulator):
    def __init__(self, model, **kwargs):
        super().__init__(); self.model_name, self.params = model, kwargs
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
        self.setWindowTitle(f'UniLab {self.model_name}'); self.setGeometry(100, 100, 1000, 750)
        w = QWidget(); self.setCentralWidget(w); l = QHBoxLayout(w); self.fig = Figure(figsize=(7, 6))
        is_3d = self.model_name in ['lorenz', 'nbody', 'optimization']
        self.ax = self.fig.add_subplot(111, projection='3d') if is_3d else self.fig.add_subplot(111)
        self.canvas = FigureCanvas(self.fig); l.addWidget(self.canvas, stretch=3)
        cp = QWidget(); self.controls_layout = QVBoxLayout(cp); g = QGroupBox("Params"); f = QFormLayout()
        if self.model_name == 'pendulum': self.add_s("Len", 0.1, 5, 'length', f); self.add_s("G", 1, 20, 'g', f)
        elif self.model_name == 'double_pendulum': self.add_s("L1", 0.1, 2, 'l1', f); self.add_s("L2", 0.1, 2, 'l2', f)
        elif self.model_name == 'lorenz': self.add_s("Rho", 0, 50, 'rho', f); self.add_s("Sigma", 0, 30, 'sigma', f)
        elif self.model_name == 'nbody': self.add_s("G", 0.1, 10, 'G', f)
        elif self.model_name == 'projectile': self.add_s("V0", 1, 50, 'v0', f); self.add_s("Angle", 0, 90, 'angle', f); self.add_s("Drag", 0, 1, 'k', f)
        elif self.model_name == 'van_der_pol': self.add_s("Mu", 0, 10, 'mu', f)
        elif self.model_name == 'spring_mass': self.add_s("Mass", 0.1, 10, 'm', f); self.add_s("Stiff", 1, 50, 'k', f); self.add_s("Damp", 0, 5, 'c', f)
        elif self.model_name == 'optimization': self.add_s("LR", 0.01, 1.0, 'lr', f)
        elif self.model_name == 'wave': self.add_s("Speed", 0.1, 5, 'c', f)
        g.setLayout(f); self.controls_layout.addWidget(g)
        
        self.run_btn = QPushButton("Run Animation")
        self.run_btn.clicked.connect(self.toggle_animation)
        self.controls_layout.addWidget(self.run_btn)
        
        # Time Slider and Label
        self.time_label = QLabel("Time: 0.00s")
        self.controls_layout.addWidget(self.time_label)
        self.time_slider = QSlider(Qt.Horizontal)
        self.time_slider.setRange(0, 100)
        self.time_slider.sliderMoved.connect(self.seek_animation)
        self.controls_layout.addWidget(self.time_slider)
        
        self.controls_layout.addStretch(); l.addWidget(cp, stretch=1); self.update_simulation()
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
    def render_frame(self, idx):
        if self.sol is None or idx >= len(self.sol): return
        
        # Update slider and label without triggering seek_animation
        self.time_slider.blockSignals(True)
        self.time_slider.setValue(idx)
        self.time_slider.blockSignals(False)
        self.time_label.setText(f"Time: {self.t[idx]:.2f}s")
        
        self.ax.clear()
        if self.model_name == 'pendulum':
            self.ax.plot([0, np.sin(self.sol[idx, 0])], [0, -np.cos(self.sol[idx, 0])], 'bo-')
            self.ax.set_xlim(-1.2, 1.2); self.ax.set_ylim(-1.2, 1.2); self.ax.set_title(f"Pendulum (t={self.t[idx]:.2f}s)")
        elif self.model_name == 'double_pendulum':
            l1, l2 = self.params['l1'], self.params['l2']
            x1, y1 = l1*np.sin(self.sol[idx, 0]), -l1*np.cos(self.sol[idx, 0])
            x2, y2 = x1 + l2*np.sin(self.sol[idx, 2]), y1 - l2*np.cos(self.sol[idx, 2])
            self.ax.plot([0, x1, x2], [0, y1, y2], 'bo-')
            self.ax.plot(l1*np.sin(self.sol[:idx, 0]) + l2*np.sin(self.sol[:idx, 2]), -l1*np.cos(self.sol[:idx, 0]) - l2*np.cos(self.sol[:idx, 2]), 'r-', alpha=0.3)
            lim = l1 + l2 + 0.2; self.ax.set_xlim(-lim, lim); self.ax.set_ylim(-lim, lim); self.ax.set_title("Double Pendulum")
        elif self.model_name == 'lorenz':
            self.ax.plot(self.sol[:idx, 0], self.sol[:idx, 1], self.sol[:idx, 2], 'm-')
            self.ax.scatter(self.sol[idx, 0], self.sol[idx, 1], self.sol[idx, 2], color='red')
            self.ax.set_title("Lorenz Attractor")
        elif self.model_name == 'nbody':
            p = self.sol[idx].reshape(-1, 6)[:, :3]
            for i in range(3):
                self.ax.plot(self.sol[:idx, i*6], self.sol[:idx, i*6+1], self.sol[:idx, i*6+2], alpha=0.3)
                self.ax.scatter(p[i, 0], p[i, 1], p[i, 2], s=50)
            self.ax.set_title("N-Body Simulation")
        elif self.model_name == 'projectile':
            self.ax.plot(self.sol[:idx, 0], self.sol[:idx, 1], 'r-')
            self.ax.scatter(self.sol[idx, 0], self.sol[idx, 1], s=100, color='blue')
            self.ax.set_xlim(0, max(np.max(self.sol[:, 0]), 10)); self.ax.set_ylim(0, max(np.max(self.sol[:, 1]), 10))
            self.ax.set_title(f"Projectile Motion (v0={self.params['v0']})")
        elif self.model_name == 'van_der_pol':
            self.ax.plot(self.sol[:idx, 0], self.sol[:idx, 1], 'g-')
            self.ax.scatter(self.sol[idx, 0], self.sol[idx, 1], color='red')
            self.ax.set_xlabel("Position (x)"); self.ax.set_ylabel("Velocity (v)")
            self.ax.set_title(f"Van der Pol Oscillator (mu={self.params['mu']})")
        elif self.model_name == 'spring_mass':
            x = self.sol[idx, 0]
            self.ax.plot([-2, 2], [0, 0], 'k-') # Floor
            self.ax.add_patch(matplotlib.patches.Rectangle((x-0.2, 0), 0.4, 0.4, color='orange')) # Mass
            # Spring visualization
            sx = np.linspace(-1.5, x-0.2, 50); sy = 0.2 + 0.1 * np.sin(np.linspace(0, 10*np.pi, 50))
            self.ax.plot(sx, sy, 'k-'); self.ax.plot([-1.5, -1.5], [0, 0.5], 'k-', lw=3) # Wall
            self.ax.set_xlim(-2, 2); self.ax.set_ylim(-0.5, 1.0); self.ax.set_title("Spring-Mass System")
        elif self.model_name == 'optimization':
            X, Y = np.meshgrid(np.linspace(-3, 3, 50), np.linspace(-3, 3, 50))
            Z = X**2 + Y**2 + 2*np.sin(2*X)*np.cos(2*Y)
            self.ax.plot_surface(X, Y, Z, cmap='viridis', alpha=0.4)
            self.ax.plot(self.sol[:idx, 0], self.sol[:idx, 1], self.sol[:idx, 2], 'r-', lw=2)
            self.ax.scatter(self.sol[idx, 0], self.sol[idx, 1], self.sol[idx, 2], color='red', s=50)
            self.ax.set_title("Gradient Descent Optimization")
        elif self.model_name == 'wave':
            x = np.linspace(0, self.params['L'], self.params['n'])
            self.ax.plot(x, self.sol[idx], 'b-', lw=2)
            self.ax.set_ylim(-1.5, 1.5); self.ax.set_xlim(0, self.params['L'])
            self.ax.set_title(f"1D Wave Equation (t={self.t[idx]:.2f}s)")
        
        self.ax.grid(True); self.canvas.draw()
    def update_simulation(self):
        self.ax.clear(); from scipy.integrate import odeint
        tr = np.asarray(self.t_range).flatten()
        num_pts = 1000 if self.model_name != 'lorenz' else 5000
        self.t = np.linspace(tr[0], tr[1], num_pts)
        
        if self.model_name == 'pendulum':
            self.sol = odeint(lambda y, t, g, L, b: [y[1], -b*y[1]-(g/L)*np.sin(y[0])], [self.params['theta0'], 0], self.t, args=(self.params['g'], self.params['length'], self.params['b']))
            self.ax.plot(self.t, self.sol[:, 0]); self.ax.set_title("Pendulum (Static View)")
        elif self.model_name == 'double_pendulum':
            def dp(y, t, m1, m2, l1, l2, g):
                t1, w1, t2, w2 = y; c, s = np.cos(t1-t2), np.sin(t1-t2)
                d1 = (m2*g*np.sin(t2)*c - m2*s*(l1*w1**2*c + l2*w2**2) - (m1+m2)*g*np.sin(t1))/(l1*(m1+m2*s**2))
                d2 = ((m1+m2)*(l1*w1**2*s - g*np.sin(t2) + g*np.sin(t1)*c) + m2*l2*w2**2*s*c)/(l2*(m1+m2*s**2))
                return [w1, d1, w2, d2]
            self.sol = odeint(dp, [self.params['theta1'], 0, self.params['theta2'], 0], self.t, args=(self.params['m1'], self.params['m2'], self.params['l1'], self.params['l2'], 9.81))
            x1 = self.params['l1']*np.sin(self.sol[:, 0]); y1 = -self.params['l1']*np.cos(self.sol[:, 0]); x2 = x1+self.params['l2']*np.sin(self.sol[:, 2]); y2 = y1-self.params['l2']*np.cos(self.sol[:, 2])
            self.ax.plot(x2, y2, 'r-', alpha=0.5); self.ax.plot([0, x1[-1], x2[-1]], [0, y1[-1], y2[-1]], 'bo-'); lim = self.params['l1']+self.params['l2']; self.ax.set_xlim(-lim, lim); self.ax.set_ylim(-lim, lim)
        elif self.model_name == 'lorenz':
            self.sol = odeint(lambda y, t, s, r, b: [s*(y[1]-y[0]), y[0]*(r-y[2])-y[1], y[0]*y[1]-b*y[2]], [1, 1, 1], self.t, args=(self.params['sigma'], self.params['rho'], self.params['beta']))
            self.ax.plot(self.sol[:, 0], self.sol[:, 1], self.sol[:, 2], 'm-')
        elif self.model_name == 'nbody':
            def nb(y, t, G):
                p, v, a = y.reshape(-1, 6)[:, :3], y.reshape(-1, 6)[:, 3:], np.zeros((3, 3))
                for i in range(3):
                    for j in range(3):
                        if i == j: continue
                        r = p[j]-p[i]; a[i] += G*r/(np.linalg.norm(r)**3+0.1)
                return np.hstack([v, a]).flatten()
            self.sol = odeint(nb, [1,0,0, 0,0.5,0, -1,0,0, 0,-0.5,0, 0,1,0, 0.5,0,0], self.t, args=(self.params['G'],))
            for i in range(3): self.ax.plot(self.sol[:, i*6], self.sol[:, i*6+1], self.sol[:, i*6+2])
        elif self.model_name == 'projectile':
            v0, ang, g, k = self.params['v0'], np.radians(self.params['angle']), self.params['g'], self.params['k']
            def proj(y, t, g, k):
                vx, vy = y[2], y[3]; v = np.sqrt(vx**2 + vy**2)
                return [vx, vy, -k*v*vx, -g - k*v*vy]
            self.sol = odeint(proj, [0, 0, v0*np.cos(ang), v0*np.sin(ang)], self.t, args=(g, k))
            self.ax.plot(self.sol[:, 0], self.sol[:, 1], 'r--'); self.ax.set_title("Trajectory")
        elif self.model_name == 'van_der_pol':
            mu = self.params['mu']
            self.sol = odeint(lambda y, t, mu: [y[1], mu*(1 - y[0]**2)*y[1] - y[0]], [2.0, 0.0], self.t, args=(mu,))
            self.ax.plot(self.sol[:, 0], self.sol[:, 1], 'g-'); self.ax.set_title("Phase Portrait")
        elif self.model_name == 'spring_mass':
            m, k, c, x0 = self.params['m'], self.params['k'], self.params['c'], self.params['x0']
            self.sol = odeint(lambda y, t, m, k, c: [y[1], (-c*y[1] - k*y[0])/m], [x0, 0.0], self.t, args=(m, k, c))
            self.ax.plot(self.t, self.sol[:, 0]); self.ax.set_title("Displacement vs Time")
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
            
        self.ax.grid(True); self.canvas.draw()

class AlgorithmSimulator(BaseSimulator):
    def __init__(self, step_func, draw_func, initial_state, **kwargs):
        super().__init__(); self.step_f, self.draw_f, self.state = step_func, draw_func, initial_state
        self.params = kwargs; self.timer = QTimer(self); self.timer.timeout.connect(self.step_algo); self.delay = 100; self.initUI()
    def initUI(self):
        self.setWindowTitle('UniLab Algorithm Simulator'); self.setGeometry(100, 100, 1000, 750)
        w = QWidget(); self.setCentralWidget(w); l = QHBoxLayout(w); self.fig = Figure(figsize=(7, 6)); self.ax = self.fig.add_subplot(111); self.canvas = FigureCanvas(self.fig); l.addWidget(self.canvas, stretch=3)
        cp = QWidget(); self.controls_layout = QVBoxLayout(cp)
        self.run_btn = QPushButton("Start"); self.run_btn.clicked.connect(self.toggle); self.controls_layout.addWidget(self.run_btn)
        self.step_btn = QPushButton("Step"); self.step_btn.clicked.connect(self.step_algo); self.controls_layout.addWidget(self.step_btn)
        self.controls_layout.addWidget(QLabel("Speed:")); self.speed_sl = QSlider(Qt.Horizontal); self.speed_sl.setRange(1, 1000); self.speed_sl.setValue(100); self.speed_sl.valueChanged.connect(lambda v: setattr(self, 'delay', v)); self.controls_layout.addWidget(self.speed_sl)
        self.custom_layout = QVBoxLayout(); self.controls_layout.addLayout(self.custom_layout); self.controls_layout.addStretch(); l.addWidget(cp, stretch=1); self.draw_algo()
    def toggle(self):
        if self.timer.isActive(): self.timer.stop(); self.run_btn.setText("Resume")
        else: self.timer.start(self.delay); self.run_btn.setText("Pause")
    def step_algo(self):
        try: self.state = self.step_f(self.state, self.params); self.draw_algo()
        except Exception as e: self.timer.stop(); print(f"Algo Error: {e}")
    def draw_algo(self): self.ax.clear(); self.draw_f(self.ax, self.state); self.ax.grid(True); self.canvas.draw()

_current_sim_window = None

class SimulatorEngine:
    @staticmethod
    def simulate(model, **kwargs):
        global _current_sim_window
        try:
            # Fix sys.argv to avoid Qt crashes on some Linux distros
            original_argv = sys.argv
            sys.argv = [sys.argv[0]]
            
            app = QApplication.instance() or QApplication(sys.argv)
            app.setAttribute(Qt.AA_DontUseNativeMenuBar)
            app.setQuitOnLastWindowClosed(False)
            
            ThemeManager.apply_light_theme(app)
            if model == 'algorithm':
                sw = AlgorithmSimulator(kwargs.get('step'), kwargs.get('draw'), kwargs.get('state'), **kwargs)
            elif callable(model): sw = MathSimulator(model, **kwargs)
            elif isinstance(model, (signal.TransferFunction, signal.StateSpace)): sw = ControlSimulator(model, **kwargs)
            elif type(model).__name__ in ['NeuralNet', 'LogisticRegression', 'SVM', 'RandomForest']: sw = MLSimulator(model, **kwargs)
            elif type(model).__name__ in ['KMeans', 'GMM', 'DBSCAN']: sw = KMeansSimulator(model, **kwargs)
            elif isinstance(model, str): sw = PhysicsSimulator(model, **kwargs)
            else: raise TypeError(f"Sim not supported for {type(model)}")
            
            if sw:
                _current_sim_window = sw
                for c in kwargs.get('controls', []):
                    l = getattr(sw, 'custom_layout', getattr(sw, 'controls_layout', None))
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
                        if not sw.isVisible():
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
    kwargs = {}
    if len(args) % 2 == 0:
        for i in range(0, len(args), 2):
            if isinstance(args[i], str): kwargs[args[i]] = args[i+1]
    SimulatorEngine.simulate(model, **kwargs)