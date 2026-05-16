import sys

def test_truecolor():
    print("Testing TrueColor Support:")
    for r in range(0, 256, 16):
        line = ""
        for g in range(0, 256, 16):
            # Foreground white, background varies
            line += f"\x1b[38;2;255;255;255m\x1b[48;2;{r};{g};0mX\x1b[0m"
        print(line)

test_truecolor()
