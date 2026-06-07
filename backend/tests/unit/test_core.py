import unittest
import pathlib
import shutil
from backend.core.unilab_core import UniLabCore, BackendConfig
from backend.core.models import SessionInfo, ExecutionResult

class TestUniLabCore(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.test_dir = pathlib.Path("./test_workspace")
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

    async def test_session_management(self):
        session = await self.core.create_session(username="testuser", engine="transpiler")
        self.assertIsInstance(session, SessionInfo)
        self.assertEqual(session.username, "testuser")
        self.assertIn(session.session_id, self.core.sessions)
        
        await self.core.stop_session(session.session_id)
        self.assertNotIn(session.session_id, self.core.sessions)

    async def test_run_code_transpiler(self):
        session = await self.core.create_session(username="testuser", engine="transpiler")
        code = "x = 1 + 2; disp(x);"
        result = await self.core.run_code(session.session_id, code)
        
        self.assertIsInstance(result, ExecutionResult)
        self.assertTrue(result.success)
        self.assertIn("3", result.stdout)
        self.assertIn("x", result.variables_snapshot)
        self.assertEqual(result.variables_snapshot["x"]["preview"], "3")

    async def test_persistence_between_runs(self):
        session = await self.core.create_session(username="testuser", engine="transpiler")
        await self.core.run_code(session.session_id, "a = 42;")
        result = await self.core.run_code(session.session_id, "disp(a);")
        
        self.assertTrue(result.success)
        self.assertIn("42", result.stdout)

    async def test_error_handling(self):
        session = await self.core.create_session(username="testuser", engine="transpiler")
        code = "this is not UniLab code"
        result = await self.core.run_code(session.session_id, code)
        
        self.assertFalse(result.success)
        self.assertTrue(len(result.stderr) > 0)

if __name__ == "__main__":
    unittest.main()
