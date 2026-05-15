from abc import ABC, abstractmethod
from typing import Any, Dict, Optional
from backend.core.models import ExecutionResult, SessionInfo

class BaseEngine(ABC):
    def __init__(self, session: SessionInfo):
        self.session = session
        self.workspace_path = session.workspace_path

    @abstractmethod
    async def start(self):
        pass

    @abstractmethod
    async def stop(self):
        pass

    @abstractmethod
    async def run_code(self, code: str, timeout: Optional[float] = 30.0) -> ExecutionResult:
        pass

    @abstractmethod
    async def fetch_variables(self) -> Dict[str, Any]:
        pass
