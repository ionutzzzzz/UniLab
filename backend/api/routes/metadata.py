"""Library and metadata endpoints."""

from fastapi import APIRouter, Depends, HTTPException
from typing import List
from backend.api.dependencies import get_core
from backend.api.schemas import (
    FunctionListResponse, FunctionSignature, LibraryListResponse, LibraryInfo,
    SearchRequest
)
from backend.core.unilab_core import UniLabCore

router = APIRouter(prefix="/api/v1", tags=["metadata"])

# Built-in functions and their signatures
BUILTIN_FUNCTIONS = {
    "disp": {
        "category": "I/O",
        "description": "Display variables",
        "parameters": ["value"],
        "returns": None,
        "examples": ["disp(x);", "disp('Hello World');"]
    },
    "sin": {
        "category": "Math",
        "description": "Sine function",
        "parameters": ["x"],
        "returns": "number",
        "examples": ["y = sin(pi/2);"]
    },
    "cos": {
        "category": "Math",
        "description": "Cosine function",
        "parameters": ["x"],
        "returns": "number",
        "examples": ["y = cos(0);"]
    },
    "exp": {
        "category": "Math",
        "description": "Exponential function",
        "parameters": ["x"],
        "returns": "number",
        "examples": ["y = exp(1);"]
    },
    "log": {
        "category": "Math",
        "description": "Natural logarithm",
        "parameters": ["x"],
        "returns": "number",
        "examples": ["y = log(10);"]
    },
    "sqrt": {
        "category": "Math",
        "description": "Square root",
        "parameters": ["x"],
        "returns": "number",
        "examples": ["y = sqrt(16);"]
    },
    "plot": {
        "category": "Visualization",
        "description": "Create a line plot",
        "parameters": ["x", "y"],
        "returns": None,
        "examples": ["plot(1:10, sin(1:10));"]
    },
    "scatter_plot": {
        "category": "Visualization",
        "description": "Create a scatter plot",
        "parameters": ["x", "y"],
        "returns": None,
        "examples": ["scatter_plot(randn(100,1), randn(100,1));"]
    },
    "hist_plot": {
        "category": "Visualization",
        "description": "Create a histogram",
        "parameters": ["data", "bins"],
        "returns": None,
        "examples": ["hist_plot(randn(1000,1), 50);"]
    },
    "eye": {
        "category": "Matrix",
        "description": "Identity matrix",
        "parameters": ["n"],
        "returns": "matrix",
        "examples": ["I = eye(3);"]
    },
    "zeros": {
        "category": "Matrix",
        "description": "Zero matrix",
        "parameters": ["m", "n"],
        "returns": "matrix",
        "examples": ["Z = zeros(3, 4);"]
    },
    "ones": {
        "category": "Matrix",
        "description": "Ones matrix",
        "parameters": ["m", "n"],
        "returns": "matrix",
        "examples": ["O = ones(2, 3);"]
    },
    "fft": {
        "category": "Signal Processing",
        "description": "Fast Fourier Transform",
        "parameters": ["x"],
        "returns": "array",
        "examples": ["X = fft(x);"]
    },
    "size": {
        "category": "Matrix",
        "description": "Matrix dimensions",
        "parameters": ["matrix"],
        "returns": "array",
        "examples": ["[m, n] = size(A);"]
    },
    "length": {
        "category": "Matrix",
        "description": "Vector length",
        "parameters": ["vector"],
        "returns": "number",
        "examples": ["n = length(x);"]
    },
}

LIBRARIES = {
    "math": {
        "name": "math",
        "category": "Mathematics",
        "description": "Advanced mathematical functions and numerical methods",
        "functions": [
            "sin", "cos", "tan", "exp", "log", "sqrt", "abs",
            "factorial", "round", "floor", "ceil"
        ]
    },
    "signal": {
        "name": "signal",
        "category": "Signal Processing",
        "description": "Signal processing and frequency domain analysis",
        "functions": [
            "fft", "ifft", "convolve", "correlate", "filter"
        ]
    },
    "control": {
        "name": "control",
        "category": "Control Systems",
        "description": "Control systems analysis and design",
        "functions": [
            "tf", "ss", "pole", "zero", "bode", "nyquist"
        ]
    },
    "stats": {
        "name": "stats",
        "category": "Statistics",
        "description": "Statistical functions and distributions",
        "functions": [
            "mean", "median", "std", "var", "histogram"
        ]
    },
    "ml": {
        "name": "ml",
        "category": "Machine Learning",
        "description": "Machine learning and classification functions",
        "functions": [
            "kmeans", "pca", "svm", "linear_regression"
        ]
    },
    "viz": {
        "name": "viz",
        "category": "Visualization",
        "description": "Plotting and visualization utilities",
        "functions": [
            "plot", "scatter_plot", "hist_plot", "surf", "contour"
        ]
    },
}


@router.get("/functions", response_model=FunctionListResponse)
async def list_functions(
    category: str = None,
    query: str = None,
    core: UniLabCore = Depends(get_core)
):
    """List available functions."""
    functions = []
    
    for name, info in BUILTIN_FUNCTIONS.items():
        # Filter by category if provided
        if category and info.get('category', '').lower() != category.lower():
            continue
        
        # Filter by query if provided
        if query and query.lower() not in name.lower():
            continue
        
        functions.append(FunctionSignature(
            name=name,
            category=info.get('category', 'General'),
            description=info.get('description'),
            parameters=info.get('parameters'),
            returns=info.get('returns'),
            examples=info.get('examples')
        ))
    
    # Get unique categories
    categories = list(set(f.category for f in functions))
    
    return FunctionListResponse(
        functions=functions,
        total=len(functions),
        categories=categories
    )


@router.get("/functions/{function_name}")
async def get_function(
    function_name: str,
    core: UniLabCore = Depends(get_core)
):
    """Get detailed information about a function."""
    if function_name not in BUILTIN_FUNCTIONS:
        raise HTTPException(status_code=404, detail=f"Function '{function_name}' not found")
    
    info = BUILTIN_FUNCTIONS[function_name]
    
    return FunctionSignature(
        name=function_name,
        category=info.get('category', 'General'),
        description=info.get('description'),
        parameters=info.get('parameters'),
        returns=info.get('returns'),
        examples=info.get('examples')
    )


@router.get("/libraries", response_model=LibraryListResponse)
async def list_libraries(
    category: str = None,
    core: UniLabCore = Depends(get_core)
):
    """List available libraries and packages."""
    libraries = []
    
    for lib_name, lib_info in LIBRARIES.items():
        # Filter by category if provided
        if category and lib_info.get('category', '').lower() != category.lower():
            continue
        
        libraries.append(LibraryInfo(
            name=lib_info['name'],
            category=lib_info['category'],
            description=lib_info.get('description'),
            functions=lib_info.get('functions', []),
            version="1.0.0"
        ))
    
    return LibraryListResponse(
        libraries=libraries,
        total=len(libraries)
    )


@router.get("/libraries/{library_name}")
async def get_library(
    library_name: str,
    core: UniLabCore = Depends(get_core)
):
    """Get detailed information about a library."""
    if library_name not in LIBRARIES:
        raise HTTPException(status_code=404, detail=f"Library '{library_name}' not found")
    
    lib_info = LIBRARIES[library_name]
    
    return LibraryInfo(
        name=lib_info['name'],
        category=lib_info['category'],
        description=lib_info.get('description'),
        functions=lib_info.get('functions', []),
        version="1.0.0"
    )


@router.post("/functions/search")
async def search_functions(
    request: SearchRequest,
    core: UniLabCore = Depends(get_core)
):
    """Search for functions by name or description."""
    results = []
    query_lower = request.query.lower()
    
    for name, info in BUILTIN_FUNCTIONS.items():
        # Search in name and description
        if (query_lower in name.lower() or
            query_lower in info.get('description', '').lower()):
            results.append({
                "name": name,
                "category": info.get('category', 'General'),
                "description": info.get('description'),
                "match_score": 1.0 if name.startswith(query_lower) else 0.8
            })
    
    # Sort by match score
    results.sort(key=lambda x: x['match_score'], reverse=True)
    
    return {
        "query": request.query,
        "results": results,
        "total": len(results)
    }


@router.get("/function-categories")
async def get_function_categories(
    core: UniLabCore = Depends(get_core)
):
    """Get all available function categories."""
    categories = {}
    
    for name, info in BUILTIN_FUNCTIONS.items():
        cat = info.get('category', 'General')
        if cat not in categories:
            categories[cat] = []
        categories[cat].append(name)
    
    return {
        "categories": categories,
        "total": len(categories)
    }


@router.get("/library-categories")
async def get_library_categories(
    core: UniLabCore = Depends(get_core)
):
    """Get all available library categories."""
    categories = {}
    
    for lib_name, lib_info in LIBRARIES.items():
        cat = lib_info.get('category', 'General')
        if cat not in categories:
            categories[cat] = []
        categories[cat].append(lib_name)
    
    return {
        "categories": categories,
        "total": len(categories)
    }
