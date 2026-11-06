# UniLab Rust Migration & Architecture Plan

## 1. Executive Summary
UniLab is transitioning its core execution engine from a Python-based transpiler to a high-performance, native Rust interpreter. This migration aims to provide massive performance gains, eliminate the dependency on a local Python environment, and enable true cross-platform execution on Mobile, Desktop, and Web browsers (via WebAssembly) using Flutter and `flutter_rust_bridge`.

This document outlines the detailed architecture, core components, project structure, and phased implementation strategy for the Rust backend.

IMPORTANT: FOR THE SIMULATIONS AND PLOTTING LIBRARYS PYTHON WILL BE USED AND IT'S CORE LIBRARY!

## 2. Current vs. Target Architecture

### 2.1 Current Architecture (Legacy Python)
- **Parsing:** Lark EBNF parser transpiles MATLAB syntax into a Python AST.
- **Execution:** Python `exec()` evaluates the generated code within a controlled `globals()` environment.
- **Math/Data:** NumPy and SciPy provide underlying matrix and mathematical operations.
- **Visualization:** Matplotlib generates images/plots that are returned as base64 or saved files.

### 2.2 Target Architecture (Native Rust)
- **Parsing:** A native Rust parser (`pest` or `nom`) parses MATLAB syntax directly into a strongly-typed Rust Abstract Syntax Tree (AST).
- **Execution:** A high-speed Tree-Walking Interpreter evaluates the AST, managing memory and scope natively.
- **Math/Data:** `ndarray` and `nalgebra` provide robust, fast matrix operations.
- **Visualization:** The Rust core will NOT render images. Instead, it emits declarative plotting commands and data structures (JSON/MessagePack) which are passed to the Flutter frontend for interactive, native rendering (e.g., using Plotly.js or native Flutter charts).
- **Integration:** `flutter_rust_bridge` handles asynchronous, memory-safe communication between the Dart UI and the Rust execution core.

## 3. Core Components Design

### 3.1 Parser & Lexer (`unilab_parser`)
We will use **Pest** (Parsing Expression Grammar) due to its clean syntax and ease of maintaining complex grammars.
- Create `unilab.pest` based on the existing `UniLab_GRAMMAR` from `transpiler_core.py`.
- Handle whitespace, comments, and line continuations cleanly at the lexer level.

### 3.2 Abstract Syntax Tree (AST)
Define recursive Rust structs and enums to represent the code:
```rust
pub enum Expr {
    Number(f64),
    String(String),
    Matrix(Vec<Vec<Expr>>),
    Identifier(String),
    BinaryOp(Box<Expr>, BinaryOperator, Box<Expr>),
    FunctionCall(String, Vec<Expr>),
    // ...
}

pub enum Stmt {
    Assignment(Vec<String>, Expr),
    If { condition: Expr, then_branch: Vec<Stmt>, else_branch: Option<Vec<Stmt>> },
    For { var: String, iter: Expr, body: Vec<Stmt> },
    FunctionDef { name: String, params: Vec<String>, body: Vec<Stmt>, returns: Vec<String> },
    // ...
}
```

### 3.3 Engine & Environment (`unilab_runtime`)
- **Variables & State:** The workspace will be managed via a `HashMap<String, Value>`.
- **Value Enum:** Encapsulates dynamic types safely in Rust.
```rust
pub enum Value {
    Scalar(f64),
    Matrix(ndarray::Array2<f64>),
    String(String),
    Bool(bool),
    CellArray(Vec<Value>),
    FunctionHandle(String),
    Void,
}
```
- **1-Based Indexing:** The engine will automatically translate MATLAB's 1-based indexing into Rust's 0-based indexing underneath.

### 3.4 Standard Library Translation (`unilab_stdlib`)
- Map core MATLAB math functions to Rust's `f64` and `ndarray` implementations.
- **Script Autoloading:** Provide an IO layer to read `.m` files from the filesystem (or bundled assets for Web) when a function name isn't found in current scope.

## 4. Proposed Rust Project Structure

We will restructure the backend as a Cargo workspace to keep components modular.

```text
backend/
├── Cargo.toml                  # Workspace definition
├── unilab_cli/                 # CLI Application (replaces cli/app.py)
│   ├── Cargo.toml
│   └── src/main.rs
├── unilab_core/                # The main execution engine and AST
│   ├── Cargo.toml
│   ├── src/
│   │   ├── parser/             # Pest grammar and parsing logic
│   │   │   ├── unilab.pest
│   │   │   └── ast.rs
│   │   ├── runtime/            # Evaluator, Scope, Environment
│   │   │   ├── env.rs
│   │   │   ├── eval.rs         # Tree-walking interpreter
│   │   │   └── value.rs        # Value enum (Scalar, Matrix, etc.)
│   │   ├── stdlib/             # Native implementations of built-ins
│   │   │   ├── math.rs
│   │   │   ├── linalg.rs
│   │   │   └── plot_api.rs     # Data emitters for plotting
│   │   └── lib.rs
├── unilab_ffi/                 # Integration bindings
│   ├── Cargo.toml
│   └── src/
│       ├── api.rs              # flutter_rust_bridge API endpoints
│       └── models.rs           # Shared structs (ExecutionResult, Session)
└── docs/
```

## 5. Implementation Phases

### Phase 1: Parsing and Basic AST (Weeks 1-2)
- Set up the Cargo workspace and initialize `unilab_core`.
- Port the existing EBNF grammar to `unilab.pest`.
- Define AST enums and implement the conversion from Pest pairs to AST nodes.
- **Deliverable:** A CLI tool that can parse `.m` files and print the AST.

### Phase 2: Core Interpreter & Memory Model (Weeks 3-4)
- Implement the `Value` enum utilizing `ndarray` for matrices.
- Build the `Environment` struct for variable scoping.
- Implement the tree-walking evaluator (`eval.rs`) handling assignments, basic arithmetic, and matrix generation.
- **Deliverable:** Execution of simple mathematical scripts.

### Phase 3: Control Flow & Standard Library (Weeks 5-7)
- Add evaluation logic for `for`, `while`, `if/elseif`, and `switch`.
- Implement function definitions and variable argument handling (`varargin`, `varargout`).
- Port core `stdlib` capabilities (linear algebra, basic stats, trigonometry).
- Implement the `.m` file autoloader to reuse existing libraries like `/astronomy`, `/finance`, etc.
- **Deliverable:** Complex script execution and Turing-completeness.

### Phase 4: FFI and Flutter Bridge (Weeks 8-9)
- Initialize `unilab_ffi` with `flutter_rust_bridge`.
- Define the Rust-Dart communication protocol for Sessions, Execution Requests, and Results.
- Route graphical commands (`plot`, `scatter`) to emit JSON/MessagePack structures instead of rendering images.
- **Deliverable:** Native library capable of plugging into the new Flutter UI.

## 6. Risks & Mitigations
1. **Matrix Slicing & Broadcasting Compatibility:**
   - *Risk:* MATLAB's matrix expansion rules differ slightly from `ndarray`.
   - *Mitigation:* Create a custom wrapper over `ndarray` or helper functions in `unilab_core` that mimic exact MATLAB broadcasting and out-of-bounds expansion behavior.
2. **Dynamic Typing Overhead:**
   - *Risk:* Passing an `enum Value` around repeatedly can be slower than statically typed operations.
   - *Mitigation:* The performance gain over Python's `exec()` will still be substantial. Future iterations can explore LLVM JIT compilation for typed hotspots.
3. **WebAssembly File System Access:**
   - *Risk:* Wasm does not have a standard filesystem, which breaks the `.m` autoloader.
   - *Mitigation:* For Wasm targets, pre-compile/bundle the `.m` standard libraries into the binary using `include_bytes!` or a virtual filesystem abstraction.