from fastapi import FastAPI, Depends, HTTPException, BackgroundTasks
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import pathlib
import os

from backend.core.unilab_core import UniLabCore
from backend.core.models import BackendConfig
from backend.api.dependencies import get_core

app = FastAPI(
    title="UniLab API",
    description="Scientific Simulation & Modeling Platform API",
    version="1.1.0"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request Models
class CreateSessionRequest(BaseModel):
    username: str = "default_user"
    engine: str = "transpiler"

class ExecuteCodeRequest(BaseModel):
    session_id: str
    code: str
    timeout: float = 300.0
    filename: Optional[str] = None

class WriteFileRequest(BaseModel):
    session_id: str
    path: str
    content: str

# Endpoints
@app.get("/")
async def root():
    return {"message": "UniLab API is running", "version": "1.1.0"}

@app.post("/api/v1/sessions")
@app.post("/compute/sessions")
async def create_session(req: CreateSessionRequest, core: UniLabCore = Depends(get_core)):
    try:
        session = await core.create_session(username=req.username, engine=req.engine)
        return {
            "session_id": session.session_id,
            "username": session.username,
            "engine": session.engine,
            "workspace": str(session.workspace_path)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/sessions/{session_id}/execute")
@app.post("/compute/run")
async def execute_code(req: ExecuteCodeRequest, core: UniLabCore = Depends(get_core)):
    try:
        result = await core.run_code(
            session_id=req.session_id,
            code=req.code,
            timeout=req.timeout,
            filename=req.filename
        )
        return result
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/sessions/{session_id}/files")
async def list_files(session_id: str, core: UniLabCore = Depends(get_core)):
    try:
        return await core.list_files(session_id)
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/sessions/{session_id}/complete")
async def complete(session_id: str, text: str, line: str = "", core: UniLabCore = Depends(get_core)):
    try:
        suggestions = await core.complete(session_id, text, line)
        return {"suggestions": suggestions}
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")

# Serve static files for the web terminal
web_dir = pathlib.Path(__file__).parent.parent / "web"
if web_dir.exists():
    app.mount("/terminal", StaticFiles(directory=str(web_dir), html=True), name="terminal")

from fastapi.responses import FileResponse

@app.get("/api/v1/sessions/{session_id}/files/{filename}/download")
async def download_file(session_id: str, filename: str, core: UniLabCore = Depends(get_core)):
    try:
        session = await core.get_session(session_id)
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")
        
        # Security check: ensure file is within workspace
        file_path = (session.workspace_path / filename).resolve()
        if not str(file_path).startswith(str(session.workspace_path.resolve())):
            raise HTTPException(status_code=403, detail="Access denied")
            
        if not file_path.exists():
            # Check in plots directory
            plot_path = (session.workspace_path / "plots" / filename).resolve()
            if plot_path.exists():
                file_path = plot_path
            else:
                raise HTTPException(status_code=404, detail="File not found")
                
        return FileResponse(path=str(file_path))
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.on_event("startup")
async def startup_event():
    core = get_core()
    await core.start()

@app.on_event("shutdown")
async def shutdown_event():
    core = get_core()
    await core.stop()
