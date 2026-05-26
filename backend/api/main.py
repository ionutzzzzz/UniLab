import os
import sys
import pathlib
import traceback
from datetime import datetime
from contextlib import asynccontextmanager

os.environ['QT_QPA_PLATFORM'] = 'offscreen'
os.environ['UNILAB_WEB_MODE'] = '1'
import matplotlib
matplotlib.use('Agg')

current_dir = pathlib.Path(__file__).resolve().parent
project_root = (current_dir / ".." / "..").resolve()
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi
from fastapi.staticfiles import StaticFiles
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from backend.api.routes import (
    compute, sessions, execution, workspace, files, export, metadata, system
)
from backend.api.dependencies import start_core, stop_core
from backend.api.schemas import ErrorResponse

@asynccontextmanager
async def lifespan(app: FastAPI):
    await start_core()
    yield
    await stop_core()

app = FastAPI(
    title="UniLab API",
    version="0.1.0",
    description="REST API for UniLab - MATLAB/Octave Alternative Scientific Computing Platform",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
    lifespan=lifespan
)

@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": "HTTP Error",
            "detail": str(exc.detail),
            "status_code": exc.status_code,
            "timestamp": datetime.now().timestamp()
        },
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = exc.errors()
    detail = []
    for error in errors:
        loc = " -> ".join(str(l) for l in error.get("loc", []))
        msg = error.get("msg", "Unknown error")
        detail.append(f"[{loc}]: {msg}")
    
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": "Validation Error",
            "detail": "; ".join(detail) if detail else "Invalid request parameters",
            "status_code": 422,
            "timestamp": datetime.now().timestamp()
        },
    )

@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "Internal Server Error",
            "detail": str(exc),
            "traceback": traceback.format_exc() if os.environ.get("DEBUG") else None,
            "status_code": 500,
            "timestamp": datetime.now().timestamp()
        },
    )

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Web Terminal
web_dir = pathlib.Path(__file__).resolve().parent.parent / "web"
if web_dir.exists():
    app.mount("/terminal", StaticFiles(directory=str(web_dir), html=True), name="web_terminal")

# Include Routers
app.include_router(sessions.router)
app.include_router(execution.router)
app.include_router(workspace.router)
app.include_router(files.router)
app.include_router(export.router)
app.include_router(metadata.router)
app.include_router(system.router)
app.include_router(compute.router)  

from fastapi.responses import Response

@app.get("/favicon.ico", include_in_schema=False)
async def favicon():
    return Response(status_code=204)

@app.get("/")
async def root():
    return {
        "message": "UniLab API is running",
        "version": "0.1.0",
        "docs": "/api/docs",
        "status": "active"
    }

@app.get("/api/v1")
async def api_root():
    return {
        "message": "UniLab API v1",
        "endpoints": {
            "sessions": "/api/v1/sessions",
            "execution": "/api/v1/sessions/{id}/execute",
            "workspace": "/api/v1/sessions/{id}/workspace",
            "files": "/api/v1/sessions/{id}/files",
            "export": "/api/v1/sessions/{id}/export",
            "functions": "/api/v1/functions",
            "libraries": "/api/v1/libraries",
            "health": "/api/v1/health"
        }
    }

def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    openapi_schema = get_openapi(
        title="UniLab API",
        version="0.1.0",
        description="REST API for UniLab Scientific Computing Platform",
        routes=app.routes,
    )
    openapi_schema["info"]["x-logo"] = {
        "url": "https://fastapi.tiangolo.com/img/logo-margin/logo-teal.png"
    }
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
