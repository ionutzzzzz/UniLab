# Image Display in Terminals – Summary

Displaying high-quality raster images in a terminal requires using special graphics protocols rather than ASCII art. Modern terminals like **Kitty**, **iTerm2**, **WezTerm**, etc. implement proprietary or standard protocols (e.g. **Kitty’s graphics protocol** and **iTerm2’s inline image protocol**). These allow full-color images with per-pixel detail (including retina support) without blurring. By contrast, fallback methods like **Sixel** output or using `w3mimgdisplay` tend to reduce color depth or rely on external X support. Key factors include:  

- **Protocols & Support:** Kitty’s protocol (ESC `_G…\033\\` sequences) offers GPU-accelerated image display (true color, retina)【30†L977-L985】【24†L779-L783】. iTerm2’s protocol (OSC `1337;File=...` with base64) is similar but Mac-only【9†L93-L101】【12†L99-L103】. WezTerm supports both iTerm2 and Kitty protocols (plus experimental Sixel)【24†L779-L783】. Sixel (DEC VT “sixel” escapes) is supported by older or patched terminals (xterm with `--enable-sixel`, mlterm, etc. 【46†L129-L137】) but is limited (often 16–256 colors, heavy dithering). Tools like **w3mimgdisplay** draw via X and can temporarily show images in some Linux terminals, but have issues (image lost on redraw) and require an X server【27†L109-L117】.  

- **Libraries/Tools:** Python libraries include **Pillow** (for image I/O), **imgcat** (implements iTerm2/WezTerm image protocol)【12†L99-L103】, **kitty-graphics** or raw control sequences for the Kitty protocol【30†L977-L985】, **libsixel-Python** or **PySixel** for Sixel encoding【46†L134-L137】, and **term-image** (a high-level package supporting Kitty/iTerm2)【2†L69-L77】. Older X-based libraries like **ueberzug** require an X terminal.  

- **Quality & Scaling:** Kitty and iTerm2 give **pixel-perfect quality** (Kitty even honors pixel aspect ratio and retina scaling)【9†L84-L92】【30†L1009-L1017】. They can scale images via protocol parameters. Sixel’s quality is lower (images are downsampled/dithered to 16–256 colors)【46†L134-L137】. Without special support, ASCII/Unicode fallback (e.g. block characters) yields blurry results and is disallowed here.  

- **Terminal and Environment Support:**  
  - *Kitty protocol:* Native in Kitty (and forked in Konsole’s later versions, WezTerm, etc.【5†L805-L814】【24†L779-L783】). Not supported in GNOME Terminal or Windows Terminal by default.  
  - *iTerm2 protocol:* Works in iTerm2 on macOS【9†L93-L101】 and in WezTerm (which is iTerm2-compatible)【24†L779-L783】. Not in Linux terminals.  
  - *Sixel:* Supported on *nix in terminals compiled with Sixel (xterm, mlterm, etc.【46†L129-L137】) and on WezTerm (since mid-2020)【24†L779-L783】. No native support on macOS or Windows Terminal.  
  - *Multiplexers:* `tmux` often blocks raw graphics by default. For example, iTerm2 images require `set-option -g allow-passthrough on` in tmux ≥3.3【47†L155-L159】. Sixel requires tmux ≥3.4 with passthrough (or running outside tmux)【47†L155-L159】.  

- **Performance & Limitations:** Sending large images (MBs) as base64 over the terminal is bandwidth-heavy. Kitty’s protocol supports *chunking* and even compression【30†L1007-L1014】, but performance can still lag on remote connections. iTerm2’s OSC stream can exceed tmux/SSH limits. Sixel encoding is CPU-intensive and slow. 

- **SSH/Remote:** Graphics protocols work over SSH if the *local* terminal supports them (i.e. the server just sends escape sequences to the local emulator). In practice, iTerm2 and Kitty graphics display via SSH, but the remote terminal (tmux) may need passthrough settings【47†L155-L159】. X-based methods like w3mimgdisplay **do not** work over plain SSH (they rely on local X windows).

- **Fallback Behavior:** If no advanced protocol is available, options are limited. W3mimgdisplay can show an image in an X terminal on Linux but is ephemeral and unreliable. True fallback might simply inform the user that inline image display is unsupported. 

In summary, **Kitty’s graphics protocol** (via direct escape sequences or a helper library) is the highest-fidelity approach for *any* OS/terminal that supports it (GPU-accelerated, truecolor, retina【30†L977-L985】). **iTerm2’s protocol (imgcat)** is equivalent quality on macOS【9†L93-L101】. When those aren’t available, one can fall back to **Sixel** (widely-supported on *nix) at the expense of color depth【46†L134-L137】. The following table compares these methods.

| **Method / Protocol**      | **Supported Terminals**                                     | **Python Libraries**                  | **Image Quality**      | **Scaling**                       | **Color Depth**    | **Performance**              | **SSH/Remote**          | **tmux/screen**            | **Snippet (usage)**                         |
|----------------------------|-------------------------------------------------------------|---------------------------------------|------------------------|-----------------------------------|--------------------|------------------------------|-------------------------|-----------------------------|----------------------------------------------|
| **Kitty Graphics** (ESC `_G`)  | Kitty, Konsole (with patch), WezTerm, iTerm2【5†L805-L814】【24†L779-L783】 | `Pillow` + raw escapes or `kitty-graphics` | *Native pixel* (best; retina/HiDPI support)【30†L977-L985】【9†L84-L92】 | Can set width/height in px or cells【9†L143-L151】【30†L1012-L1020】 | Full 24-bit (truecolor) | High bandwidth (base64), but supports chunking/compression【30†L1007-L1014】 | Yes (via SSH, if terminal supports) | Supported if `allow-passthrough` on for tmux【47†L155-L159】 | ```python\nfrom base64 import b64encode\nfrom PIL import Image\nim=Image.open(path).convert('RGBA')\nb = im.tobytes(); h,w = im.size[1], im.size[0]\nheader = f\"\\033_Gf=24,s={w},v={h},m=1;\".encode()\ndata = b64encode(b)\nprint(header + data + b'\\033\\\\')``` |
| **iTerm2 Inline** (OSC `1337`) | iTerm2 (macOS), WezTerm【9†L93-L101】【24†L779-L783】           | [imgcat](https://pypi.org/project/imgcat) (Python CLI/API)【12†L99-L103】 | *Native pixel* (retina aware since v3.2)【9†L84-L92】 | Can specify width/height in chars, px, or %【9†L143-L151】      | Full 24-bit        | Base64 large streams; **tmux note**: older tmux limited size【47†L155-L159】 | Yes (protocol travels over SSH) | Requires tmux passthrough (or tmux ≤2.4)【47†L155-L159】 | ```python\nfrom imgcat import imgcat\nimgcat('image.png', width='50%', preserve_aspect=True)``` |
| **Sixel Graphics**         | xterm (–enable-sixel), mlterm, most DEC terminals【46†L129-L137】; WezTerm (experimental)【24†L779-L783】 | `PySixel` or `libsixel` bindings【46†L134-L137】      | Pixellated, often dithering to limited palette【46†L134-L137】 | Can specify width/height; target is cell-level resolution【46†L180-L188】 | Up to 256 colors (often set to 16 by default)【46†L134-L137】 | CPU-heavy encode; text output moderate size (RLE-compressed) | Yes (if terminal supports) | tmux ≥3.4 needed with passthrough, else use outside tmux【47†L155-L159】 | ```python\nfrom libsixel.encoder import Encoder\nenc = Encoder(); enc.setopt(Encoder.SIXEL_OPTFLAG_WIDTH, '80')\nenc.setopt(Encoder.SIXEL_OPTFLAG_COLORS, '256')\nenc.encode('image.png')``` |
| **w3mimgdisplay (X)**      | Linux consoles with framebuffer or X (via w3m); requires X11/Wayland window    | `subprocess` call to `/usr/libexec/w3m/w3mimgdisplay`  | High (actual image), but is *drawn behind text buffer* | Fixed position/size via coordinates | Truecolor (uses actual image) | Very fast draw (uses existing images) | **Not over SSH** (draws on X display) | Overwrites output, lost on scroll/redraw【27†L109-L117】 | Not recommended for general use (no simple code snippet) |

> **Note:** tmux/screen can strip these escapes. For example, tmux ≥3.3 requires `set-option -g allow-passthrough on` for images【47†L155-L159】. Without it, even raw iTerm2/Kitty escapes may be blocked.

## Examples

Below are two complete Python examples. **Example A** uses the Kitty graphics protocol (best quality). **Example B** uses Sixel encoding as a fallback. Each script reads an image file path and attempts to display it in the terminal.

```python
# Example A: Display image via Kitty graphics protocol (best quality)
import os, sys
from base64 import standard_b64encode
from PIL import Image

def display_kitty(path):
    # Open image and get raw PNG bytes
    im = Image.open(path)
    # Kitty protocol can accept raw PNG data (f=100) or raw RGBA (f=24/32)
    # Here we use PNG for simplicity and compression.
    buf = io.BytesIO()
    im.save(buf, format="PNG")
    data = buf.getvalue()

    # Send in chunks to avoid exceeding escape length limits
    chunk_size = 4096
    first = True
    for i in range(0, len(data), chunk_size):
        chunk = data[i:i+chunk_size]
        eof = (i+chunk_size >= len(data))
        # Build control sequence
        if first:
            # 'a=T' says "begin image"
            header = f"\033_Ga=T,f=100;"
            first = False
        else:
            # no initial metadata on subsequent chunks
            header = "\033_G"
        # 'm=0' means final chunk; 'm=1' means more coming
        header += f"m={0 if eof else 1};"
        # Write header, data, and terminator
        sys.stdout.buffer.write(header.encode('ascii'))
        sys.stdout.buffer.write(standard_b64encode(chunk))
        sys.stdout.buffer.write(b"\033\\")
    sys.stdout.flush()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python kitty_display.py <image_path>")
        sys.exit(1)
    img_path = sys.argv[1]
    # Detect if running in Kitty (KITTY_WINDOW_ID present)
    if "KITTY_WINDOW_ID" in os.environ:
        display_kitty(img_path)
    else:
        print("Kitty protocol not detected. Please run in Kitty terminal.")
```

This **Kitty example** uses the native protocol for maximum clarity. It encodes the image as PNG and streams it in chunks (using the `ESC _G ... ESC \` sequence)【30†L977-L985】【30†L992-L1000】. It checks `KITTY_WINDOW_ID` to ensure it’s in a Kitty instance. The width/height is not specified here, so the image is shown at its pixel size (Kitty will scale it to fit the window if needed). Because Kitty is a GPU-accelerated terminal, this yields a sharp image with proper aspect ratio (even on Retina)【9†L84-L92】【30†L1009-L1018】.

```python
# Example B: Fallback using Sixel (fewer dependencies)
import sys
try:
    from libsixel.encoder import Encoder, SIXEL_OPTFLAG_WIDTH, SIXEL_OPTFLAG_COLORS
except ImportError:
    print("libsixel not installed. Install with `pip install libsixel-python`.")
    sys.exit(1)

def display_sixel(path):
    enc = Encoder()
    # Optionally set width (in characters or pixels) to fit terminal
    enc.setopt(SIXEL_OPTFLAG_WIDTH, "80")      # e.g., 80 columns wide
    enc.setopt(SIXEL_OPTFLAG_COLORS, "256")    # up to 256 colors if supported
    # Encode and write sixel directly to stdout
    enc.encode(path)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python sixel_display.py <image_path>")
        sys.exit(1)
    display_sixel(sys.argv[1])
```

This **Sixel fallback** uses the `libsixel` encoder to convert an image to sixel graphics escapes. Sixel may **dither** the image (especially if the terminal only supports 16 colors)【46†L134-L137】, but it works on many Linux terminals (xterm –enable-sixel, mlterm, etc.)【46†L129-L137】. It sets a fixed width (`80` cells here) and up to 256 colors. In practice, adjust the width to your terminal size for best results.

## Setup and Dependencies

To use these examples and other methods, install the required Python libraries:

- **Pillow** (`pip install pillow`) for image I/O in most cases (used by the Kitty example).  
- **imgcat** (`pip install imgcat`) if you want to use the iTerm2/WezTerm protocol from Python (Example: `from imgcat import imgcat`).  
- **libsixel** (`pip install libsixel-python`) or **PySixel** (`pip install PySixel`) if you plan to encode Sixel images (required by the Sixel example). Note that `libsixel-python` may require libSIXEL on the system or building from source.  
- **term-image** (`pip install term-image`) is an all-in-one package that internally supports Kitty and iTerm2 escapes (with detection logic). It can simplify usage but under the hood uses the same protocols【2†L69-L77】.  

Ensure your terminal emulator supports the desired protocol: for example, enable “Allow ASCII control characters” in Konsole for Kitty escapes, or compile xterm with `--enable-sixel` for Sixel.

## Detection Logic

A robust script should detect the terminal and choose the best available method at runtime. For example:

1. **Kitty available?** Check `os.environ["KITTY_WINDOW_ID"]` (or `TERM` contains `-kitty`)【5†L805-L814】. If yes, use Kitty protocol (Example A).  
2. **iTerm2/WezTerm?** Check `os.environ["TERM_PROGRAM"] == "iTerm.app"` or `COLORTERM == "truecolor"` or WezTerm-specific env variables【12†L99-L103】【24†L779-L783】. If yes, use `imgcat` (calls iTerm2’s OSC 1337) for best Mac/WezTerm support.  
3. **Sixel support?** If `TERM` suggests xterm/terminal with sixel, or if libsixel is installed, use Sixel (Example B).  
4. **No support:** Optionally try `w3mimgdisplay` (with X11) or simply print an error saying “Terminal does not support inline images.”

A mermaid diagram of this flow:

```mermaid
flowchart TD
    A[Start] --> B{Kitty protocol?}
    B -- Yes --> C[Use Kitty graphics (Example A)]
    B -- No  --> D{iTerm2/WezTerm?}
    D -- Yes --> E[Use iTerm2/imgcat protocol]
    D -- No  --> F{Sixel support?}
    F -- Yes --> G[Use Sixel encoding (Example B)]
    F -- No  --> H[Print "Unsupported terminal"]
```

## Testing & Troubleshooting

- **Verify True Color:** Confirm your terminal reports 24-bit color support (`COLORTERM=truecolor`). If not, images may degrade to 256 colors【2†L73-L77】.  
- **Check Sizes:** Use `stty size` or `ioctl(TIOCGWINSZ)` to get terminal pixel dimensions【5†L825-L834】, and scale images accordingly. If images exceed the viewport, they may scroll or cut off.  
- **tmux/Screen:** Test outside tmux first. If using tmux, add `set-option -g allow-passthrough on` (tmux ≥3.3)【47†L155-L159】. For screen, similar passthrough settings or attach after.  
- **SSH:** Ensure your *local* terminal supports the protocol (SSH only transmits escape codes). Using iTerm2 → ssh to Linux → Kitty on Linux will not magically display on macOS iTerm (the protocol only works to local emulator).  
- **Installation:** If a method “does nothing,” ensure its CLI dependencies are present (e.g. `w3m-img` for w3mimgdisplay, Pillow for Python examples, libsixel library installed for Python libsixel).  

## Recommended Default Approach

For general use, **Kitty’s graphics protocol** is the default recommendation for best quality, provided you run in Kitty (or compatible) terminal【30†L977-L985】. Otherwise, on macOS or WezTerm use **imgcat** (iTerm2 protocol). On Linux GUI terminals without Kitty/iTerm, **libsixel** is the fallback, acknowledging its color limitations【46†L134-L137】. 

Always include detection logic to select the method at runtime, as shown above. For most users on modern terminals, simply using [Term-Image](https://term-image.readthedocs.io) or calling `imgcat` if in iTerm/WezTerm (and Sixel otherwise) covers all bases. 

**Sources:** Official terminal docs and library docs/specs were used for all details【9†L93-L101】【30†L977-L985】【2†L69-L77】【46†L134-L137】【47†L155-L159】【24†L779-L783】. These include protocol specifications (Kitty docs), implementation notes (iTerm2 docs, imgcat readme), and Python package references.