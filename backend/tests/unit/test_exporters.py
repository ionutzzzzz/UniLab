import unittest
import os
import json
import pandas as pd
import numpy as np
import asyncio
from backend.exporters.csv_exporter import CSVExporter
from backend.exporters.json_exporter import JSONExporter

class TestExporters(unittest.TestCase):
    def setUp(self):
        self.csv_exporter = CSVExporter()
        self.json_exporter = JSONExporter()
        self.test_data = {
            "a": [1, 2, 3],
            "b": "hello",
            "c": np.array([4, 5, 6])
        }
        self.csv_path = "test_export.csv"
        self.json_path = "test_export.json"

    def tearDown(self):
        if os.path.exists(self.csv_path):
            os.remove(self.csv_path)
        if os.path.exists(self.json_path):
            os.remove(self.json_path)

    def test_json_export(self):
        async def run_test():
            await self.json_exporter.export(self.test_data, self.json_path)
            self.assertTrue(os.path.exists(self.json_path))
            with open(self.json_path, 'r') as f:
                data = json.load(f)
            self.assertEqual(data["a"], [1, 2, 3])
            self.assertEqual(data["b"], "hello")
            self.assertEqual(data["c"], [4, 5, 6]) # Numpy array converted to list
            
        asyncio.run(run_test())

    def test_csv_export(self):
        async def run_test():
            # CSV works best with uniform data, but let's test a simple dict
            simple_data = {"x": 1, "y": 2, "z": 3}
            await self.csv_exporter.export(simple_data, self.csv_path)
            self.assertTrue(os.path.exists(self.csv_path))
            df = pd.read_csv(self.csv_path)
            self.assertEqual(df["x"][0], 1)
            
        asyncio.run(run_test())

if __name__ == "__main__":
    unittest.main()
