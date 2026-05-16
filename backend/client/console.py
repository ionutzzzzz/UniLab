import asyncio
import os
import sys
import pathlib
import argparse
from typing import Optional

try:
    import readline
except ImportError:
    readline = None

PROJECT_ROOT = pathlib.Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

if 'backend' not in os.listdir('.') and 'backend' in os.listdir('..'):
    sys.path.insert(0, os.path.abspath('..'))

try:
    from backend.core.main import UniLabCore, BackendConfig
except ImportError as e:
    if "No module named 'backend'" in str(e):
        try:
            from core.main import UniLabCore, BackendConfig
        except ImportError as e2:
            print(f"Error: Could not import UniLabCore. Ensure you are in the project root.")
            print(f"Original error: {e}")
            print(f"Fallback error: {e2}")
            sys.exit(1)
    else:
        print(f"Error: Failed to import UniLabCore due to missing dependency: {e}")
        print("Please ensure all requirements are installed: pip install -r backend/requirements.txt")
        sys.exit(1)

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
            print(f" UniLab Interactive Console")
            print(" Type 'exit' or 'quit' to close.")
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

                if is_tty and (line.strip().endswith('...') or line.strip() in ('if', 'for', 'while', 'function', 'switch', 'try')):
                    buffer = [line.rstrip('.').rstrip()]
                    while True:
                        sub_line = input("   ")
                        if not sub_line.strip():
                            break
                        buffer.append(sub_line)
                        if sub_line.strip() == 'end':
                            break
                    line = "\n".join(buffer)

                if line.strip().lower() in ('clc', 'clc;'):
                    os.system('cls' if os.name == 'nt' else 'clear')
                    if command: break
                    continue

                if line.strip().startswith('!'):
                    os.system(line.strip()[1:])
                    if command: break
                    continue

                parts = line.strip().split()
                cmd = parts[0].lower()
                # Added 'cd' to the list and fixed the nested if
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

                is_whos = line.strip().lower() == 'whos' or line.strip().lower() == 'whos;'
                
                result = await core.run_code(session.session_id, line)
                
                if result.stdout:
                    print(result.stdout.rstrip())
                
                if result.stderr:
                    print(f"Error: {result.stderr.rstrip()}", file=sys.stderr)
                
                if is_whos:
                    if result.variables_snapshot:
                        print("\nName           Size            Bytes  Class")
                        print("="*45)
                        for name, info in result.variables_snapshot.items():
                            shape_str = str(info['shape']) if info['shape'] else "1x1"
                            dtype = info['dtype']
                            print(f"{name:14} {shape_str:15} {dtype}")
                        print("")
                
                if result.plots:
                    for p in result.plots:
                        print(f"Plot generated: {p}")
                
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
                print(f"Warning: Could not save history file: {e}")
        await core.stop()
        if is_tty:
            print("\nConsole closed.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="UniLab Interactive Console")
    parser.add_argument("--engine", choices=["transpiler", "octave"], default="transpiler", 
                        help="Execution engine to use (default: transpiler)")
    parser.add_argument("command", nargs=argparse.REMAINDER, help="Terminal command to execute (optional)")
    args = parser.parse_args()
    
    cmd_str = " ".join(args.command) if args.command else None
    
    try:
        asyncio.run(run_console(args.engine, cmd_str))
    except KeyboardInterrupt:
        pass
