import os
import base64

def is_kitty():
    """Detect Kitty terminal."""
    return "KITTY_WINDOW_ID" in os.environ or (os.environ.get("TERM", "") and "kitty" in os.environ["TERM"])

def is_iterm2():
    """Detect iTerm2 terminal."""
    return os.environ.get("TERM_PROGRAM") == "iTerm.app"

def is_wezterm():
    """Detect WezTerm terminal."""
    return "WEZTERM_PANE" in os.environ or "WEZTERM_EXECUTABLE" in os.environ

def get_kitty_sequence(img_path):
    """Generate Kitty graphics protocol sequence."""
    try:
        with open(img_path, "rb") as f:
            data = f.read()
        
        encoded = base64.b64encode(data).decode('ascii')
        chunk_size = 4096
        res = ""
        for i in range(0, len(encoded), chunk_size):
            chunk = encoded[i:i+chunk_size]
            m = 1 if i + chunk_size < len(encoded) else 0
            if i == 0:
                # a=T: action=transmit, f=100: format=PNG
                res += f"\x1b_Ga=T,f=100,m={m};{chunk}\x1b\\"
            else:
                res += f"\x1b_Gm={m};{chunk}\x1b\\"
        return res
    except Exception:
        return None

def get_iterm2_sequence(img_path):
    """Generate iTerm2 inline image protocol sequence."""
    try:
        with open(img_path, "rb") as f:
            data = f.read()
        encoded = base64.b64encode(data).decode('ascii')
        # \x1b]1337;File=inline=1;...:<base64>\x07
        return f"\x1b]1337;File=inline=1;preserveAspectRatio=1:{encoded}\x07"
    except Exception:
        return None

def get_terminal_graphics(img_path):
    """Detect terminal and return appropriate graphics sequence or None."""
    # Check for force fallback
    if os.environ.get("UNILAB_FORCE_FALLBACK", "0") == "1":
        return None
        
    if is_kitty():
        return get_kitty_sequence(img_path)
    
    if is_iterm2() or is_wezterm():
        return get_iterm2_sequence(img_path)
    
    return None
