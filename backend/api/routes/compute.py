from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from backend.api.dependencies import get_core
from backend.core.main import UniLabCore

router = APIRouter(prefix="/compute", tags=["compute"])

class CreateSessionRequest(BaseModel):
    username: Optional[str] = None
    engine: str = "octave"

class RunCodeRequest(BaseModel):
    session_id: str
    code: str
    timeout: Optional[float] = 30.0

@router.post("/sessions")
async def create_session(req: CreateSessionRequest, core: UniLabCore = Depends(get_core)):
    session = await core.create_session(username=req.username, engine=req.engine)
    return {
        "session_id": session.session_id,
        "workspace_path": str(session.workspace_path),
        "engine": session.engine
    }

@router.post("/run")
async def run_code(req: RunCodeRequest, core: UniLabCore = Depends(get_core)):
    try:
        result = await core.run_code(req.session_id, req.code, timeout=req.timeout)
        return result
    except KeyError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/sessions/{session_id}/files")
async def list_files(session_id: str, path: Optional[str] = None, core: UniLabCore = Depends(get_core)):
    try:
        return await core.list_files(session_id, path)
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")

@router.post("/sessions/{session_id}/export")
async def export_workspace(session_id: str, format: str = "json", filename: Optional[str] = None, core: UniLabCore = Depends(get_core)):
    try:
        path = await core.export_workspace(session_id, format, filename)
        return {"path": path}
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
