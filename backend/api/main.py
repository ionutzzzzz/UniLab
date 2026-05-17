from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi
from backend.api.routes import (
    compute, sessions, execution, workspace, files, export, metadata, system
)
from backend.api.dependencies import start_core, stop_core

app = FastAPI(
    title="UniLab API",
    version="0.1.0",
    description="REST API for UniLab - MATLAB/Octave Alternative Scientific Computing Platform",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(sessions.router)
app.include_router(execution.router)
app.include_router(workspace.router)
app.include_router(files.router)
app.include_router(export.router)
app.include_router(metadata.router)
app.include_router(system.router)
app.include_router(compute.router)  # Keep legacy routes for backward compatibility

@app.on_event("startup")
async def startup_event():
    await start_core()

@app.on_event("shutdown")
async def shutdown_event():
    await stop_core()

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
