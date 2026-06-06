"""Workspace management endpoints."""

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from typing import Optional, List
from backend.api.dependencies import get_core
from backend.api.schemas import (
    WorkspaceResponse, VariableInfo, SetVariableRequest, ClearWorkspaceRequest
)
from backend.core.unilab_core import UniLabCore

router = APIRouter(prefix="/api/v1/sessions", tags=["workspace"])


@router.websocket("/{session_id}/ws")
async def workspace_ws(
    websocket: WebSocket,
    session_id: str,
    core: UniLabCore = Depends(get_core)
):
    """WebSocket for real-time workspace updates."""
    await websocket.accept()
    
    # Listener function to be called by UniLabCore event pump
    async def workspace_listener(event):
        if event.get("type") == "workspace_update" and event.get("session_id") == session_id:
            try:
                # MATLAB-style workspace update format
                variables = event.get("variables", {})
                
                # Transform to expected format if needed (matching WorkspaceResponse)
                formatted_vars = {}
                for name, info in variables.items():
                    formatted_vars[name] = {
                        "name": name,
                        "dtype": info.get('dtype', 'unknown'),
                        "shape": info.get('shape'),
                        "preview": str(info.get('preview', ''))[:200],
                        "size_bytes": info.get('bytes', 0),
                        "min": info.get('min'),
                        "max": info.get('max'),
                        "mean": info.get('mean'),
                        "median": info.get('median'),
                        "sum": info.get('sum'),
                        "std": info.get('std'),
                        "variance": info.get('variance'),
                        "range": info.get('range'),
                        "mode": info.get('mode'),
                    }
                
                await websocket.send_json({
                    "event": "workspace_updated",
                    "session_id": session_id,
                    "variables": formatted_vars
                })
            except Exception:
                # If sending fails (e.g. connection closed), we don't need to do anything here
                # the finally block or a future message will handle cleanup if needed.
                pass

    # Register listener in core
    hook_name = f"ws_listener_{session_id}"
    if hook_name not in core._plugin_hooks:
        core._plugin_hooks[hook_name] = []
    core._plugin_hooks[hook_name].append(workspace_listener)
    
    try:
        # Keep connection open until client disconnects
        while True:
            # We can also receive commands here if needed in the future
            data = await websocket.receive_text()
    except WebSocketDisconnect:
        pass
    finally:
        # Cleanup hook
        if hook_name in core._plugin_hooks:
            if workspace_listener in core._plugin_hooks[hook_name]:
                core._plugin_hooks[hook_name].remove(workspace_listener)
            if not core._plugin_hooks[hook_name]:
                del core._plugin_hooks[hook_name]


@router.get("/{session_id}/workspace", response_model=WorkspaceResponse)
async def get_workspace(
    session_id: str,
    core: UniLabCore = Depends(get_core)
):
    """Get all variables in the workspace."""
    try:
        # Execute 'whos;' to get all variables
        result = await core.run_code(session_id, "whos;", timeout=5.0)
        
        variables = {}
        total_size = 0
        
        if result.variables_snapshot:
            for name, info in result.variables_snapshot.items():
                var_info = {
                    "name": name,
                    "dtype": info.get('dtype', 'unknown'),
                    "shape": info.get('shape'),
                    "preview": str(info.get('preview', ''))[:200],
                    "size_bytes": estimate_size(info.get('preview')),
                    "min": info.get('min'),
                    "max": info.get('max'),
                    "mean": info.get('mean'),
                    "median": info.get('median'),
                    "sum": info.get('sum'),
                    "std": info.get('std'),
                    "variance": info.get('variance'),
                    "range": info.get('range'),
                    "mode": info.get('mode'),
                }
                variables[name] = var_info
                total_size += var_info.get('size_bytes', 0)
        
        return WorkspaceResponse(
            variables=variables,
            total_size_bytes=total_size,
            variable_count=len(variables)
        )
    except KeyError:
        raise HTTPException(status_code=404, detail=f"Session {session_id} not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{session_id}/vars/{var_name}", response_model=VariableInfo)
async def get_variable(
    session_id: str,
    var_name: str,
    core: UniLabCore = Depends(get_core)
):
    """Get a specific variable from workspace."""
    try:
        # Execute code to get the variable
        result = await core.run_code(session_id, f"disp({var_name});", timeout=5.0)
        
        if result.variables_snapshot and var_name in result.variables_snapshot:
            info = result.variables_snapshot[var_name]
            return VariableInfo(
                name=var_name,
                dtype=info.get('dtype', 'unknown'),
                shape=info.get('shape'),
                preview=str(info.get('preview', ''))[:1000],
                min=info.get('min'),
                max=info.get('max'),
                mean=info.get('mean'),
                median=info.get('median'),
                sum=info.get('sum'),
                std=info.get('std'),
                variance=info.get('variance'),
                range=info.get('range'),
                mode=info.get('mode'),
            )
        else:
            raise HTTPException(status_code=404, detail=f"Variable '{var_name}' not found in workspace")
    
    except HTTPException:
        raise
    except KeyError:
        raise HTTPException(status_code=404, detail=f"Session {session_id} not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{session_id}/vars/{var_name}")
async def set_variable(
    session_id: str,
    var_name: str,
    req: SetVariableRequest,
    core: UniLabCore = Depends(get_core)
):
    """Set a variable in the workspace."""
    try:
        # Create assignment code
        import json
        
        # Handle different data types
        if isinstance(req.value, (int, float)):
            code = f"{var_name} = {req.value};"
        elif isinstance(req.value, str):
            code = f"{var_name} = '{req.value}';"
        elif isinstance(req.value, list):
            # Convert to array notation
            arr_str = str(req.value).replace('[', '[').replace(']', ']')
            code = f"{var_name} = {arr_str};"
        else:
            code = f"{var_name} = {req.value};"
        
        result = await core.run_code(session_id, code, timeout=5.0)
        
        if result.success:
            return {"status": "success", "variable": var_name}
        else:
            raise HTTPException(status_code=400, detail=f"Failed to set variable '{var_name}': {result.stderr}")
    
    except KeyError:
        raise HTTPException(status_code=404, detail=f"Session {session_id} not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{session_id}/vars/{var_name}")
async def delete_variable(
    session_id: str,
    var_name: str,
    core: UniLabCore = Depends(get_core)
):
    """Clear a specific variable."""
    try:
        result = await core.run_code(session_id, f"clear {var_name};", timeout=5.0)
        
        return {"status": "success", "variable": var_name, "cleared": result.success}
    except KeyError:
        raise HTTPException(status_code=404, detail=f"Session {session_id} not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{session_id}/clear")
async def clear_workspace(
    session_id: str,
    req: Optional[ClearWorkspaceRequest] = None,
    core: UniLabCore = Depends(get_core)
):
    """Clear all variables or matching pattern."""
    try:
        if not req or not req.pattern:
            code = "clear all;"
        else:
            # Clear with pattern
            code = f"clear {req.pattern};"
        
        result = await core.run_code(session_id, code, timeout=5.0)
        
        return {
            "status": "success",
            "cleared": result.success,
            "message": "Workspace cleared"
        }
    except KeyError:
        raise HTTPException(status_code=404, detail=f"Session {session_id} not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{session_id}/vars-detailed")
async def get_variables_detailed(
    session_id: str,
    core: UniLabCore = Depends(get_core)
):
    """Get detailed information about all variables."""
    try:
        # Get workspace snapshot
        result = await core.run_code(session_id, "whos;", timeout=5.0)
        
        variables_detail = []
        
        if result.variables_snapshot:
            for name, info in result.variables_snapshot.items():
                variables_detail.append({
                    "name": name,
                    "dtype": info.get('dtype', 'unknown'),
                    "shape": info.get('shape'),
                    "preview": str(info.get('preview', ''))[:500],
                    "size_bytes": estimate_size(info.get('preview')),
                    "min": info.get('min'),
                    "max": info.get('max'),
                    "mean": info.get('mean'),
                    "median": info.get('median'),
                    "sum": info.get('sum'),
                    "std": info.get('std'),
                    "variance": info.get('variance'),
                    "range": info.get('range'),
                    "mode": info.get('mode'),
                })
        
        return {
            "variables": variables_detail,
            "total": len(variables_detail),
            "timestamp": result.duration_s
        }
    except KeyError:
        raise HTTPException(status_code=404, detail=f"Session {session_id} not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def estimate_size(obj):
    """Estimate size of an object in bytes."""
    import sys
    try:
        return sys.getsizeof(obj)
    except:
        return 0
