import sys
import time
from backend.core.simulation.engine import SimulatorEngine
from PyQt5.QtWidgets import QApplication

def dummy_step(state, params):
    state['x'] += 1
    return state

def dummy_draw(ax, state):
    ax.plot([0, state['x']], [0, state['x']])

if __name__ == '__main__':
    app = QApplication(sys.argv)
    SimulatorEngine.simulate('algorithm', step=dummy_step, draw=dummy_draw, state={'x': 0}, on_init=lambda: time.sleep(0.5) or app.quit())
