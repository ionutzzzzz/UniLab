import sys
import numpy as np
from scipy import signal

try:
    import matplotlib
    matplotlib.use('Qt5Agg')
except Exception as e:
    print(f"Warning: Could not set matplotlib backend to Qt5Agg: {e}")

import matplotlib.pyplot as plt
from matplotlib.figure import Figure

try:
    from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
except ImportError as e:
    print(f"Warning: Could not import FigureCanvasQTAgg: {e}")
    FigureCanvas = None

from PyQt5.QtWidgets import (QApplication, QMainWindow, QVBoxLayout, QHBoxLayout, 
                             QWidget, QLabel, QSlider, QPushButton, QComboBox, 
                             QProgressBar, QAction, QMenu, QMenuBar, QTabWidget, QGroupBox, QFormLayout)
from PyQt5.QtCore import Qt, QTimer, QThread, pyqtSignal
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
        
        plt.style.use('dark_background')
        
    @staticmethod
    def apply_light_theme(app):
        app.setStyle("Fusion")
        app.setPalette(app.style().standardPalette())
        plt.style.use('default')

class BaseSimulator(QMainWindow):
    def __init__(self):
        super().__init__()
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
        
    def refresh_plot(self):
        pass # To be overridden

class MLTrainingThread(QThread):
    progress_update = pyqtSignal(int, float, object)
    finished_training = pyqtSignal()
    
    def __init__(self, model, X, y, epochs, lr, l1=0.0, l2=0.0):
        super().__init__()
        self.model = model
        self.X = np.array(X).copy() if X is not None else None
        self.y = np.array(y).copy() if y is not None else None
        self.epochs = epochs
        self.lr = lr
        self.l1 = l1
        self.l2 = l2
        self._is_running = True
        self.grid_pts = None
        self.meshgrid = None
        if self.X is not None and self.X.shape[1] == 2:
            x_min, x_max = self.X[:, 0].min() - 0.5, self.X[:, 0].max() + 0.5
            y_min, y_max = self.X[:, 1].min() - 0.5, self.X[:, 1].max() + 0.5
            xx, yy = np.meshgrid(np.arange(x_min, x_max, 0.1),
                                 np.arange(y_min, y_max, 0.1))
            self.grid_pts = np.c_[xx.ravel(), yy.ravel()]
            self.meshgrid = (xx.copy(), yy.copy())
        
    def run(self):
        def callback(epoch, loss):
            if not self._is_running:
                return False
            Z = None
            if self.grid_pts is not None and (epoch % max(1, self.epochs//20) == 0 or epoch == self.epochs):
                if type(self.model).__name__ == 'NeuralNet':
                    Z = self.model.predict(self.grid_pts)
                    if Z.shape[1] == 1:
                        Z = (Z > 0.5).astype(int)
                    else:
                        Z = np.argmax(Z, axis=1)
                elif type(self.model).__name__ == 'LogisticRegression':
                    Z = self.model.predict(self.grid_pts)

            if Z is not None:
                self.progress_update.emit(epoch, loss, (self.meshgrid, Z))
            else:
                self.progress_update.emit(epoch, loss, None)

            # Brief sleep to keep GUI responsive
            QThread.msleep(1)
            return True

        try:
            if type(self.model).__name__ == 'NeuralNet':
                self.model.train(self.X, self.y, epochs=self.epochs, lr=self.lr, l1=self.l1, l2=self.l2, callback=callback)
            elif type(self.model).__name__ == 'LogisticRegression':
                original_epochs = self.model.epochs
                self.model.epochs = self.epochs
                self.model.lr = self.lr
                self.model.fit(self.X, self.y, callback=callback)
                self.model.epochs = original_epochs
        except Exception as e:
            import traceback
            sys.stderr.write(f"ML Training Error: {e}\n")
            traceback.print_exc(file=sys.stderr)

        self.finished_training.emit()
    
    def stop(self):
        self._is_running = False

class KMeansTrainingThread(QThread):
    progress_update = pyqtSignal(int, object, object)
    finished_training = pyqtSignal()
    
    def __init__(self, model, X):
        super().__init__()
        self.model = model
        self.X = np.array(X).copy()
        self._is_running = True
        
    def run(self):
        def callback(epoch, centroids, labels):
            if not self._is_running:
                return False
            self.progress_update.emit(epoch, centroids.copy(), labels.copy())
            QThread.msleep(300) # Sleep to make animation visible
            return True
            
        try:
            self.model.fit(self.X, callback=callback)
        except Exception as e:
            print(f"KMeans Error: {e}")
        self.finished_training.emit()
        
    def stop(self):
        self._is_running = False

class KMeansSimulator(BaseSimulator):
    def __init__(self, model, **kwargs):
        super().__init__()
        self.model = model
        self.X = kwargs.get('X', None)
        self.epochs_history = []
        
        self.training_thread = None
        self.initUI()
        
    def initUI(self):
        self.setWindowTitle('UniLab K-Means Clustering Simulator')
        self.setGeometry(150, 150, 900, 700)
        
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        layout = QVBoxLayout(main_widget)
        
        self.figure = Figure(figsize=(7, 5))
        self.ax = self.figure.add_subplot(111)
        self.canvas = FigureCanvas(self.figure)
        layout.addWidget(self.canvas)
        
        try:
            if self.X is not None and self.X.shape[1] >= 2:
                self.ax.scatter(self.X[:, 0], self.X[:, 1], c='gray', alpha=0.5, s=30)
                self.ax.set_title("Unclustered Data")
                self.ax.grid(True)
        except Exception:
            pass
        
        controls_layout = QHBoxLayout()
        self.status_label = QLabel(f"Status: Ready (K={self.model.k})")
        controls_layout.addWidget(self.status_label)
        
        self.start_btn = QPushButton("Start")
        self.start_btn.clicked.connect(self.start_training)
        controls_layout.addWidget(self.start_btn)
        
        self.pause_btn = QPushButton("Pause")
        self.pause_btn.clicked.connect(self.pause_training)
        self.pause_btn.setEnabled(False)
        controls_layout.addWidget(self.pause_btn)
        
        self.reset_btn = QPushButton("Stop/Reset")
        self.reset_btn.clicked.connect(self.reset_training)
        controls_layout.addWidget(self.reset_btn)
        
        layout.addLayout(controls_layout)
        
    def refresh_plot(self):
        try:
            self.canvas.draw()
        except Exception:
            pass
        
    def start_training(self):
        try:
            if self.X is None:
                self.status_label.setText("Error: X data required.")
                return
                
            self.start_btn.setEnabled(False)
            self.pause_btn.setEnabled(True)
            self.status_label.setText("Status: Clustering...")
            
            self.training_thread = KMeansTrainingThread(self.model, self.X)
            self.training_thread.progress_update.connect(self.update_plot)
            self.training_thread.finished_training.connect(self.training_finished)
            self.training_thread.start()
        except Exception as e:
            self.status_label.setText(f"Error: {str(e)}")
        
    def pause_training(self):
        try:
            if self.training_thread:
                self.training_thread.stop()
                self.training_thread.wait()
            self.status_label.setText("Status: Paused")
            self.start_btn.setEnabled(True)
            self.pause_btn.setEnabled(False)
        except Exception as e:
            print(f"Pause Clustering Error: {e}")
            
    def reset_training(self):
        try:
            self.pause_training()
            if hasattr(self.model, 'reset'):
                self.model.reset()
            self.ax.clear()
            if self.X is not None and self.X.shape[1] >= 2:
                self.ax.scatter(self.X[:, 0], self.X[:, 1], c='gray', alpha=0.5, s=30)
                self.ax.set_title("Unclustered Data")
                self.ax.grid(True)
            self.status_label.setText("Status: Reset")
            self.canvas.draw()
        except Exception as e:
            print(f"Reset Clustering Error: {e}")
    
    def update_plot(self, epoch, centroids, labels):
        try:
            self.ax.clear()
            if self.X is not None and self.X.shape[1] >= 2:
                self.ax.scatter(self.X[:, 0], self.X[:, 1], c=labels, cmap='viridis', alpha=0.6, s=30)
                if centroids is not None and centroids.shape[1] >= 2:
                    self.ax.scatter(centroids[:, 0], centroids[:, 1], c='red', marker='X', s=200, edgecolors='black', linewidths=2, label='Centroids')
                    self.ax.legend()
                self.ax.set_title(f"K-Means Clustering (Epoch {epoch})")
                self.ax.grid(True)
            self.canvas.draw()
        except Exception as e:
            print(f"KMeans Update Plot Error: {e}")
            
    def training_finished(self):
        self.status_label.setText("Status: Clustering Converged")
        self.start_btn.setEnabled(True)
        self.pause_btn.setEnabled(False)

class MLSimulator(BaseSimulator):
    def __init__(self, model, **kwargs):
        super().__init__()
        self.model = model
        self.X = kwargs.get('X', None)
        self.y = kwargs.get('y', None)
        self.epochs = kwargs.get('epochs', 1000)
        self.lr = kwargs.get('lr', 0.01)
        self.l1 = kwargs.get('l1', 0.0)
        self.l2 = kwargs.get('l2', 0.0)
        
        self.epochs_history = []
        self.loss_history = []
        self.current_Z = None
        
        self.training_thread = None
        self.initUI()
        
    def initUI(self):
        self.setWindowTitle('UniLab Advanced ML Training Simulator')
        self.setGeometry(150, 150, 1000, 700)
        
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        main_layout = QHBoxLayout(main_widget)
        
        # Left Side: Tabs for Plots
        self.tabs = QTabWidget()
        
        # Tab 1: Loss Curve
        self.loss_tab = QWidget()
        self.loss_layout = QVBoxLayout(self.loss_tab)
        self.loss_figure = Figure(figsize=(6, 4))
        self.loss_ax = self.loss_figure.add_subplot(111)
        self.loss_canvas = FigureCanvas(self.loss_figure)
        self.loss_layout.addWidget(self.loss_canvas)
        self.tabs.addTab(self.loss_tab, "Loss Curve")
        
        # Tab 2: Decision Boundary (Only if 2D features)
        self.db_tab = QWidget()
        self.db_layout = QVBoxLayout(self.db_tab)
        self.db_figure = Figure(figsize=(6, 4))
        self.db_ax = self.db_figure.add_subplot(111)
        self.db_canvas = FigureCanvas(self.db_figure)
        self.db_layout.addWidget(self.db_canvas)
        self.tabs.addTab(self.db_tab, "Decision Boundary")
        
        main_layout.addWidget(self.tabs, stretch=3)
        
        # Right Side: Controls and Hyperparameters
        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)
        
        # Training Controls
        train_group = QGroupBox("Training Controls")
        train_layout = QVBoxLayout()
        self.status_label = QLabel(f"Status: Ready ({type(self.model).__name__})")
        train_layout.addWidget(self.status_label)
        
        self.progress_bar = QProgressBar()
        self.progress_bar.setMaximum(self.epochs)
        train_layout.addWidget(self.progress_bar)
        
        btn_layout = QHBoxLayout()
        self.start_btn = QPushButton("Start")
        self.start_btn.clicked.connect(self.start_training)
        btn_layout.addWidget(self.start_btn)
        
        self.pause_btn = QPushButton("Pause")
        self.pause_btn.clicked.connect(self.pause_training)
        self.pause_btn.setEnabled(False)
        btn_layout.addWidget(self.pause_btn)
        
        self.reset_btn = QPushButton("Stop/Reset")
        self.reset_btn.clicked.connect(self.reset_training)
        btn_layout.addWidget(self.reset_btn)
        
        train_layout.addLayout(btn_layout)
        train_group.setLayout(train_layout)
        right_layout.addWidget(train_group)
        
        # Hyperparameters Live Tuning
        hp_group = QGroupBox("Live Hyperparameter Tuning")
        hp_layout = QFormLayout()
        
        # Learning Rate Slider (Logarithmic scaling approximation)
        self.lr_label = QLabel(f"{self.lr:.4f}")
        self.lr_slider = QSlider(Qt.Horizontal)
        self.lr_slider.setRange(1, 1000) # Corresponds to 0.0001 to 0.1
        self.lr_slider.setValue(int(self.lr * 10000))
        self.lr_slider.valueChanged.connect(self.update_lr)
        hp_layout.addRow("Learning Rate:", self.lr_label)
        hp_layout.addRow(self.lr_slider)
        
        # L1 Regularization Slider
        self.l1_label = QLabel(f"{self.l1:.4f}")
        self.l1_slider = QSlider(Qt.Horizontal)
        self.l1_slider.setRange(0, 100) # 0 to 0.01
        self.l1_slider.setValue(int(self.l1 * 10000))
        self.l1_slider.valueChanged.connect(self.update_lr)
        hp_layout.addRow("L1 Regularization:", self.l1_label)
        hp_layout.addRow(self.l1_slider)
        
        # L2 Regularization Slider
        self.l2_label = QLabel(f"{self.l2:.4f}")
        self.l2_slider = QSlider(Qt.Horizontal)
        self.l2_slider.setRange(0, 100) # 0 to 0.01
        self.l2_slider.setValue(int(self.l2 * 10000))
        self.l2_slider.valueChanged.connect(self.update_lr)
        hp_layout.addRow("L2 Regularization:", self.l2_label)
        hp_layout.addRow(self.l2_slider)
        
        hp_group.setLayout(hp_layout)
        right_layout.addWidget(hp_group)
        
        right_layout.addStretch()
        main_layout.addWidget(right_panel, stretch=1)
        
        self.refresh_plot()
        
    def update_lr(self):
        val = self.lr_slider.value() / 10000.0
        self.lr = val
        self.lr_label.setText(f"{self.lr:.4f}")
        
        self.l1 = self.l1_slider.value() / 10000.0
        self.l1_label.setText(f"{self.l1:.4f}")
        
        self.l2 = self.l2_slider.value() / 10000.0
        self.l2_label.setText(f"{self.l2:.4f}")
        
        if self.training_thread:
            self.training_thread.lr = self.lr
            self.training_thread.l1 = self.l1
            self.training_thread.l2 = self.l2
            
    def refresh_plot(self):
        try:
            # Update Loss Plot
            self.loss_ax.clear()
            if len(self.epochs_history) > 0:
                self.loss_ax.plot(self.epochs_history, self.loss_history, 'b-')
                self.loss_ax.set_title(f'Training Loss (Epoch {self.epochs_history[-1]}, Loss: {self.loss_history[-1]:.4f})')
            else:
                self.loss_ax.set_title('Training Loss')
            self.loss_ax.set_xlabel('Epoch')
            self.loss_ax.set_ylabel('Loss')
            self.loss_ax.grid(True)
            self.loss_canvas.draw()
            
            # Update Decision Boundary Plot
            if self.current_Z is not None:
                meshgrid, Z = self.current_Z
                xx, yy = meshgrid
                
                self.db_ax.clear()
                self.db_ax.contourf(xx, yy, Z.reshape(xx.shape), alpha=0.3, cmap='coolwarm')
                self.db_ax.scatter(self.X[:, 0], self.X[:, 1], c=self.y.flatten() if self.y is not None else 'blue', edgecolor='k', cmap='coolwarm')
                self.db_ax.set_title('Decision Boundary')
                self.db_ax.grid(True)
                self.db_canvas.draw()
        except Exception as e:
            print(f"ML Refresh Plot Error: {e}")
        
    def start_training(self):
        try:
            if self.X is None or self.y is None:
                self.status_label.setText("Error: X and y data required.")
                return
                
            self.start_btn.setEnabled(False)
            self.pause_btn.setEnabled(True)
            self.status_label.setText("Status: Training...")
            
            remaining_epochs = self.epochs - len(self.epochs_history)
            if remaining_epochs <= 0:
                self.status_label.setText("Status: Training Complete.")
                self.start_btn.setEnabled(True)
                self.pause_btn.setEnabled(False)
                return
                
            self.training_thread = MLTrainingThread(self.model, self.X, self.y, remaining_epochs, self.lr, self.l1, self.l2)
            self.training_thread.progress_update.connect(self.update_plot)
            self.training_thread.finished_training.connect(self.training_finished)
            self.training_thread.start()
        except Exception as e:
            self.status_label.setText(f"Error: {str(e)}")
        
    def pause_training(self):
        try:
            if self.training_thread:
                self.training_thread.stop()
                self.training_thread.wait()
            self.status_label.setText("Status: Paused")
            self.start_btn.setEnabled(True)
            self.pause_btn.setEnabled(False)
        except Exception as e:
            print(f"Pause Training Error: {e}")
            
    def reset_training(self):
        try:
            self.pause_training()
            if hasattr(self.model, 'reset'):
                self.model.reset()
            self.epochs_history = []
            self.loss_history = []
            self.current_Z = None
            self.progress_bar.setValue(0)
            self.status_label.setText("Status: Reset")
            self.refresh_plot()
        except Exception as e:
            print(f"Reset Training Error: {e}")
        
    def update_plot(self, epoch_offset, loss, Z=None):
        try:
            current_epoch = len(self.epochs_history) + 1
            self.epochs_history.append(current_epoch)
            self.loss_history.append(loss)
            
            if current_epoch <= self.epochs:
                self.progress_bar.setValue(current_epoch)
            
            if Z is not None:
                self.current_Z = Z
                self.refresh_plot()
        except Exception as e:
            print(f"ML Update Plot Error: {e}")
    def training_finished(self):
        self.status_label.setText("Status: Training Complete")
        self.start_btn.setEnabled(True)
        self.pause_btn.setEnabled(False)
        self.progress_bar.setValue(self.epochs)
        self.refresh_plot() # Final draw

class ControlSimulator(BaseSimulator):
    def __init__(self, sys_model, **kwargs):
        super().__init__()
        self.sys_model = sys_model
        
        self.input_type = kwargs.get('input', 'step')
        self.kp = kwargs.get('kp', 1.0)
        self.ki = kwargs.get('ki', 0.0)
        self.kd = kwargs.get('kd', 0.0)
        
        self.initUI()
        
    def initUI(self):
        self.setWindowTitle('UniLab Interactive PID & Control Simulator')
        self.setGeometry(100, 100, 900, 650)
        
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        layout = QVBoxLayout(main_widget)
        
        self.figure = Figure(figsize=(6, 4))
        self.ax = self.figure.add_subplot(111)
        self.canvas = FigureCanvas(self.figure)
        layout.addWidget(self.canvas)
        
        controls_layout = QHBoxLayout()
        
        # Input selection
        input_layout = QVBoxLayout()
        self.input_combo = QComboBox()
        self.input_combo.addItems(['step', 'impulse', 'sine', 'square'])
        self.input_combo.setCurrentText(self.input_type)
        self.input_combo.currentTextChanged.connect(self.update_simulation)
        input_layout.addWidget(QLabel("Input Signal:"))
        input_layout.addWidget(self.input_combo)
        controls_layout.addLayout(input_layout)
        
        # PID Sliders
        pid_layout = QVBoxLayout()
        
        # Kp
        self.kp_label = QLabel(f"Kp (Proportional): {self.kp:.2f}")
        self.kp_slider = QSlider(Qt.Horizontal)
        self.kp_slider.setRange(0, 1000)
        self.kp_slider.setValue(int(self.kp * 100))
        self.kp_slider.valueChanged.connect(self.update_pid)
        pid_layout.addWidget(self.kp_label)
        pid_layout.addWidget(self.kp_slider)
        
        # Ki
        self.ki_label = QLabel(f"Ki (Integral): {self.ki:.2f}")
        self.ki_slider = QSlider(Qt.Horizontal)
        self.ki_slider.setRange(0, 500)
        self.ki_slider.setValue(int(self.ki * 100))
        self.ki_slider.valueChanged.connect(self.update_pid)
        pid_layout.addWidget(self.ki_label)
        pid_layout.addWidget(self.ki_slider)
        
        # Kd
        self.kd_label = QLabel(f"Kd (Derivative): {self.kd:.2f}")
        self.kd_slider = QSlider(Qt.Horizontal)
        self.kd_slider.setRange(0, 500)
        self.kd_slider.setValue(int(self.kd * 100))
        self.kd_slider.valueChanged.connect(self.update_pid)
        pid_layout.addWidget(self.kd_label)
        pid_layout.addWidget(self.kd_slider)
        
        controls_layout.addLayout(pid_layout)
        layout.addLayout(controls_layout)
        
        self.update_simulation()
        
    def refresh_plot(self):
        self.update_simulation()
        
    def update_pid(self):
        try:
            self.kp = self.kp_slider.value() / 100.0
            self.ki = self.ki_slider.value() / 100.0
            self.kd = self.kd_slider.value() / 100.0
            
            self.kp_label.setText(f"Kp (Proportional): {self.kp:.2f}")
            self.ki_label.setText(f"Ki (Integral): {self.ki:.2f}")
            self.kd_label.setText(f"Kd (Derivative): {self.kd:.2f}")
            
            self.update_simulation()
        except Exception as e:
            print(f"Update PID Error: {e}")
        
    def update_simulation(self):
        self.ax.clear()
        
        input_signal = self.input_combo.currentText()
        
        # We assume sys_model is the plant G(s)
        # Controller C(s) = Kp + Ki/s + Kd*s = (Kd*s^2 + Kp*s + Ki) / s
        C_num = [self.kd, self.kp, self.ki]
        C_den = [1, 0]
        C_sys = signal.TransferFunction(C_num, C_den)
        
        # If StateSpace, convert to TF for feedback loop calculation simplicity
        if isinstance(self.sys_model, signal.StateSpace):
            num, den = signal.ss2tf(self.sys_model.A, self.sys_model.B, self.sys_model.C, self.sys_model.D)
            plant_sys = signal.TransferFunction(num[0], den)
        else:
            plant_sys = self.sys_model
            
        # Open loop L(s) = C(s) * G(s)
        # Closed loop T(s) = L(s) / (1 + L(s))
        L_num = np.convolve(C_sys.num, plant_sys.num)
        L_den = np.convolve(C_sys.den, plant_sys.den)
        
        T_num = L_num
        T_den = np.polyadd(L_den, L_num)
        
        sys_closed = signal.TransferFunction(T_num, T_den)
        
        t = np.linspace(0, 10, 500)
        
        if input_signal == 'step':
            u = np.ones_like(t)
            _, y, _ = signal.lsim(sys_closed, u, t)
            self.ax.plot(t, u, 'g--', label='Reference (Step)')
            self.ax.plot(t, y, 'b-', label='System Output')
        elif input_signal == 'impulse':
            _, y = signal.impulse(sys_closed, T=t)
            self.ax.plot(t, y, 'r-', label='Impulse Response')
        elif input_signal == 'sine':
            u = np.sin(2 * np.pi * 1.0 * t)
            _, y, _ = signal.lsim(sys_closed, u, t)
            self.ax.plot(t, u, 'g--', label='Reference (Sine 1Hz)')
            self.ax.plot(t, y, 'b-', label='System Output')
        elif input_signal == 'square':
            u = signal.square(2 * np.pi * 0.5 * t)
            _, y, _ = signal.lsim(sys_closed, u, t)
            self.ax.plot(t, u, 'g--', label='Reference (Square 0.5Hz)')
            self.ax.plot(t, y, 'b-', label='System Output')
            
        self.ax.grid(True)
        self.ax.set_xlabel('Time (s)')
        self.ax.set_ylabel('Amplitude')
        self.ax.set_title('Closed-Loop System Response')
        self.ax.legend()
        
        poles = sys_closed.poles
        poles_str = ", ".join([f"{p.real:.2f}{'+'+str(p.imag)+'j' if p.imag>0 else (''+str(p.imag)+'j' if p.imag<0 else '')}" for p in poles])
        stable = all(p.real < 0 for p in poles)
        status_text = "Stable" if stable else "Unstable"
        self.ax.text(0.05, 0.95, f'Status: {status_text}\nPoles: {poles_str}', transform=self.ax.transAxes, 
                     bbox=dict(facecolor='white', alpha=0.5, edgecolor='none'))
        
        self.canvas.draw()

class PhysicsSimulator(BaseSimulator):
    """Simulates predefined physics models like a Pendulum."""
    def __init__(self, model_name, **kwargs):
        super().__init__()
        self.model_name = model_name
        self.initUI()
        
    def initUI(self):
        self.setWindowTitle(f'Physics Simulator: {self.model_name.capitalize()}')
        self.setGeometry(100, 100, 800, 600)
        
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        layout = QVBoxLayout(main_widget)
        
        self.figure = Figure(figsize=(6, 4))
        
        if self.model_name == 'lorenz':
            self.ax = self.figure.add_subplot(111, projection='3d')
        else:
            self.ax = self.figure.add_subplot(111)
            
        self.canvas = FigureCanvas(self.figure)
        layout.addWidget(self.canvas)
        
        self.controls_layout = QHBoxLayout()
        
        if self.model_name == 'pendulum':
            self.g = 9.81
            self.length = 1.0
            self.theta0 = np.pi / 4
            
            # Length slider
            self.l_label = QLabel(f"Length: {self.length:.1f} m")
            self.l_slider = QSlider(Qt.Horizontal)
            self.l_slider.setRange(1, 50)
            self.l_slider.setValue(10)
            self.l_slider.valueChanged.connect(self.update_params)
            
            self.controls_layout.addWidget(self.l_label)
            self.controls_layout.addWidget(self.l_slider)
            
            # Initial Angle slider
            self.angle_label = QLabel(f"Init Angle: 45°")
            self.angle_slider = QSlider(Qt.Horizontal)
            self.angle_slider.setRange(10, 170)
            self.angle_slider.setValue(45)
            self.angle_slider.valueChanged.connect(self.update_params)
            
            self.controls_layout.addWidget(self.angle_label)
            self.controls_layout.addWidget(self.angle_slider)
            
        elif self.model_name == 'lorenz':
            self.sigma = 10.0
            self.rho = 28.0
            self.beta = 8.0 / 3.0
            
            # Rho (Rayleigh Number) Slider
            self.rho_label = QLabel(f"Rho: {self.rho:.1f}")
            self.rho_slider = QSlider(Qt.Horizontal)
            self.rho_slider.setRange(0, 500)
            self.rho_slider.setValue(int(self.rho * 10))
            self.rho_slider.valueChanged.connect(self.update_params)
            
            self.controls_layout.addWidget(self.rho_label)
            self.controls_layout.addWidget(self.rho_slider)
            
        layout.addLayout(self.controls_layout)
        self.update_simulation()
        
    def update_params(self):
        try:
            if self.model_name == 'pendulum':
                self.length = self.l_slider.value() / 10.0
                angle_deg = self.angle_slider.value()
                self.theta0 = angle_deg * np.pi / 180.0
                
                self.l_label.setText(f"Length: {self.length:.1f} m")
                self.angle_label.setText(f"Init Angle: {angle_deg}°")
            elif self.model_name == 'lorenz':
                self.rho = self.rho_slider.value() / 10.0
                self.rho_label.setText(f"Rho: {self.rho:.1f}")
                
            self.update_simulation()
        except Exception as e:
            print(f"Update Params Error: {e}")
        
    def refresh_plot(self):
        self.update_simulation()
        
    def update_simulation(self):
        self.ax.clear()
        
        if self.model_name == 'pendulum':
            from scipy.integrate import odeint
            
            def pendulum_eq(y, t, b, c):
                theta, omega = y
                dydt = [omega, -b*omega - c*np.sin(theta)]
                return dydt
            
            b = 0.25 # friction
            c = self.g / self.length
            
            y0 = [self.theta0, 0.0]
            t = np.linspace(0, 10, 250)
            sol = odeint(pendulum_eq, y0, t, args=(b, c))
            
            self.ax.plot(t, sol[:, 0] * 180 / np.pi, 'b-', label='Angle (degrees)')
            self.ax.plot(t, sol[:, 1] * 180 / np.pi, 'r--', label='Angular Vel (deg/s)')
            self.ax.set_title('Damped Pendulum Dynamics')
            
            self.ax.grid(True)
            self.ax.set_xlabel('Time (s)')
            self.ax.legend()
        elif self.model_name == 'lorenz':
            from scipy.integrate import odeint
            
            def lorenz_eq(y, t, sigma, rho, beta):
                x, y_, z = y
                return [sigma * (y_ - x), x * (rho - z) - y_, x * y_ - beta * z]
            
            y0 = [1.0, 1.0, 1.0]
            t = np.linspace(0, 50, 5000)
            sol = odeint(lorenz_eq, y0, t, args=(self.sigma, self.rho, self.beta))
            
            self.ax.plot(sol[:, 0], sol[:, 1], sol[:, 2], 'm-', lw=0.5)
            self.ax.set_title('Lorenz Attractor (Chaos)')
            self.ax.set_xlabel('X')
            self.ax.set_ylabel('Y')
            self.ax.set_zlabel('Z')
            
        self.canvas.draw()


class SimulatorEngine:
    @staticmethod
    def simulate(model, **kwargs):
        try:
            import os
            
            # Suppress GTK warnings
            os.environ['GTK_MODULES'] = ''
            
            app = QApplication.instance()
            if app is None:
                try:
                    app = QApplication(sys.argv)
                except Exception as e:
                    print(f"Warning: Failed to create QApplication: {e}")
                    print("Simulation will not display a GUI.")
                    return
            
            ThemeManager.apply_light_theme(app)
            
            try:
                if isinstance(model, (signal.TransferFunction, signal.StateSpace)):
                    sim_window = ControlSimulator(model, **kwargs)
                    sim_window.show()
                elif type(model).__name__ in ['NeuralNet', 'LogisticRegression']:
                    sim_window = MLSimulator(model, **kwargs)
                    sim_window.show()
                elif type(model).__name__ in ['KMeans']:
                    sim_window = KMeansSimulator(model, **kwargs)
                    sim_window.show()
                elif isinstance(model, str) and model in ['pendulum', 'lorenz']:
                    sim_window = PhysicsSimulator(model, **kwargs)
                    sim_window.show()
                else:
                    raise TypeError(f"Simulation not supported for object of type {type(model)}")
                
                # Use processEvents instead of exec_ to avoid blocking
                # This allows the GUI to be responsive while keeping compatibility with asyncio
                import time
                start_time = time.time()
                timeout_seconds = 300  # 5 minute timeout
                
                while sim_window.isVisible():
                    app.processEvents()
                    time.sleep(0.05)  # Small sleep to prevent CPU spinning
                    
                    # Timeout check
                    if time.time() - start_time > timeout_seconds:
                        print("Simulation window closed due to timeout.")
                        break
                        
            except Exception as e:
                print(f"Error creating simulator window: {e}")
                import traceback
                traceback.print_exc()
                
        except Exception as e:
            print(f"Error during simulation: {e}")
            import traceback
            traceback.print_exc()

def unilab_simulate(model, *args):
    kwargs = {}
    if len(args) % 2 == 0:
        for i in range(0, len(args), 2):
            if isinstance(args[i], str):
                kwargs[args[i]] = args[i+1]
    
    SimulatorEngine.simulate(model, **kwargs)