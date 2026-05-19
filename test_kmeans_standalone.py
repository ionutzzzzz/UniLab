import faulthandler
faulthandler.enable()
import numpy as np
import sys
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
        sim_window.start_training()
    
    QTimer.singleShot(500, on_timeout)
    QTimer.singleShot(3000, app.quit)
    app.exec_()

if __name__ == '__main__':
    test()
