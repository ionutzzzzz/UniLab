from backend.core.core import UniLabTranspiler
import pathlib

code = pathlib.Path('sample/30_robotics_arm_kinematics.m').read_text()
transpiler = UniLabTranspiler()
py_code, _, _ = transpiler.transpile(code)

with open('debug_transpiled.py', 'w') as f:
    f.write(py_code)

print("Transpilation successful. Saved to debug_transpiled.py")
