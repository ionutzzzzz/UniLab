import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from backend.core.runtime import plot, title, xlabel, ylabel
import numpy as np

x = np.linspace(0, 10, 100)
plot(x, np.sin(x))
