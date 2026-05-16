import base64
from PIL import Image
import io

if __name__ == "__main__":
    from PIL import Image
    # Create dummy graph.png
    Image.new("RGB", (100, 100), color="blue").save("graph.png")

    img = Image.open("graph.png").convert("RGB")
    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=85, optimize=True)
    jpeg_data = buf.getvalue()
    print("JPEG size:", len(jpeg_data))
    print("JPEG Base64 size:", len(base64.b64encode(jpeg_data)))

