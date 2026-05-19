"""Pydantic schemas for API requests and responses."""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any, Tuple
from datetime import datetime


# ==================== Session Management ====================

class CreateSessionRequest(BaseModel):
    """Create a new execution session."""
    username: Optional[str] = Field(default=None, description="Username")
    engine: str = Field(default="transpiler", description="Execution engine")
    metadata: Optional[Dict[str, Any]] = Field(default=None, description="Custom metadata")


class SessionResponse(BaseModel):
    """Session information response."""
    session_id: str
    username: str
    engine: str
    started_at: float
    workspace_path: str
    container_id: Optional[str] = None
    is_shared: bool = False
    metadata: Dict[str, Any] = {}


class SessionListResponse(BaseModel):
    """List of active sessions."""
    sessions: List[SessionResponse]
    total: int


# ==================== Code Execution ====================

class ExecuteCodeRequest(BaseModel):
    """Execute code in a session."""
    code: str = Field(..., description="UniLab/MATLAB code")
    timeout: Optional[float] = Field(default=30.0, description="Execution timeout in seconds")
    capture_plots: bool = Field(default=False, description="Capture generated plots")


class VariableInfo(BaseModel):
    """Information about a workspace variable."""
    name: str
    dtype: str
    shape: Optional[List[int]] = None
    preview: Any = None
    size_bytes: Optional[int] = None


class ExecutionResultResponse(BaseModel):
    """Result of code execution."""
    success: bool
    stdout: str = ""
    stderr: str = ""
    return_code: int
    duration_s: float
    variables_snapshot: Dict[str, VariableInfo] = {}
    plots: List[str] = []
    execution_id: Optional[str] = None


class BatchExecuteRequest(BaseModel):
    """Execute multiple code snippets."""
    commands: List[ExecuteCodeRequest]
    stop_on_error: bool = Field(default=True, description="Stop batch on first error")


class BatchExecuteResponse(BaseModel):
    """Results of batch execution."""
    results: List[ExecutionResultResponse]
    total: int
    failed: int


# ==================== Workspace Management ====================

class VariableValue(BaseModel):
    """Variable value for setting."""
    name: str
    value: Any
    dtype: Optional[str] = None


class WorkspaceResponse(BaseModel):
    """Complete workspace state."""
    variables: Dict[str, VariableInfo]
    total_size_bytes: int
    variable_count: int


class SetVariableRequest(BaseModel):
    """Set a variable in workspace."""
    value: Any = Field(..., description="Variable value")
    dtype: Optional[str] = Field(default=None, description="Data type")


class ClearWorkspaceRequest(BaseModel):
    """Clear workspace variables."""
    pattern: Optional[str] = Field(default=None, description="Variable pattern to clear (regex)")
    exclude: Optional[List[str]] = Field(default=None, description="Variables to exclude")


# ==================== File Operations ====================

class FileInfo(BaseModel):
    """Information about a file."""
    name: str
    path: str
    size: int
    created_at: Optional[float] = None
    modified_at: Optional[float] = None
    is_directory: bool = False


class FileListResponse(BaseModel):
    """List of files in workspace."""
    files: List[FileInfo]
    total: int
    path: str


class FileContentResponse(BaseModel):
    """File content response."""
    name: str
    path: str
    content: str
    size: int
    is_text: bool


class CreateFileRequest(BaseModel):
    """File creation metadata."""
    filename: str
    content: str
    overwrite: bool = False

class UploadFileRequest(BaseModel):
    """File upload metadata."""
    filename: str
    overwrite: bool = False


class RunScriptRequest(BaseModel):
    """Run a .m script file."""
    filename: str
    timeout: Optional[float] = Field(default=30.0)
    parameters: Optional[Dict[str, Any]] = Field(default=None, description="Script parameters")


# ==================== Export & Visualization ====================

class ExportRequest(BaseModel):
    """Export workspace data."""
    format: str = Field(default="json", description="Export format: json, csv, mat")
    filename: Optional[str] = None
    variables: Optional[List[str]] = Field(default=None, description="Specific variables to export")
    compress: bool = Field(default=False, description="Compress output")


class ExportResponse(BaseModel):
    """Export result."""
    path: str
    format: str
    size: int
    variables_count: int
    filename: str


class PlotRequest(BaseModel):
    """Generate a plot."""
    code: str = Field(..., description="Plotting code")
    format: str = Field(default="png", description="Output format: png, svg, pdf")
    width: int = Field(default=800, description="Plot width in pixels")
    height: int = Field(default=600, description="Plot height in pixels")


class PlotResponse(BaseModel):
    """Plot generation result."""
    plot_id: str
    format: str
    path: str
    size: int
    created_at: float


class PlotListResponse(BaseModel):
    """List of generated plots."""
    plots: List[PlotResponse]
    total: int


# ==================== Library & Metadata ====================

class FunctionSignature(BaseModel):
    """Function signature information."""
    name: str
    category: str
    description: Optional[str] = None
    parameters: Optional[List[str]] = None
    returns: Optional[str] = None
    examples: Optional[List[str]] = None


class FunctionListResponse(BaseModel):
    """List of available functions."""
    functions: List[FunctionSignature]
    total: int
    categories: List[str]


class LibraryInfo(BaseModel):
    """Library information."""
    name: str
    category: str
    functions: List[str]
    description: Optional[str] = None
    version: Optional[str] = None


class LibraryListResponse(BaseModel):
    """List of available libraries."""
    libraries: List[LibraryInfo]
    total: int


class SearchRequest(BaseModel):
    """A search request with a query string."""
    query: str


# ==================== System & Monitoring ====================

class HealthResponse(BaseModel):
    """System health status."""
    status: str  # "healthy", "degraded", "unhealthy"
    uptime_s: float
    timestamp: float


class MetricsResponse(BaseModel):
    """System metrics."""
    active_sessions: int
    total_executions: int
    total_errors: int
    average_execution_time_s: float
    uptime_s: float
    workspace_size_mb: float
    memory_usage_mb: Optional[float] = None


class SettingsResponse(BaseModel):
    """System settings."""
    max_sessions: int
    max_execution_time_s: float
    default_engine: str
    workspace_root: str
    available_engines: List[str]
    version: str


class SystemInfoResponse(BaseModel):
    """Complete system information."""
    health: HealthResponse
    metrics: MetricsResponse
    settings: SettingsResponse


# ==================== Error Responses ====================

class ErrorResponse(BaseModel):
    """Standard error response."""
    error: str
    detail: str
    status_code: int
    timestamp: float


class ValidationErrorResponse(BaseModel):
    """Validation error response."""
    error: str
    field: str
    message: str
    status_code: int = 422


# ==================== Advanced Execution ====================

class DebugRequest(BaseModel):
    """Debug code execution."""
    code: str
    breakpoints: Optional[List[int]] = None
    step_mode: bool = False


class DebugResponse(BaseModel):
    """Debug execution response."""
    state: str  # "running", "paused", "stopped"
    current_line: Optional[int] = None
    variables: Dict[str, Any]
    call_stack: List[str]


class ProfileRequest(BaseModel):
    """Profile code execution."""
    code: str
    collect_memory: bool = True
    collect_timing: bool = True


class ProfileResponse(BaseModel):
    """Code profiling results."""
    total_time_s: float
    total_memory_mb: Optional[float] = None
    lines: Dict[int, Dict[str, float]]  # line_number -> {time, memory}


class TranspileRequest(BaseModel):
    """Transpile UniLab code to Python."""
    code: str
    include_builtins: bool = Field(default=False, description="Include builtin functions")


class TranspileResponse(BaseModel):
    """Transpiled code response."""
    python_code: str
    unilab_code: str
    transpiler_version: str
    parse_tree: Optional[str] = None
