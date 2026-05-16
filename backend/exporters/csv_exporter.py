import csv
import numpy as np
import pandas as pd
from typing import Any
from .base import BaseExporter

class CSVExporter(BaseExporter):
    async def export(self, data: Any, output_path: str) -> str:
        """
        Exports data to a CSV file.
        Supports dictionaries, lists, and numpy arrays.
        """
        try:
            if isinstance(data, dict):
                # Try to convert dict to DataFrame
                df = pd.DataFrame.from_dict(data, orient='index').transpose()
                df.to_csv(output_path, index=False)
            elif isinstance(data, (list, np.ndarray)):
                df = pd.DataFrame(data)
                df.to_csv(output_path, index=False)
            else:
                with open(output_path, 'w', newline='') as f:
                    writer = csv.writer(f)
                    writer.writerow([data])
            return output_path
        except Exception as e:
            raise Exception(f"CSV Export failed: {str(e)}")
