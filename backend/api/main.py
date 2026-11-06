from fastapi import FastAPI, Depends, HTTPException, BackgroundTasks, Query
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import pathlib
import os
import time

from backend.core.unilab_core import UniLabCore
from backend.core.models import BackendConfig
from backend.api.dependencies import get_core
from backend.core.transpiler_core import UniLabTranspiler

START_TIME = time.time()
EXECUTION_COUNT = 0

app = FastAPI(
    title="UniLab API",
    description="Scientific Simulation & Modeling Platform API",
    version="1.1.0",
    docs_url="/api/docs",
    openapi_url="/api/openapi.json"
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
    session_id: Optional[str] = None
    code: str
    timeout: float = 300.0
    filename: Optional[str] = None

class BatchCommand(BaseModel):
    code: str

class BatchExecuteRequest(BaseModel):
    commands: List[BatchCommand]
    stop_on_error: bool = False

class TranspileRequest(BaseModel):
    code: str

class SetVarRequest(BaseModel):
    value: Any

class ExportWorkspaceRequest(BaseModel):
    format: str = "json"

class CreateFileRequest(BaseModel):
    filename: str
    content: str
    overwrite: bool = True

class RunScriptRequest(BaseModel):
    filename: str

class SearchFunctionRequest(BaseModel):
    query: str

# In-memory functions & libraries catalog for metadata endpoints
FUNCTIONS_CATALOG = [
    {"name": "sin", "category": "math", "description": "Sine of argument in radians"},
    {"name": "cos", "category": "math", "description": "Cosine of argument in radians"},
    {"name": "tan", "category": "math", "description": "Tangent of argument in radians"},
    {"name": "asin", "category": "math", "description": "Inverse sine in radians"},
    {"name": "acos", "category": "math", "description": "Inverse cosine in radians"},
    {"name": "atan", "category": "math", "description": "Inverse tangent in radians"},
    {"name": "exp", "category": "math", "description": "Exponential function"},
    {"name": "log", "category": "math", "description": "Natural logarithm"},
    {"name": "log10", "category": "math", "description": "Common logarithm (base 10)"},
    {"name": "sqrt", "category": "math", "description": "Square root"},
    {"name": "abs", "category": "math", "description": "Absolute value and complex magnitude"},
    {"name": "zeros", "category": "matrix", "description": "Create array of all zeros"},
    {"name": "ones", "category": "matrix", "description": "Create array of all ones"},
    {"name": "eye", "category": "matrix", "description": "Identity matrix"},
    {"name": "linspace", "category": "matrix", "description": "Generate linearly spaced vector"},
    {"name": "inv", "category": "linear_algebra", "description": "Matrix inverse"},
    {"name": "det", "category": "linear_algebra", "description": "Matrix determinant"},
    {"name": "eig", "category": "linear_algebra", "description": "Eigenvalues and eigenvectors"},
    {"name": "svd", "category": "linear_algebra", "description": "Singular value decomposition"},
    {"name": "norm", "category": "linear_algebra", "description": "Matrix or vector norm"},
    {"name": "plot", "category": "graphics", "description": "2-D line plot"},
    {"name": "subplot", "category": "graphics", "description": "Create axes in tiled positions"},
    {"name": "scatter", "category": "graphics", "description": "Scatter plot"},
    {"name": "fft", "category": "signal", "description": "Fast Fourier transform"},
    {"name": "ifft", "category": "signal", "description": "Inverse Fast Fourier transform"},
    {"name": "ode45", "category": "simulation", "description": "Solve non-stiff differential equations"},
]

LIBRARIES_CATALOG = [
    {
        "name": "math",
        "description": "Standard mathematical operations and elementary functions",
        "functions": ["sin", "cos", "tan", "asin", "acos", "atan", "exp", "log", "log10", "sqrt", "abs"]
    },
    {
        "name": "matrix",
        "description": "Matrix creation and array manipulation functions",
        "functions": ["zeros", "ones", "eye", "diag", "repmat", "linspace", "size", "length"]
    },
    {
        "name": "linear_algebra",
        "description": "Matrix factorizations, solvers, and decompositions",
        "functions": ["inv", "det", "eig", "svd", "norm", "rank", "trace", "cond"]
    },
    {
        "name": "signal",
        "description": "Signal processing and spectral analysis",
        "functions": ["fft", "ifft", "fftshift", "filter", "conv", "xcorr"]
    },
    {
        "name": "control",
        "description": "Control system design and analysis",
        "functions": ["tf", "step", "bode", "rlocus", "lsim", "margin"]
    },
    {
        "name": "simulation",
        "description": "Numerical integration and dynamic simulation solvers",
        "functions": ["ode45", "ode23", "ode15s", "euler", "rk4"]
    },
]

# Root endpoints
@app.get("/")
async def root():
    return {"message": "UniLab API is running", "version": "1.1.0"}

@app.get("/api/v1")
async def api_v1_root():
    return {
        "name": "UniLab API v1",
        "version": "1.1.0",
        "endpoints": [
            "/api/v1/sessions",
            "/api/v1/functions",
            "/api/v1/libraries",
            "/api/v1/health",
            "/api/v1/metrics",
            "/api/v1/settings",
            "/api/v1/version",
            "/api/v1/system-info",
        ]
    }

# Session Management Endpoints
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

@app.get("/api/v1/sessions")
async def list_sessions(core: UniLabCore = Depends(get_core)):
    try:
        sessions = await core.list_sessions()
        session_list = [
            {
                "session_id": s.session_id,
                "username": s.username,
                "engine": s.engine,
                "started_at": s.started_at,
                "workspace": str(s.workspace_path)
            }
            for s in sessions
        ]
        return {
            "sessions": session_list,
            "total": len(session_list)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/sessions/{session_id}")
async def get_session(session_id: str, core: UniLabCore = Depends(get_core)):
    session = await core.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    return {
        "session_id": session.session_id,
        "username": session.username,
        "engine": session.engine,
        "started_at": session.started_at,
        "workspace": str(session.workspace_path)
    }

@app.delete("/api/v1/sessions/{session_id}")
async def delete_session(session_id: str, core: UniLabCore = Depends(get_core)):
    session = await core.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    await core.stop_session(session_id)
    return {"status": "success", "session_id": session_id}

# Execution Endpoints
@app.post("/api/v1/sessions/{session_id}/execute")
@app.post("/compute/run")
async def execute_code(
    req: ExecuteCodeRequest,
    session_id: Optional[str] = None,
    core: UniLabCore = Depends(get_core)
):
    global EXECUTION_COUNT
    target_session_id = session_id or req.session_id
    if not target_session_id:
        raise HTTPException(status_code=400, detail="session_id required")
    
    session = await core.get_session(target_session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    EXECUTION_COUNT += 1
    try:
        result = await core.run_code(
            session_id=target_session_id,
            code=req.code,
            timeout=req.timeout,
            filename=req.filename
        )
        return result
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/sessions/{session_id}/batch")
async def batch_execute(
    session_id: str,
    req: BatchExecuteRequest,
    core: UniLabCore = Depends(get_core)
):
    global EXECUTION_COUNT
    session = await core.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    results = []
    failed = 0
    for cmd in req.commands:
        EXECUTION_COUNT += 1
        res = await core.run_code(session_id=session_id, code=cmd.code)
        results.append(res)
        if not res.success:
            failed += 1
            if req.stop_on_error:
                break

    return {
        "total": len(req.commands),
        "executed": len(results),
        "failed": failed,
        "results": results
    }

@app.post("/api/v1/sessions/{session_id}/transpile")
@app.post("/api/v1/transpile")
async def transpile_code(
    req: TranspileRequest,
    session_id: Optional[str] = None,
    core: UniLabCore = Depends(get_core)
):
    try:
        t = UniLabTranspiler()
        res = t.transpile(req.code)
        py_code = res[0] if isinstance(res, tuple) else res
        return {
            "python_code": py_code,
            "unilab_code": req.code
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# Workspace Management Endpoints
@app.get("/api/v1/sessions/{session_id}/workspace")
async def get_workspace(session_id: str, core: UniLabCore = Depends(get_core)):
    session = await core.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    engine = core.engines.get(session_id)
    if not engine:
        raise HTTPException(status_code=404, detail="Engine not found")
    
    variables = engine._get_variables() if hasattr(engine, '_get_variables') else {}
    total_size = sum(v.get('size_bytes', 0) for v in variables.values() if isinstance(v, dict))
    return {
        "variables": variables,
        "variable_count": len(variables),
        "total_size_bytes": total_size
    }

@app.post("/api/v1/sessions/{session_id}/vars/{var_name}")
async def set_variable(
    session_id: str,
    var_name: str,
    req: SetVarRequest,
    core: UniLabCore = Depends(get_core)
):
    session = await core.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    engine = core.engines.get(session_id)
    if not engine:
        raise HTTPException(status_code=404, detail="Engine not found")

    if hasattr(engine, 'globals'):
        engine.globals[var_name] = req.value
    return {"status": "success", "variable": var_name}

@app.get("/api/v1/sessions/{session_id}/vars/{var_name}")
async def get_variable(
    session_id: str,
    var_name: str,
    core: UniLabCore = Depends(get_core)
):
    session = await core.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    engine = core.engines.get(session_id)
    if not engine or not hasattr(engine, 'globals') or var_name not in engine.globals:
        raise HTTPException(status_code=404, detail=f"Variable '{var_name}' not found")
    
    val = engine.globals[var_name]
    return {
        "name": var_name,
        "value": str(val),
        "type": type(val).__name__
    }

@app.post("/api/v1/sessions/{session_id}/clear")
async def clear_workspace(session_id: str, core: UniLabCore = Depends(get_core)):
    session = await core.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    engine = core.engines.get(session_id)
    if engine and hasattr(engine, 'globals'):
        # Keep runtime builtins, clear user variables
        runtime_names = getattr(engine, '_runtime_names', set())
        to_del = [k for k in engine.globals.keys() if k not in runtime_names and not k.startswith('_')]
        for k in to_del:
            del engine.globals[k]
    return {"status": "success"}

@app.post("/api/v1/sessions/{session_id}/export")
async def export_workspace(
    session_id: str,
    req: ExportWorkspaceRequest,
    core: UniLabCore = Depends(get_core)
):
    session = await core.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    try:
        exported_path = await core.export_workspace(session_id, format=req.format)
        return {"status": "success", "format": req.format, "file": str(exported_path)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# File Endpoints
@app.get("/api/v1/sessions/{session_id}/files")
async def list_files(
    session_id: str,
    path: Optional[str] = None,
    core: UniLabCore = Depends(get_core)
):
    session = await core.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    try:
        files = await core.list_files(session_id, path=path)
        base = session.workspace_path if path is None else (session.workspace_path / path)
        return {
            "files": files,
            "total": len(files),
            "path": str(base)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/sessions/{session_id}/files/create")
async def create_file(
    session_id: str,
    req: CreateFileRequest,
    core: UniLabCore = Depends(get_core)
):
    session = await core.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    target_path = session.workspace_path / req.filename
    if target_path.exists() and not req.overwrite:
        raise HTTPException(status_code=409, detail="File already exists")
    
    await core.write_file(session_id, req.filename, req.content)
    return {"status": "success", "filename": req.filename}

@app.post("/api/v1/sessions/{session_id}/scripts/run")
async def run_script(
    session_id: str,
    req: RunScriptRequest,
    core: UniLabCore = Depends(get_core)
):
    session = await core.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    # Locate file in session workspace or project root
    file_path = session.workspace_path / req.filename
    if not file_path.exists():
        # Fallback to samples / project root
        root = pathlib.Path(__file__).resolve().parents[2]
        alt = root / req.filename
        if not alt.exists():
            alt = root / "sample" / req.filename
        if alt.exists():
            file_path = alt
        else:
            raise HTTPException(status_code=404, detail=f"Script '{req.filename}' not found")
    
    code = file_path.read_text(encoding="utf-8")
    result = await core.run_code(session_id, code, filename=str(file_path))
    return result

@app.get("/api/v1/sessions/{session_id}/complete")
async def complete(session_id: str, text: str, line: str = "", core: UniLabCore = Depends(get_core)):
    try:
        suggestions = await core.complete(session_id, text, line)
        return {"suggestions": suggestions}
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")

@app.get("/api/v1/sessions/{session_id}/files/{filename}/download")
async def download_file(session_id: str, filename: str, core: UniLabCore = Depends(get_core)):
    session = await core.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    file_path = (session.workspace_path / filename).resolve()
    if not str(file_path).startswith(str(session.workspace_path.resolve())):
        raise HTTPException(status_code=403, detail="Access denied")
        
    if not file_path.exists():
        plot_path = (session.workspace_path / "plots" / filename).resolve()
        if plot_path.exists():
            file_path = plot_path
        else:
            raise HTTPException(status_code=404, detail="File not found")
            
    return FileResponse(path=str(file_path))

# Metadata Endpoints
@app.get("/api/v1/functions")
async def list_functions():
    return {
        "functions": FUNCTIONS_CATALOG,
        "total": len(FUNCTIONS_CATALOG)
    }

@app.get("/api/v1/functions/{name}")
async def get_function(name: str):
    for f in FUNCTIONS_CATALOG:
        if f["name"].lower() == name.lower():
            return f
    raise HTTPException(status_code=404, detail=f"Function '{name}' not found")

@app.post("/api/v1/functions/search")
async def search_functions(req: SearchFunctionRequest):
    q = req.query.lower()
    results = [
        f for f in FUNCTIONS_CATALOG
        if q in f["name"].lower() or q in f["description"].lower() or q in f["category"].lower()
    ]
    return {"results": results, "total": len(results)}

@app.get("/api/v1/libraries")
async def list_libraries():
    return {
        "libraries": LIBRARIES_CATALOG,
        "total": len(LIBRARIES_CATALOG)
    }

@app.get("/api/v1/libraries/{name}")
async def get_library(name: str):
    for lib in LIBRARIES_CATALOG:
        if lib["name"].lower() == name.lower():
            return lib
    raise HTTPException(status_code=404, detail=f"Library '{name}' not found")

# System Monitoring Endpoints
@app.get("/api/v1/health")
async def health_check():
    now = time.time()
    return {
        "status": "healthy",
        "uptime_s": now - START_TIME,
        "timestamp": now
    }

@app.get("/api/v1/metrics")
async def get_metrics(core: UniLabCore = Depends(get_core)):
    now = time.time()
    return {
        "active_sessions": len(core.sessions),
        "total_executions": EXECUTION_COUNT,
        "uptime_s": now - START_TIME
    }

@app.get("/api/v1/settings")
async def get_settings():
    return {
        "max_sessions": 100,
        "default_engine": "transpiler",
        "version": "1.1.0"
    }

@app.get("/api/v1/version")
async def get_version():
    return {
        "name": "UniLab",
        "version": "1.1.0"
    }

@app.get("/api/v1/system-info")
async def system_info(core: UniLabCore = Depends(get_core)):
    now = time.time()
    return {
        "health": {
            "status": "healthy",
            "uptime_s": now - START_TIME,
            "timestamp": now
        },
        "metrics": {
            "active_sessions": len(core.sessions),
            "total_executions": EXECUTION_COUNT,
            "uptime_s": now - START_TIME
        },
        "settings": {
            "max_sessions": 100,
            "default_engine": "transpiler",
            "version": "1.1.0"
        }
    }

# Web terminal static mount
web_dir = pathlib.Path(__file__).parent.parent / "web"
if web_dir.exists():
    app.mount("/terminal", StaticFiles(directory=str(web_dir), html=True), name="terminal")

@app.on_event("startup")
async def startup_event():
    core = get_core()
    await core.start()

@app.on_event("shutdown")
async def shutdown_event():
    core = get_core()
    await core.stop()
