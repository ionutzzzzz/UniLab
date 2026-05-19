import traceback
import sys
from backend.core.simulation.engine import SimulatorEngine
from backend.packages import ml
import numpy as np

try:
    X = np.random.randn(150, 2)
    model = ml.KMeans(k=3, max_iters=50)
    SimulatorEngine.simulate(model, X=X)
except Exception as e:
    traceback.print_exc()
