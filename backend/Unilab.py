import asyncio
import argparse
import pathlib
import sys
import os
import re
from typing import Optional

def highlight_syntax(code: str) -> str:
    """Applies TrueColor pastel ANSI color codes to UniLab/MATLAB syntax."""
    # Pastel RGB Colors
    PASTEL_PURPLE = "\x1b[38;2;191;148;228m" # Keywords
    PASTEL_CYAN   = "\x1b[38;2;137;207;240m" # Functions
    PASTEL_YELLOW = "\x1b[38;2;253;253;150m" # Strings
    PASTEL_GRAY   = "\x1b[38;2;169;169;169m" # Comments
    RESET = "\x1b[0m"

    keywords = r'\b(function|end|if|elseif|else|for|while|switch|case|otherwise|try|catch|global|clear|return|break|continue)\b'
    
    # Highlight comments
    if '%' in code:
        parts = code.split('%', 1)
        code = parts[0]
        comment = f"{PASTEL_GRAY}%{parts[1]}{RESET}"
    else:
        comment = ""
    
    # Highlight strings
    code = re.sub(r"('[^'\n]*')", f"{PASTEL_YELLOW}\\1{RESET}", code)
    
    # Highlight keywords
    code = re.sub(keywords, f"{PASTEL_PURPLE}\\1{RESET}", code)
    
    # Highlight functions calls
    code = re.sub(r'\b([a-zA-Z_][a-zA-Z0-9_]*)\s*(?=\()', f"{PASTEL_CYAN}\\1{RESET}", code)

    return code + comment

# Setup paths to ensure we can import core modules
current_dir = pathlib.Path(__file__).resolve().parent
project_root = current_dir.parent if (current_dir / "core").exists() else current_dir
sys.path.insert(0, str(project_root))

try:
    import readline
except ImportError:
    readline = None

try:
    from backend.core.main import UniLabCore, BackendConfig
except ImportError:
    try:
        from core.main import UniLabCore, BackendConfig
    except ImportError as e:
        print(f"Error: Could not import UniLabCore. Ensure you are in the project root.")
        print(f"Details: {e}")
        print("Please ensure all requirements are installed: pip install -r backend/requirements.txt")
        sys.exit(1)

async def run_UniLab_script(script_path: str, engine_name: str = "transpiler"):
    path = pathlib.Path(script_path)
    if not path.exists():
        print(f"Error: Script '{script_path}' not found.")
        return

    workspace_root = pathlib.Path("./test_runs")
    workspace_root.mkdir(exist_ok=True)
    
    cfg = BackendConfig(
        workspace_root=workspace_root,
        use_docker=False
    )
    
    core = UniLabCore(cfg)
    await core.start()

    try:
        session = await core.create_session(username="script_user", engine=engine_name)
        code = path.read_text(encoding="utf-8")
        
        print(f"\n{'='*20} Executing: {path.name} {'='*20}")
        result = await core.run_code(session.session_id, code)
        
        print(f"\nStatus: {'SUCCESS' if result.success else 'FAILED'}")
        print(f"Duration: {result.duration_s:.4f}s")
        
        if result.stdout:
            print("\n[STDOUT]")
            print(result.stdout.strip())
            
        if result.stderr:
            print("\n[STDERR]")
            print(result.stderr.strip())
            
        if result.variables_snapshot:
            print("\n[Variables]")
            for name, info in result.variables_snapshot.items():
                shape_str = f" {info['shape']}" if info['shape'] else ""
                print(f"  {name:14} : {info['dtype']:10}{shape_str:12} = {info['preview']}")
        
        print(f"\n{'='*60}\n")
                
    except Exception as e:
        print(f"An error occurred during execution: {e}")
    finally:
        await core.stop()

async def run_console(engine_name: str = "transpiler", command: Optional[str] = None):
    workspace_root = pathlib.Path("./console_workspaces")
    workspace_root.mkdir(exist_ok=True)
    
    history_file = workspace_root / ".unilab_history"
    if not command and readline:
        try:
            if history_file.exists():
                readline.read_history_file(str(history_file))
            readline.set_history_length(1000)
        except Exception as e:
            print(f"Warning: Could not load history file: {e}")

    cfg = BackendConfig(
        workspace_root=workspace_root,
        use_docker=False
    )
    
    core = UniLabCore(cfg)
    await core.start()
    
    try:
        session = await core.create_session(username="console_user", engine=engine_name)
        
        is_tty = sys.stdin.isatty() and not command
        if is_tty:
            print("\n" + "="*60)
            print(f" 🧪 UniLab Interactive Console (TrueColor Enabled)")
            print(" Type 'exit' or 'quit' to close.")
            print(" Type 'list_libraries();' to explore toolboxes.")
            print("="*60 + "\n")
        
        while True:
            try:
                if command:
                    line = command
                else:
                    if is_tty:
                        line = input(">> ")
                    else:
                        line = sys.stdin.readline()
                        if not line:
                            break
                
                if line.strip().lower() in ('exit', 'quit', 'exit;', 'quit;'):
                    break
                
                if not line.strip():
                    if command: break
                    continue

                # Handle multi-line blocks
                first_word = line.strip().split()[0].lower() if line.strip().split() else ""
                if is_tty and (line.strip().endswith('...') or first_word in ('if', 'for', 'while', 'function', 'switch', 'try')):
                    buffer = [line.rstrip('.').rstrip()]
                    open_blocks = 1 if first_word in ('if', 'for', 'while', 'function', 'switch', 'try') else 0

                    while open_blocks > 0 or line.strip().endswith('...'):
                        sub_line = input("   ")
                        if not sub_line.strip() and not line.strip().endswith('...'):
                            break

                        buffer.append(sub_line)
                        line = sub_line

                        sub_first = sub_line.strip().split()[0].lower() if sub_line.strip().split() else ""
                        if sub_first in ('if', 'for', 'while', 'function', 'switch', 'try'):
                            open_blocks += 1
                        elif sub_first == 'end' or sub_line.strip().endswith('end'):
                            open_blocks -= 1

                    line = "\n".join(buffer)

                if line.strip().lower() in ('clc', 'clc;'):
                    os.system('cls' if os.name == 'nt' else 'clear')
                    if command: break
                    continue

                if is_tty:
                    sys.stdout.write(f"\033[F\033[K>> {highlight_syntax(line)}\n")
                    sys.stdout.flush()

                if line.strip().lower().startswith('export'):
                    parts = line.strip().rstrip(';').split()
                    fmt = 'json'
                    if len(parts) > 1:
                        fmt = parts[1].lower()
                    try:
                        path = await core.export_workspace(session.session_id, format=fmt)
                        print(f"Workspace exported to: {path}")
                    except Exception as e:
                        print(f"Export failed: {e}")
                    if command: break
                    continue

                if line.strip().startswith('!'):
                    os.system(line.strip()[1:])
                    if command: break
                    continue

                parts = line.strip().split()
                if parts:
                    cmd = parts[0].lower()
                    if cmd in ('ls', 'dir', 'pwd', 'mkdir', 'rm', 'cp', 'mv', 'cd', 'git', 'python', 'pip', 'npm', 'cat'):
                        if cmd == 'cd':
                            try:
                                if len(parts) > 1:
                                    os.chdir(parts[1])
                                else:
                                    print(os.getcwd())
                            except Exception as e:
                                print(f"Error: {e}")
                        else:
                            os.system(line.strip())
                
                        if command: break
                        continue

                is_whos = line.strip().lower() in ('whos', 'whos;')
                result = await core.run_code(session.session_id, line)
                
                if result.stdout:
                    print(result.stdout.rstrip())
                
                if result.stderr:
                    print(f"Error: {result.stderr.rstrip()}", file=sys.stderr)
                
                if is_whos:
                    if result.variables_snapshot:
                        print("\nName           Size            Class")
                        print("-" * 45)
                        for name, info in result.variables_snapshot.items():
                            shape_str = str(info['shape']) if info['shape'] else "1x1"
                            dtype = info['dtype']
                            print(f"{name:14} {shape_str:15} {dtype}")
                        print("")
                
                if command:
                    break

            except EOFError:
                break
            except KeyboardInterrupt:
                if command: break
                print("\nUse 'exit' to quit.")
            except Exception as e:
                print(f"Error executing command: {e}")
                if command: break

    finally:
        if is_tty and readline:
            try:
                readline.write_history_file(str(history_file))
            except Exception as e:
                print(f"Warning: Could not load history file: {e}")
        await core.stop()
        if is_tty:
            print("\nConsole closed.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="UniLab: Scientific Simulation & Modeling Platform")
    subparsers = parser.add_subparsers(dest="command", help="Commands")

    run_parser = subparsers.add_parser("run", help="Run a UniLab (.m) script")
    run_parser.add_argument("script", help="Path to the script file")
    run_parser.add_argument("--engine", choices=["transpiler", "octave"], default="transpiler", 
                           help="Execution engine (default: transpiler)")

    console_parser = subparsers.add_parser("console", help="Launch interactive console")
    console_parser.add_argument("--engine", choices=["transpiler", "octave"], default="transpiler", 
                               help="Execution engine (default: transpiler)")
    console_parser.add_argument("cmd_args", nargs=argparse.REMAINDER, help="Terminal command to execute (optional)")

    if len(sys.argv) == 1:
        args = parser.parse_args(["console"])
    else:
        args = parser.parse_args()

    try:
        if args.command == "run":
            asyncio.run(run_UniLab_script(args.script, args.engine))
        elif args.command == "console":
            cmd_str = " ".join(args.cmd_args) if args.cmd_args else None
            asyncio.run(run_console(args.engine, cmd_str))
        else:
            parser.print_help()
    except KeyboardInterrupt:
        print("\nOperation cancelled.")
