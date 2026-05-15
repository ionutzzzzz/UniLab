import asyncio
import argparse
import pathlib
import sys
import os

# Add the current directory to sys.path to ensure 'backend' is importable
sys.path.insert(0, os.getcwd())

from core.main import UniLabCore, BackendConfig

async def run_matlab_script(script_path):
    path = pathlib.Path(script_path)
    if not path.exists():
        print(f"Error: Script '{script_path}' not found.")
        return

    # Setup UniLab Core with a temporary workspace
    workspace_root = pathlib.Path("./test_runs")
    workspace_root.mkdir(exist_ok=True)
    
    cfg = BackendConfig(
        workspace_root=workspace_root,
        use_docker=False
    )
    
    core = UniLabCore(cfg)
    await core.start()

    try:
        # Create a session using the custom transpiler engine
        session = await core.create_session(username="tester", engine="transpiler")
        
        # Read the script content
        code = path.read_text(encoding="utf-8")
        
        print(f"\n{'='*20} Executing: {path.name} {'='*20}")
        
        # Execute the code
        result = await core.run_code(session.session_id, code)
        
        # Output results
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
                print(f"  {name:10} : {info['dtype']:10}{shape_str:12} = {info['preview']}")
                
        if result.plots:
            print("\n[Plots Generated]")
            for p in result.plots:
                # Make path relative to current dir for easier reading
                try:
                    rel_p = pathlib.Path(p).relative_to(os.getcwd())
                except ValueError:
                    rel_p = p
                print(f"  - {rel_p}")
        
        print(f"\n{'='*60}\n")
                
    except Exception as e:
        print(f"An error occurred during execution: {e}")
    finally:
        await core.stop()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="UniLab CLI: Run a MATLAB script via the Transpiler engine.")
    parser.add_argument("script", help="Path to the .m script to execute")
    
    if len(sys.argv) < 2:
        parser.print_help()
        sys.exit(1)
        
    args = parser.parse_args()
    
    try:
        asyncio.run(run_matlab_script(args.script))
    except KeyboardInterrupt:
        print("\nExecution interrupted by user.")
