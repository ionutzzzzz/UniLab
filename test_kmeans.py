import numpy as np
import sys
import traceback
from PyQt5.QtWidgets import QApplication
from PyQt5.QtCore import QTimer
from backend.core.simulation.engine import SimulatorEngine, KMeansSimulator
from backend.packages import ml

def test():
    app = QApplication.instance()
    if app is None:
        app = QApplication(sys.argv)
    
    X = np.random.randn(150, 2)
    model = ml.KMeans(k=3, max_iters=50)
    
    sim_window = KMeansSimulator(model, X=X)
    sim_window.show()
    
    def on_timeout():
        print("Starting clustering...", flush=True)
        try:
            sim_window.start_training()
        except Exception as e:
            traceback.print_exc()
            app.quit()
    
    QTimer.singleShot(1000, on_timeout)
    QTimer.singleShot(5000, app.quit)
    app.exec_()

try:
    test()
except Exception:
    traceback.print_exc()
