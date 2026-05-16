import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from backend.core.runtime import render_image_terminal

out = render_image_terminal("graph.png")
print("Length of output:", len(out) if out else 0)
print("Output snippet:", out[:50] if out else None)
