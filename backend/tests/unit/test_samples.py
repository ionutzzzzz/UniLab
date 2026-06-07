import pytest
import pytest_asyncio
import pathlib
from backend.core.unilab_core import UniLabCore, BackendConfig

# Get the path to the sample directory
PROJECT_ROOT = pathlib.Path(__file__).resolve().parent.parent.parent.parent
SAMPLE_DIR = PROJECT_ROOT / "sample"

def get_sample_files():
    """Return a list of paths to all .m files in the sample directory."""
    if not SAMPLE_DIR.exists():
        return []
    return sorted(list(SAMPLE_DIR.glob("*.m")))

@pytest_asyncio.fixture
async def unilab_core(tmp_path):
    """Fixture to create and configure a UniLabCore instance."""
    cfg = BackendConfig(workspace_root=tmp_path)
    core = UniLabCore(cfg)
    await core.start()
    yield core
    await core.stop()

@pytest.mark.asyncio
@pytest.mark.parametrize("sample_file", get_sample_files(), ids=lambda f: f.name)
async def test_sample_script(unilab_core, sample_file):
    """Test that a sample script executes without errors."""
    with open(sample_file, "r") as f:
        code = f.read()

    session = await unilab_core.create_session(username="sample_tester", engine="transpiler")
    
    # We might need to copy the script content into the workspace or simply run it
    result = await unilab_core.run_code(session.session_id, code)
    
    # Assert that execution was successful
    assert result.success, f"Failed to execute {sample_file.name}. Stderr: {result.stderr}"
    
    # Clean up session
    await unilab_core.stop_session(session.session_id)
