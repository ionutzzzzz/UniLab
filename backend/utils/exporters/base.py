from abc import ABC, abstractmethod
from typing import Any, Dict
from backend.core.models import ExecutionResult

class BaseExporter(ABC):
    @abstractmethod
    async def export(self, data: Any, output_path: str) -> str:
        pass
