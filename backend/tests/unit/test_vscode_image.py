import sys
import base64

if __name__ == "__main__":
    from PIL import Image
    # Create dummy graph.png
    Image.new("RGB", (100, 100), color="red").save("graph.png")

    with open("graph.png", "rb") as f:
        img_data = f.read()
        
    b64 = base64.b64encode(img_data).decode("ascii")
    sys.stdout.write(f"\x1b]1337;File=inline=1;size={len(img_data)};width=90%;height=auto:{b64}\a\n")
    sys.stdout.flush()
