"""File operations endpoints."""

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, BackgroundTasks
from typing import Optional, List
import aiofiles
import os
from pathlib import Path
from backend.api.dependencies import get_core
from backend.api.schemas import (
    FileInfo, FileListResponse, FileContentResponse, RunScriptRequest, CreateFileRequest
)
from backend.core.main import UniLabCore

router = APIRouter(prefix="/api/v1/sessions", tags=["files"])


@router.get("/{session_id}/files", response_model=FileListResponse)
async def list_workspace_files(
    session_id: str,
    path: Optional[str] = None,
    recursive: bool = False,
    core: UniLabCore = Depends(get_core)
):
    """List files in workspace."""
    try:
        files_info = await core.list_files(session_id, path or "")
        
        file_list = []
        if files_info and isinstance(files_info, list):
            for f in files_info:
                if isinstance(f, dict):
                    file_list.append(FileInfo(
                        name=f.get('name', 'unknown'),
                        path=f.get('path', ''),
                        size=f.get('size', 0),
                        is_directory=f.get('is_directory', False)
                    ))
        
        return FileListResponse(
            files=file_list,
            total=len(file_list),
            path=path or ""
        )
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def is_temporary_file(filename: str, parent_path: Path) -> bool:
    """Check if a file is a temporary artifact that should be cleaned up after download."""
    # Check if it's in a known temp subdirectory
    if parent_path.name in ['plots', 'exports']:
        return True
    
    # Check for specific temporary file patterns in the root or elsewhere
    if filename.startswith('graph_') and (filename.endswith('.png') or filename.endswith('.json')):
        return True
    if filename.startswith('workspace_export_'):
        return True
    
    return False

async def cleanup_temp_file(path: Path, logger):
    """Background task to remove temporary files."""
    try:
        if path.exists():
            path.unlink()
            logger.info(f"Cleaned up temporary file: {path}")
    except Exception as e:
        logger.error(f"Failed to cleanup {path}: {e}")

@router.get("/{session_id}/files/{file_path:path}", response_model=FileContentResponse)
async def get_file_content(
    session_id: str,
    file_path: str,
    background_tasks: BackgroundTasks,
    core: UniLabCore = Depends(get_core)
):
    """Get content of a file."""
    import logging
    logger = logging.getLogger("api.files")
    try:
        content = await core.read_file(session_id, file_path)
        
        session = await core.get_session(session_id)
        if session:
            filename = os.path.basename(file_path)
            full_path = session.workspace_path / file_path
            if is_temporary_file(filename, full_path.parent):
                background_tasks.add_task(cleanup_temp_file, full_path, logger)

        file_size = len(content.encode('utf-8')) if isinstance(content, str) else len(content)
        
        return FileContentResponse(
            name=Path(file_path).name,
            path=file_path,
            content=content if isinstance(content, str) else str(content),
            size=file_size,
            is_text=True
        )
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="File not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{session_id}/files/upload")
async def upload_file(
    session_id: str,
    file: UploadFile = File(...),
    overwrite: bool = Form(False),
    core: UniLabCore = Depends(get_core)
):
    """Upload a file to workspace."""
    try:
        # Get session workspace
        session = await core.get_session(session_id)
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")
        
        workspace_path = session.workspace_path
        file_path = workspace_path / file.filename
        
        # Check if file exists
        if file_path.exists() and not overwrite:
            raise HTTPException(
                status_code=409,
                detail="File already exists. Set overwrite=true to replace."
            )
        
        # Write file
        content = await file.read()
        await core.write_file(session_id, file.filename, content.decode('utf-8'))
        
        return {
            "status": "success",
            "filename": file.filename,
            "size": len(content),
            "path": str(file_path)
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{session_id}/files/create")
async def create_file(
    session_id: str,
    req: CreateFileRequest,
    core: UniLabCore = Depends(get_core)
):
    """Create a new file in workspace."""
    try:
        session = await core.get_session(session_id)
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")
        
        file_path = session.workspace_path / req.filename
        
        if file_path.exists() and not req.overwrite:
            raise HTTPException(
                status_code=409,
                detail="File already exists. Set overwrite=true to replace."
            )
        
        await core.write_file(session_id, req.filename, req.content)
        
        return {
            "status": "success",
            "filename": req.filename,
            "size": len(req.content.encode('utf-8')),
            "path": str(file_path)
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{session_id}/files/delete")
async def delete_file(
    session_id: str,
    filepath: str,
    core: UniLabCore = Depends(get_core)
):
    """Delete a file from workspace."""
    try:
        session = await core.get_session(session_id)
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")
        
        file_path = session.workspace_path / filepath
        
        if not file_path.exists():
            raise HTTPException(status_code=404, detail="File not found")
        
        file_path.unlink()
        
        return {
            "status": "success",
            "filename": filepath,
            "deleted": True
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{session_id}/scripts/run")
async def run_script(
    session_id: str,
    req: RunScriptRequest,
    core: UniLabCore = Depends(get_core)
):
    """Run a .m script file."""
    try:
        # Read the script file
        script_content = await core.read_file(session_id, req.filename)
        
        # Add parameters to workspace if provided
        if req.parameters:
            param_code = "\n".join([
                f"{k} = {repr(v)};" for k, v in req.parameters.items()
            ])
            script_content = param_code + "\n" + script_content
        
        # Execute the script
        result = await core.run_code(session_id, script_content, timeout=req.timeout)
        
        variables_snapshot = {}
        if result.variables_snapshot:
            for name, info in result.variables_snapshot.items():
                variables_snapshot[name] = {
                    "name": name,
                    "dtype": info.get('dtype', 'unknown'),
                    "shape": info.get('shape'),
                    "preview": str(info.get('preview', ''))[:200]
                }
        
        return {
            "status": "success",
            "script": req.filename,
            "success": result.success,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "duration_s": result.duration_s,
            "variables": variables_snapshot
        }
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Script file not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{session_id}/files/{file_path:path}/download")
async def download_file(
    session_id: str,
    file_path: str,
    background_tasks: BackgroundTasks,
    core: UniLabCore = Depends(get_core)
):
    """Download a file from workspace."""
    from fastapi import Response
    import logging
    import os
    from pathlib import Path
    logger = logging.getLogger("api.files")
    
    try:
        session = await core.get_session(session_id)
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")
        
        # Security: prevent directory traversal
        filename = os.path.basename(file_path)
        workspace_base = session.workspace_path.resolve()
        full_path = (workspace_base / file_path).resolve()
        
        # Ensure the file is within the workspace
        if not str(full_path).startswith(str(workspace_base)):
             # Try standard locations if not found in root
             alt_found = False
             for sub in ['plots', 'exports']:
                 alt_path = workspace_base / sub / filename
                 if alt_path.exists():
                     full_path = alt_path
                     alt_found = True
                     break
             if not alt_found:
                raise HTTPException(status_code=403, detail="Forbidden")

        if not full_path.exists():
            # Try subdirectories if not found exactly as requested
            for sub in ['plots', 'exports']:
                alt_path = workspace_base / sub / filename
                if alt_path.exists():
                    full_path = alt_path
                    break
        
        if not full_path.exists():
            raise HTTPException(status_code=404, detail=f"File not found: {filename}")
        
        is_temp = is_temporary_file(filename, full_path.parent)
        
        # Read file directly and return binary Response
        try:
            content = full_path.read_bytes()
            media_type = "image/png" if filename.endswith(".png") else "application/octet-stream"
            
            # If it's a temporary file, schedule cleanup
            if is_temp:
                background_tasks.add_task(cleanup_temp_file, full_path, logger)
                
            return Response(content=content, media_type=media_type)
        except Exception as e:
            logger.error(f"Failed to read file for download: {e}")
            raise HTTPException(status_code=500, detail=f"Read error: {str(e)}")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Download Error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

