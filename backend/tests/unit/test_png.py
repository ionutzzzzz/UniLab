import base64
from PIL import Image
import io

if __name__ == "__main__":
    from PIL import Image
    # Create dummy graph.png
    Image.new("RGB", (100, 100), color="green").save("graph.png")

    img = Image.open("graph.png").convert("P", palette=Image.ADAPTIVE, colors=256)
    buf = io.BytesIO()
    img.save(buf, format="PNG", optimize=True)
    png_data = buf.getvalue()
    print("PNG P size:", len(png_data))
    print("PNG P Base64 size:", len(base64.b64encode(png_data)))
