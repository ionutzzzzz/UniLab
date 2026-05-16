from PIL import Image, ImageDraw
import numpy as np

def image_to_braille_color(img_path, width=80):
    img = Image.open(img_path).convert('RGB')
    
    target_width_px = width * 2
    aspect_ratio = img.height / img.width
    target_height_px = int(target_width_px * aspect_ratio)
    
    if target_height_px % 4 != 0:
        target_height_px += (4 - (target_height_px % 4))
        
    img = img.resize((target_width_px, target_height_px), Image.Resampling.LANCZOS)
    
    pixels = np.array(img)
    # Threshold based on luminance to find non-white pixels
    # Luminance = 0.299 R + 0.587 G + 0.114 B
    luminance = 0.299 * pixels[:, :, 0] + 0.587 * pixels[:, :, 1] + 0.114 * pixels[:, :, 2]
    binary = luminance < 240
    
    dot_map = [
        [0x01, 0x08],
        [0x02, 0x10],
        [0x04, 0x20],
        [0x40, 0x80]
    ]
    
    braille_chars = []
    for r in range(0, target_height_px, 4):
        line = ""
        for c in range(0, target_width_px, 2):
            char_val = 0x2800
            r_sum, g_sum, b_sum, count = 0, 0, 0, 0
            for dr in range(4):
                for dc in range(2):
                    if binary[r+dr, c+dc]:
                        char_val |= dot_map[dr][dc]
                        color = pixels[r+dr, c+dc]
                        r_sum += color[0]
                        g_sum += color[1]
                        b_sum += color[2]
                        count += 1
            if count > 0:
                avg_r = int(r_sum / count)
                avg_g = int(g_sum / count)
                avg_b = int(b_sum / count)
                line += f"\x1b[38;2;{avg_r};{avg_g};{avg_b}m{chr(char_val)}\x1b[0m"
            else:
                line += " "
        braille_chars.append(line)
        
    print("\n".join(braille_chars))

if __name__ == "__main__":
    # Create a dummy image if it doesn't exist
    from PIL import Image, ImageDraw
    img = Image.new('RGB', (100, 100), color='white')
    d = ImageDraw.Draw(img)
    d.text((10,10), "Test", fill=(255,0,0))
    img.save('dummy2.png')
    
    image_to_braille_color('dummy2.png', width=50)
