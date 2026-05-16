import asyncio
import argparse
import pathlib
import sys
import os
from typing import Optional

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

async def run_console(engine_name: str = "transpiler"):
    workspace_root = pathlib.Path("./console_workspaces")
    workspace_root.mkdir(exist_ok=True)
    
    history_file = workspace_root / ".unilab_history"
    if readline:
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
        
        print("\n" + "="*60)
        print(f" 🧪 UniLab Interactive Console (TrueColor Enabled)")
        print(" Type 'exit' or 'quit' to close.")
        print(" Type 'list_libraries();' to explore toolboxes.")
        print("="*60 + "\n")
        
        while True:
            try:
                line = input(">> ")
                
                if line.strip().lower() in ('exit', 'quit', 'exit;', 'quit;'):
                    break
                
                if not line.strip():
                    continue

                # Handle multi-line blocks
                if line.strip().endswith('...') or line.strip() in ('if', 'for', 'while', 'function', 'switch', 'try'):
                    buffer = [line.rstrip('.').rstrip()]
                    while True:
                        sub_line = input("   ")
                        if not sub_line.strip():
                            break
                        buffer.append(sub_line)
                        if sub_line.strip() == 'end':
                            break
                    line = "\n".join(buffer)

                # Built-in terminal commands
                if line.strip().lower() in ('clc', 'clc;'):
                    os.system('cls' if os.name == 'nt' else 'clear')
                    continue

                if line.strip().startswith('!'):
                    os.system(line.strip()[1:])
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

            except EOFError:
                break
            except KeyboardInterrupt:
                print("\nUse 'exit' to quit.")
            except Exception as e:
                print(f"Error executing command: {e}")

    finally:
        if readline:
            try:
                readline.write_history_file(str(history_file))
            except Exception as e:
                print(f"Warning: Could not save history file: {e}")
        await core.stop()
        print("\nConsole closed.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="UniLab: Scientific Simulation & Modeling Platform")
    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # Run script command
    run_parser = subparsers.add_parser("run", help="Run a UniLab (.m) script")
    run_parser.add_argument("script", help="Path to the script file")
    run_parser.add_argument("--engine", choices=["transpiler", "octave"], default="transpiler", 
                           help="Execution engine (default: transpiler)")

    # Interactive console command
    console_parser = subparsers.add_parser("console", help="Launch interactive console")
    console_parser.add_argument("--engine", choices=["transpiler", "octave"], default="transpiler", 
                               help="Execution engine (default: transpiler)")

    # Default to console if no arguments
    if len(sys.argv) == 1:
        args = parser.parse_args(["console"])
    else:
        args = parser.parse_args()

    try:
        if args.command == "run":
            asyncio.run(run_UniLab_script(args.script, args.engine))
        elif args.command == "console":
            asyncio.run(run_console(args.engine))
        else:
            parser.print_help()
    except KeyboardInterrupt:
        print("\nOperation cancelled.")
