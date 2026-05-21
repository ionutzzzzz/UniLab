from backend.core.core import UniLabTranspiler
import pathlib

p = pathlib.Path('backend/libraries/control/routh_table.m')
code = p.read_text()
transpiler = UniLabTranspiler()
py_code, _, _ = transpiler.transpile(code)
print(py_code)
