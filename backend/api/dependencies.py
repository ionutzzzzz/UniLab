from backend.core.unilab_core import UniLabCore
from backend.core.models import BackendConfig

# Singleton instance for the core engine
_core_instance = None

def get_core() -> UniLabCore:
    global _core_instance
    if _core_instance is None:
        _core_instance = UniLabCore()
    return _core_instance

async def start_core():
    core = get_core()
    await core.start()

async def stop_core():
    global _core_instance
    if _core_instance:
        await _core_instance.stop()
        _core_instance = None
