#!/usr/bin/env python3
"""UniLab CLI entry point.

Delegates execution directly to the canonical CLI application in `backend.cli.app`.
"""
import sys
import pathlib

# Ensure project root is in sys.path
PROJECT_ROOT = pathlib.Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from backend.cli.app import main, show_plots

__all__ = ["main", "show_plots"]

if __name__ == "__main__":
    main()
