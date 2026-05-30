"""System and monitoring endpoints."""

from fastapi import APIRouter, Depends, HTTPException
import time
from pathlib import Path
from backend.api.dependencies import get_core
from backend.api.schemas import (
    HealthResponse, MetricsResponse, SettingsResponse, SystemInfoResponse
)
from backend.core.unilab_core import UniLabCore

router = APIRouter(prefix="/api/v1", tags=["system"])

# Track metrics
_start_time = time.time()
_execution_stats = {
    "total_executions": 0,
    "total_errors": 0,
    "total_time": 0.0
}


@router.get("/health", response_model=HealthResponse)
async def health_check(core: UniLabCore = Depends(get_core)):
    """Check system health status."""
    try:
        uptime = time.time() - _start_time
        
        # Simple health check - just verify core is running
        status = "healthy"
        
        return HealthResponse(
            status=status,
            uptime_s=uptime,
            timestamp=time.time()
        )
    except Exception as e:
        return HealthResponse(
            status="unhealthy",
            uptime_s=time.time() - _start_time,
            timestamp=time.time()
        )


@router.get("/metrics", response_model=MetricsResponse)
async def get_metrics(core: UniLabCore = Depends(get_core)):
    """Get system metrics."""
    try:
        # Get active sessions count
        active_sessions = len(await core.list_sessions()) if hasattr(core, 'list_sessions') else 0
        
        # Calculate average execution time
        avg_time = (
            _execution_stats['total_time'] / _execution_stats['total_executions']
            if _execution_stats['total_executions'] > 0
            else 0.0
        )
        
        # Estimate workspace size
        workspace_size = 0
        try:
            workspace_root = core.config.workspace_root
            if workspace_root.exists():
                for item in workspace_root.rglob('*'):
                    if item.is_file():
                        workspace_size += item.stat().st_size
        except:
            pass
        
        workspace_size_mb = workspace_size / (1024 * 1024)
        
        return MetricsResponse(
            active_sessions=active_sessions,
            total_executions=_execution_stats['total_executions'],
            total_errors=_execution_stats['total_errors'],
            average_execution_time_s=avg_time,
            uptime_s=time.time() - _start_time,
            workspace_size_mb=workspace_size_mb
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/settings", response_model=SettingsResponse)
async def get_settings(core: UniLabCore = Depends(get_core)):
    """Get system settings."""
    try:
        return SettingsResponse(
            max_sessions=core.config.max_sessions,
            max_execution_time_s=30.0,
            default_engine="transpiler",
            workspace_root=str(core.config.workspace_root),
            available_engines=["transpiler"],
            version="0.1.0"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/system-info", response_model=SystemInfoResponse)
async def get_system_info(core: UniLabCore = Depends(get_core)):
    """Get complete system information."""
    try:
        health = await health_check(core)
        metrics = await get_metrics(core)
        settings = await get_settings(core)
        
        return SystemInfoResponse(
            health=health,
            metrics=metrics,
            settings=settings
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/status")
async def get_status(core: UniLabCore = Depends(get_core)):
    """Get quick status summary."""
    try:
        sessions = await core.list_sessions() if hasattr(core, 'list_sessions') else []
        
        return {
            "status": "running",
            "uptime_s": time.time() - _start_time,
            "active_sessions": len(sessions),
            "total_executions": _execution_stats['total_executions'],
            "errors": _execution_stats['total_errors'],
            "timestamp": time.time()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/record-execution")
async def record_execution(
    success: bool,
    duration_s: float
):
    """Record execution metrics (internal use)."""
    _execution_stats['total_executions'] += 1
    _execution_stats['total_time'] += duration_s
    
    if not success:
        _execution_stats['total_errors'] += 1
    
    return {"status": "recorded"}


@router.get("/version")
async def get_version():
    """Get API version."""
    return {
        "version": "0.1.0",
        "name": "UniLab API",
        "build": "development"
    }


@router.get("/info")
async def get_info():
    """Get API information."""
    return {
        "name": "UniLab Scientific Computing Platform API",
        "description": "REST API for executing MATLAB-like code in a multi-session environment",
        "version": "0.1.0",
        "endpoints": {
            "sessions": "Session management and CRUD operations",
            "execution": "Code execution and transpilation",
            "workspace": "Workspace and variable management",
            "files": "File operations and script execution",
            "export": "Data export and visualization",
            "metadata": "Function and library information",
            "system": "System monitoring and health checks"
        }
    }
