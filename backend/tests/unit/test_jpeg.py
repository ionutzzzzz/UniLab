import base64
from PIL import Image
import io

img = Image.open("graph.png").convert("RGB")
buf = io.BytesIO()
img.save(buf, format="JPEG", quality=50)
jpeg_data = buf.getvalue()
print("JPEG 50 size:", len(jpeg_data))
print("JPEG 50 Base64 size:", len(base64.b64encode(jpeg_data)))
