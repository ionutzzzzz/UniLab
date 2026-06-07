import json
import time
import asyncio
from typing import Any, Dict, Optional
from backend.core.engines.base import BaseEngine
from backend.core.models import ExecutionResult, SessionInfo

try:
    from backend.core import unilab_rust_core
    RUST_AVAILABLE = True
except ImportError:
    RUST_AVAILABLE = False

class RustEngine(BaseEngine):
    def __init__(self, session: SessionInfo):
        super().__init__(session)
        self.variables = {}
        self.session_id = session.session_id

    async def start(self):
        if not RUST_AVAILABLE:
            raise ImportError("unilab_rust_core not found. Build the Rust core first.")
        # Create persistent session in Rust
        unilab_rust_core.rust_create_session(self.session_id)

    async def stop(self):
        pass

    async def run_code(self, code: str, timeout: Optional[float] = 300.0) -> ExecutionResult:
        start_time = time.time()
        try:
            loop = asyncio.get_event_loop()
            result_json = await loop.run_in_executor(
                None, 
                unilab_rust_core.rust_run_code_session, 
                self.session_id, 
                code
            )
            
            data = json.loads(result_json)
            duration = time.time() - start_time
            
            return ExecutionResult(
                success=data.get("success", False),
                stdout=data.get("output", ""),
                stderr=data.get("error", ""),
                return_code=0 if data.get("success", False) else 1,
                duration_s=duration,
                variables_snapshot={}, # We need to implement variable fetching from Rust
                plots=data.get("plots", [])
            )
        except Exception as e:
            return ExecutionResult(
                success=False,
                stdout="",
                stderr=str(e),
                return_code=1,
                duration_s=time.time() - start_time,
                variables_snapshot={},
                plots=[]
            )

    async def fetch_variables(self) -> Dict[str, Any]:
        # TODO: Implement variable fetching from Rust Evaluator
        return {}
