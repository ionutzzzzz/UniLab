"""UniLab main entry point."""
import sys
import pathlib

# Ensure project root is in sys.path
current_dir = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(current_dir.parent))

from backend.cli.app import main

if __name__ == "__main__":
    main()
