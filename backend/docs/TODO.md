# UniLab: Development Roadmap (v2.0 Native GUI)

## 🏗️ Phase 1: Foundation & Bridging (Q3 2026)
- [ ] Initialize Flutter Project (`unilab_gui`)
- [ ] Initialize Rust Workspace (`unilab_core`)
- [ ] Integrate `flutter_rust_bridge` for cross-language calls
- [ ] Proof of Concept: Native math execution (Rust) → UI display (Flutter)
- [ ] Port Lark EBNF Grammar to Rust using `pest` or `nom`
- [ ] Implement Abstract Syntax Tree (AST) structures in Rust

## 🔢 Phase 2: Core Math & Scripting (Q4 2026)
- [ ] Build high-speed AST tree-walking interpreter in Rust
- [ ] Implement 1-based indexing and slicing logic in Rust
- [ ] Integrate `ndarray` for core matrix operations
- [ ] Build Flutter-native data-driven plotting (Line, Scatter, Bar)
- [ ] Implement basic math library port (sin, cos, exp, etc.) in Rust
- [ ] Handle MATLAB-style variable scoping (local, global) in Rust

## 🎨 Phase 3: Unified Workspace (Q1 2027)
- [ ] Build local File/Workspace manager in Flutter
- [ ] Implement Code Editor widget with UniLab syntax highlighting
- [ ] Create interactive REPL (Terminal) in Flutter
- [ ] Build 3D Surface Plotting widget using Flutter/Impeller
- [ ] Implement "toolbox" autoloading logic in Rust

## 🚀 Phase 4: Advanced Features & Optimization (Q2 2027+)
- [ ] Port Machine Learning toolboxes to native Rust
- [ ] Port Control Systems toolboxes to native Rust
- [ ] Implement LLVM-based JIT compilation for UniLab scripts
- [ ] Add support for CSV/JSON/HDF5 data import in Rust
- [ ] Release Beta versions for Android, iOS, and Web (Wasm)

---

## 🔧 Maintenance (Legacy Python Core)
- [x] Stabilization of Python Transpiler (v1.0.1)
- [x] 100% Pass rate on 88 unit tests
- [ ] Critical security patches only
- [ ] Use as reference implementation for Rust port

---

## ✅ Completed Milestones
- [x] 🧪 Core transpilation engine (Python)
- [x] 📚 65+ scientific libraries (MATLAB-compatible)
- [x] 📐 Architectural Pivot Plan (Flutter/Rust)
- [x] 📑 Global Documentation Update
