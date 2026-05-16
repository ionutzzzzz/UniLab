import sys
import base64
import os

with open("graph.png", "rb") as f:
    img_data = f.read()
    
b64 = base64.b64encode(img_data).decode("ascii")
sys.stdout.write(f"\x1b]1337;File=inline=1;size={len(img_data)};width=90%;height=auto:{b64}\a\n")
sys.stdout.flush()
