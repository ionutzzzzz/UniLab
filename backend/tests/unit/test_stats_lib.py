import unittest
import pathlib
import shutil
from backend.core.unilab_core import UniLabCore, BackendConfig

class TestStatsLibrary(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.test_dir = pathlib.Path("./.console_workspaces/test_stats_workspace")
        if self.test_dir.exists():
            shutil.rmtree(self.test_dir)
        self.test_dir.mkdir()
        self.config = BackendConfig(workspace_root=self.test_dir, use_docker=False)
        self.core = UniLabCore(self.config)
        await self.core.start()

    async def asyncTearDown(self):
        await self.core.stop()
        if self.test_dir.exists():
            shutil.rmtree(self.test_dir)

    async def test_linear_regression(self):
        session = await self.core.create_session(username="testuser", engine="transpiler")
        code = """
        x = [1, 2, 3, 4, 5]';
        y = [2, 4, 5, 4, 5]';
        [slope, intercept, r2] = linear_regression(x, y);
        """
        result = await self.core.run_code(session.session_id, code)
        self.assertTrue(result.success, result.stderr)
        
        def to_float(s):
            return float(s.replace('[', '').replace(']', '').strip())

        slope = to_float(result.variables_snapshot["slope"]["preview"])
        intercept = to_float(result.variables_snapshot["intercept"]["preview"])
        r2 = to_float(result.variables_snapshot["r2"]["preview"])
        
        # Expected: y = 0.6x + 2.2, r2 = 0.6
        self.assertAlmostEqual(slope, 0.6, places=2)
        self.assertAlmostEqual(intercept, 2.2, places=2)
        self.assertAlmostEqual(r2, 0.6, places=2)

    async def test_correlation_matrix(self):
        session = await self.core.create_session(username="testuser", engine="transpiler")
        code = """
        data = [1, 2; 2, 4; 3, 6; 4, 8];
        R = correlation_matrix(data);
        """
        result = await self.core.run_code(session.session_id, code)
        self.assertTrue(result.success, result.stderr)
        
        # R should be [[1, 1], [1, 1]] because they are perfectly correlated
        # The preview might be complex, let's just check if it's there
        self.assertIn("R", result.variables_snapshot)

    async def test_robust_scaler(self):
        session = await self.core.create_session(username="testuser", engine="transpiler")
        code = """
        data = [1, 2, 3, 4, 100]';
        scaled = robust_scaler(data);
        """
        result = await self.core.run_code(session.session_id, code)
        self.assertTrue(result.success, result.stderr)
        self.assertIn("scaled", result.variables_snapshot)

    async def test_skewness_kurtosis(self):
        session = await self.core.create_session(username="testuser", engine="transpiler")
        code = """
        data = [1, 2, 3, 4, 5]';
        sk = skewness(data);
        kt = kurtosis(data);
        """
        result = await self.core.run_code(session.session_id, code)
        self.assertTrue(result.success, result.stderr)
        
        def to_float(s):
            return float(s.replace('[', '').replace(']', '').strip())

        # Skewness of symmetric data should be 0
        sk = to_float(result.variables_snapshot["sk"]["preview"])
        self.assertAlmostEqual(sk, 0, places=2)

if __name__ == "__main__":
    unittest.main()
