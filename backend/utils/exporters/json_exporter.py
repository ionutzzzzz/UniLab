import json
import numpy as np
from typing import Any
from .base import BaseExporter

class JSONEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        if isinstance(obj, np.integer):
            return int(obj)
        if isinstance(obj, np.floating):
            return float(obj)
        return super().default(obj)

class JSONExporter(BaseExporter):
    async def export(self, data: Any, output_path: str) -> str:
        """
        Exports data to a JSON file.
        Handles numpy arrays and other common mathematical types.
        """
        try:
            with open(output_path, 'w') as f:
                json.dump(data, f, cls=JSONEncoder, indent=4)
            return output_path
        except Exception as e:
            raise Exception(f"JSON Export failed: {str(e)}")
