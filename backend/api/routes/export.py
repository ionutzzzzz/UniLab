"""Export and visualization endpoints."""

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse
from typing import Optional, List
from pathlib import Path
import json
import os
import logging
from backend.api.dependencies import get_core
from backend.api.schemas import (
    ExportRequest, ExportResponse, PlotRequest, PlotResponse, PlotListResponse
)
from backend.core.unilab_core import UniLabCore

router = APIRouter(prefix="/api/v1/sessions", tags=["export"])
logger = logging.getLogger("api.export")

# Store for generated plots
_generated_plots = {}

async def cleanup_file(path: str, plot_id: Optional[str] = None):
    """Background task to remove temporary files after they are served."""
    try:
        p = Path(path)
        if p.exists():
            p.unlink()
            logger.info(f"Cleaned up temporary file: {path}")
        
        if plot_id and plot_id in _generated_plots:
            del _generated_plots[plot_id]
            logger.info(f"Removed plot metadata for: {plot_id}")
    except Exception as e:
        logger.error(f"Error cleaning up file {path}: {e}")


@router.post("/{session_id}/export", response_model=ExportResponse)
async def export_workspace(
    session_id: str,
    req: ExportRequest,
    core: UniLabCore = Depends(get_core)
):
    """Export workspace data in various formats."""
    try:
        # Use the core's export function
        export_path = await core.export_workspace(
            session_id,
            format=req.format,
            filename=req.filename
        )
        
        export_file = Path(export_path)
        file_size = export_file.stat().st_size if export_file.exists() else 0
        
        return ExportResponse(
            path=str(export_path),
            format=req.format,
            size=file_size,
            variables_count=0,
            filename=export_file.name
        )
    except KeyError:
        raise HTTPException(status_code=404, detail=f"Session {session_id} not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Export failed: {str(e)}")


@router.get("/{session_id}/export/{export_id}")
async def download_export(
    session_id: str,
    export_id: str,
    background_tasks: BackgroundTasks,
    core: UniLabCore = Depends(get_core)
):
    """Download exported workspace file."""
    try:
        session = await core.get_session(session_id)
        if not session:
            raise HTTPException(status_code=404, detail=f"Session {session_id} not found")
        
        # Look for export file
        export_dir = session.workspace_path / "exports"
        if not export_dir.exists():
            raise HTTPException(status_code=404, detail=f"Export directory not found for session {session_id}")
        
        export_file = export_dir / export_id
        if not export_file.exists():
            raise HTTPException(status_code=404, detail=f"Export file '{export_id}' not found")
        
        # Add cleanup task
        background_tasks.add_task(cleanup_file, str(export_file))
        
        return FileResponse(export_file)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{session_id}/plot", response_model=PlotResponse)
async def generate_plot(
    session_id: str,
    req: PlotRequest,
    core: UniLabCore = Depends(get_core)
):
    """Generate a plot from code."""
    try:
        import uuid
        import matplotlib
        matplotlib.use('Agg')
        import matplotlib.pyplot as plt
        
        plot_id = str(uuid.uuid4())
        
        # Set figure size
        plt.figure(figsize=(req.width/100, req.height/100), dpi=100)
        
        # Execute plotting code
        result = await core.run_code(session_id, req.code, timeout=15.0)
        
        if not result.success:
            raise HTTPException(status_code=400, detail=f"Plot generation failed: {result.stderr}")
        
        # Save plot
        session = await core.get_session(session_id)
        if not session:
            raise HTTPException(status_code=404, detail=f"Session {session_id} not found")

        plot_dir = session.workspace_path / "plots"
        plot_dir.mkdir(exist_ok=True)
        
        plot_path = plot_dir / f"{plot_id}.{req.format}"
        plt.savefig(plot_path, format=req.format, dpi=100, bbox_inches='tight')
        plt.close()
        
        file_size = plot_path.stat().st_size
        
        import time
        plot_info = {
            "plot_id": plot_id,
            "format": req.format,
            "path": str(plot_path),
            "size": file_size,
            "created_at": time.time()
        }
        _generated_plots[plot_id] = plot_info
        
        return PlotResponse(
            plot_id=plot_id,
            format=req.format,
            path=str(plot_path),
            size=file_size,
            created_at=time.time()
        )
    except HTTPException:
        raise
    except KeyError:
        raise HTTPException(status_code=404, detail=f"Session {session_id} not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Plot generation failed: {str(e)}")


@router.get("/{session_id}/plot/{plot_id}")
async def get_plot(
    session_id: str,
    plot_id: str,
    background_tasks: BackgroundTasks,
    core: UniLabCore = Depends(get_core)
):
    """Download a generated plot."""
    try:
        if plot_id not in _generated_plots:
            raise HTTPException(status_code=404, detail=f"Plot {plot_id} not found")
        
        plot_info = _generated_plots[plot_id]
        plot_path = Path(plot_info['path'])
        
        if not plot_path.exists():
            raise HTTPException(status_code=404, detail=f"Plot file not found for {plot_id}")
        
        # Add cleanup task
        background_tasks.add_task(cleanup_file, str(plot_path), plot_id)
        
        return FileResponse(plot_path, media_type=f"image/{plot_info['format']}")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))



@router.get("/{session_id}/plots", response_model=PlotListResponse)
async def list_plots(
    session_id: str,
    core: UniLabCore = Depends(get_core)
):
    """List all generated plots for a session."""
    try:
        session = await core.get_session(session_id)
        if not session:
            raise HTTPException(status_code=404, detail=f"Session {session_id} not found")
        
        plot_dir = session.workspace_path / "plots"
        plots = []
        
        if plot_dir.exists():
            for plot_file in plot_dir.iterdir():
                if plot_file.is_file():
                    plots.append(PlotResponse(
                        plot_id=plot_file.stem,
                        format=plot_file.suffix[1:],
                        path=str(plot_file),
                        size=plot_file.stat().st_size,
                        created_at=plot_file.stat().st_mtime
                    ))
        
        return PlotListResponse(plots=plots, total=len(plots))
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{session_id}/plot/{plot_id}")
async def delete_plot(
    session_id: str,
    plot_id: str,
    core: UniLabCore = Depends(get_core)
):
    """Delete a generated plot."""
    try:
        if plot_id not in _generated_plots:
            raise HTTPException(status_code=404, detail=f"Plot {plot_id} not found")
        
        plot_info = _generated_plots[plot_id]
        plot_path = Path(plot_info['path'])
        
        if plot_path.exists():
            plot_path.unlink()
        
        del _generated_plots[plot_id]
        
        return {"status": "success", "plot_id": plot_id, "deleted": True}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{session_id}/export-plot")
async def export_plot_as_data(
    session_id: str,
    plot_id: str,
    format: str = "json",
    core: UniLabCore = Depends(get_core)
):
    """Export plot data (for recreation on client)."""
    try:
        if plot_id not in _generated_plots:
            raise HTTPException(status_code=404, detail=f"Plot {plot_id} not found")
        
        return _generated_plots[plot_id]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
