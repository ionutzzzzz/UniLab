import numpy as np
import sys
from PyQt5.QtWidgets import QApplication
from PyQt5.QtCore import QTimer, QThread
from backend.core.simulation.engine import KMeansTrainingThread, KMeansSimulator
from backend.packages import ml

app = QApplication(sys.argv)
model = ml.KMeans(k=3, max_iters=50)
sim_window = KMeansSimulator(model, X=np.random.randn(150, 2))

def check():
    print("Main thread:", QThread.currentThread())
    sim_window.start_training()
    
    # Monkey patch update_plot to see thread
    old_update = sim_window.update_plot
    def new_update(epoch, centroids, labels):
        print("update_plot thread:", QThread.currentThread())
        old_update(epoch, centroids, labels)
    sim_window.update_plot = new_update

QTimer.singleShot(100, check)
QTimer.singleShot(2000, app.quit)
QT_QPA_PLATFORM=offscreen app.exec_()
