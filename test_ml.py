import numpy as np
import sys
import traceback
from PyQt5.QtWidgets import QApplication
from PyQt5.QtCore import QTimer
from backend.core.simulation.engine import SimulatorEngine, MLSimulator
from backend.packages import ml

def test():
    app = QApplication.instance()
    if app is None:
        app = QApplication(sys.argv)
    
    X = np.random.randn(100, 2)
    y = np.random.randint(0, 2, (100, 1))
    net = ml.NeuralNet([2, 10, 1], 'tanh')
    
    sim_window = MLSimulator(net, X=X, y=y, epochs=100, lr=0.05)
    sim_window.show()
    
    def on_timeout():
        print("Starting training...", flush=True)
        try:
            sim_window.start_training()
        except Exception as e:
            traceback.print_exc()
            app.quit()
    
    QTimer.singleShot(1000, on_timeout)
    QTimer.singleShot(3000, app.quit)
    app.exec_()

try:
    test()
except Exception:
    traceback.print_exc()