import faulthandler
faulthandler.enable()
import os
import sys

# Replace process with UniLab script
os.execlp("python3", "python3", "backend/UniLab.py", "run", "sample/17_gui_kmeans_sim.m")
