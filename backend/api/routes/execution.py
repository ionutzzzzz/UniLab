"""Code execution endpoints."""

import asyncio
import logging
import uuid
from datetime import datetime
from typing import Optional, Dict, Any

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from backend.api.dependencies import get_core
from backend.api.schemas import (
    ExecuteCodeRequest, ExecutionResultResponse, BatchExecuteRequest,
    BatchExecuteResponse, TranspileRequest, TranspileResponse,
    DebugRequest, DebugResponse, ProfileRequest, ProfileResponse
)
from backend.core.unilab_core import UniLabCore

router = APIRouter(prefix="/api/v1/sessions", tags=["execution"])
logger = logging.getLogger("api.execution")

# Store for background execution tracking
_background_executions: Dict[str, Dict[str, Any]] = {}


@router.post("/{session_id}/execute", response_model=ExecutionResultResponse)
async def execute_code(
    session_id: str,
    req: ExecuteCodeRequest,
    core: UniLabCore = Depends(get_core)
):
    """Execute code in a session."""
    try:
        # Special handling for 'whos' to match CLI behavior
        code = req.code.strip()
        if code.lower() in ('whos', 'whos;'):
            if not code.endswith(';'):
                code += ';'
        
        try:
            result = await core.run_code(session_id, code, timeout=req.timeout)
        except asyncio.TimeoutError:
            return ExecutionResultResponse(
                success=False,
                stdout="",
                stderr=f"Execution timed out after {req.timeout} seconds.",
                return_code=124,
                duration_s=req.timeout,
                variables_snapshot={},
                plots=[],
                execution_id=str(uuid.uuid4())
            )
        
        # Convert VariableInfo dicts to the schema
        variables_snapshot = {}
        if result.variables_snapshot:
            for name, info in result.variables_snapshot.items():
                variables_snapshot[name] = {
                    "name": name,
                    "dtype": info.get('dtype', 'unknown'),
                    "shape": info.get('shape'),
                    "preview": str(info.get('preview', ''))[:200],
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
        
        return ExecutionResultResponse(
            success=result.success,
            stdout=result.stdout,
            stderr=result.stderr,
            return_code=result.return_code,
            duration_s=result.duration_s,
            variables_snapshot=variables_snapshot,
            plots=result.plots,
            execution_id=str(uuid.uuid4()),
            extra=result.extra
        )
    except KeyError:
        raise HTTPException(status_code=404, detail=f"Session {session_id} not found")
    except Exception as e:
        import traceback
        logger.error(f"Execution failed: {e}\n{traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Execution system error: {str(e)}")


@router.post("/{session_id}/execute-async")
async def execute_code_async(
    session_id: str,
    req: ExecuteCodeRequest,
    background_tasks: BackgroundTasks,
    core: UniLabCore = Depends(get_core)
):
    """Execute code asynchronously in background."""
    execution_id = str(uuid.uuid4())
    
    async def run_in_background():
        try:
            result = await core.run_code(session_id, req.code, timeout=req.timeout)
            _background_executions[execution_id] = {
                "status": "completed",
                "result": result,
                "timestamp": datetime.now().isoformat()
            }
        except asyncio.TimeoutError:
             _background_executions[execution_id] = {
                "status": "failed",
                "error": "Execution timed out",
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            _background_executions[execution_id] = {
                "status": "failed",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    # Check session existence first
    try:
        session = await core.get_session(session_id)
        if not session:
             raise HTTPException(status_code=404, detail="Session not found")
    except KeyError:
         raise HTTPException(status_code=404, detail="Session not found")

    _background_executions[execution_id] = {
        "status": "running",
        "timestamp": datetime.now().isoformat()
    }
    
    background_tasks.add_task(run_in_background)
    
    return {
        "execution_id": execution_id,
        "status": "queued",
        "check_url": f"/api/v1/sessions/{session_id}/execution/{execution_id}"
    }


@router.get("/{session_id}/execution/{execution_id}")
async def get_execution_status(
    session_id: str,
    execution_id: str
):
    """Get status of async execution."""
    if execution_id not in _background_executions:
        raise HTTPException(status_code=404, detail="Execution not found")
    
    return _background_executions[execution_id]


@router.post("/{session_id}/batch", response_model=BatchExecuteResponse)
async def batch_execute(
    session_id: str,
    req: BatchExecuteRequest,
    core: UniLabCore = Depends(get_core)
):
    """Execute multiple code snippets in sequence."""
    results = []
    failed_count = 0
    
    try:
        for cmd_req in req.commands:
            result = await core.run_code(session_id, cmd_req.code, timeout=cmd_req.timeout)
            
            variables_snapshot = {}
            if result.variables_snapshot:
                for name, info in result.variables_snapshot.items():
                    variables_snapshot[name] = {
                        "name": name,
                        "dtype": info.get('dtype', 'unknown'),
                        "shape": info.get('shape'),
                        "preview": str(info.get('preview', ''))[:200],
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
            
            exec_result = ExecutionResultResponse(
                success=result.success,
                stdout=result.stdout,
                stderr=result.stderr,
                return_code=result.return_code,
                duration_s=result.duration_s,
                variables_snapshot=variables_snapshot,
                plots=result.plots,
                execution_id=str(uuid.uuid4())
            )
            results.append(exec_result)
            
            if not result.success:
                failed_count += 1
                if req.stop_on_error:
                    break
    
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
    return BatchExecuteResponse(
        results=results,
        total=len(results),
        failed=failed_count
    )


@router.post("/{session_id}/transpile", response_model=TranspileResponse)
async def transpile_code(
    session_id: str,
    req: TranspileRequest,
    core: UniLabCore = Depends(get_core)
):
    """Transpile UniLab code to Python."""
    try:
        # Get the transpiler from the engine
        transpiler = core.engines[session_id].transpiler
        python_code, _, _ = transpiler.transpile(req.code)
        
        return TranspileResponse(
            python_code=python_code,
            unilab_code=req.code,
            transpiler_version="1.0.0"
        )
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Transpilation failed: {str(e)}")


@router.post("/{session_id}/debug", response_model=DebugResponse)
async def debug_execute(
    session_id: str,
    req: DebugRequest,
    core: UniLabCore = Depends(get_core)
):
    """Execute code in debug mode (stepping, breakpoints)."""
    try:
        # For now, just execute and return variables
        # Full debug support would require more infrastructure
        result = await core.run_code(session_id, req.code, timeout=30.0)
        
        return DebugResponse(
            state="stopped",
            current_line=None,
            variables=result.variables_snapshot or {},
            call_stack=[]
        )
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{session_id}/profile", response_model=ProfileResponse)
async def profile_execute(
    session_id: str,
    req: ProfileRequest,
    core: UniLabCore = Depends(get_core)
):
    """Profile code execution for performance analysis."""
    try:
        import time
        import psutil
        import os
        
        start_time = time.time()
        start_memory = None
        
        try:
            process = psutil.Process(os.getpid())
            start_memory = process.memory_info().rss / 1024 / 1024
        except:
            pass
        
        result = await core.run_code(session_id, req.code, timeout=30.0)
        
        total_time = time.time() - start_time
        total_memory = None
        
        if start_memory:
            try:
                end_memory = process.memory_info().rss / 1024 / 1024
                total_memory = end_memory - start_memory
            except:
                pass
        
        return ProfileResponse(
            total_time_s=total_time,
            total_memory_mb=total_memory,
            lines={}
        )
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
