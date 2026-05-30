"""Session management endpoints."""

from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional, List
from backend.api.dependencies import get_core
from backend.api.schemas import (
    CreateSessionRequest, SessionResponse, SessionListResponse
)
from backend.core.unilab_core import UniLabCore

router = APIRouter(prefix="/api/v1/sessions", tags=["sessions"])


@router.post("", response_model=SessionResponse)
async def create_session(
    req: CreateSessionRequest,
    core: UniLabCore = Depends(get_core)
):
    """Create a new execution session."""
    try:
        session = await core.create_session(
            username=req.username or "default",
            engine=req.engine
        )
        return SessionResponse(
            session_id=session.session_id,
            username=session.username,
            engine=session.engine,
            started_at=session.started_at,
            workspace_path=str(session.workspace_path),
            container_id=session.container_id,
            is_shared=session.is_shared,
            metadata=session.metadata
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("", response_model=SessionListResponse)
async def list_sessions(
    username: Optional[str] = Query(None),
    core: UniLabCore = Depends(get_core)
):
    """List all active sessions."""
    try:
        sessions = await core.list_sessions()
        
        # Filter by username if provided
        if username:
            sessions = [s for s in sessions if s.username == username]
        
        return SessionListResponse(
            sessions=[
                SessionResponse(
                    session_id=s.session_id,
                    username=s.username,
                    engine=s.engine,
                    started_at=s.started_at,
                    workspace_path=str(s.workspace_path),
                    container_id=s.container_id,
                    is_shared=s.is_shared,
                    metadata=s.metadata
                )
                for s in sessions
            ],
            total=len(sessions)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{session_id}", response_model=SessionResponse)
async def get_session(
    session_id: str,
    core: UniLabCore = Depends(get_core)
):
    """Get details of a specific session."""
    try:
        session = await core.get_session(session_id)
        if not session:
            raise HTTPException(status_code=404, detail=f"Session {session_id} not found or has expired")
        
        return SessionResponse(
            session_id=session.session_id,
            username=session.username,
            engine=session.engine,
            started_at=session.started_at,
            workspace_path=str(session.workspace_path),
            container_id=session.container_id,
            is_shared=session.is_shared,
            metadata=session.metadata
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{session_id}")
async def delete_session(
    session_id: str,
    core: UniLabCore = Depends(get_core)
):
    """Delete/close a session."""
    try:
        await core.stop_session(session_id)
        return {"status": "success", "message": "Session closed"}
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{session_id}/complete")
async def autocomplete(
    session_id: str,
    text: str = "",
    line: str = "",
    core: UniLabCore = Depends(get_core)
):
    """Get autocomplete suggestions for a session."""
    try:
        suggestions = await core.complete(session_id, text, line)
        return {"suggestions": suggestions}
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
