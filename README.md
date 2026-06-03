# 🧪 UniLab

![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Rust](https://img.shields.io/badge/rust-%23000000.svg?style=for-the-badge&logo=rust&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![WebAssembly](https://img.shields.io/badge/wasm-%23624DE8.svg?style=for-the-badge&logo=webassembly&logoColor=white)

> A high-performance, local-first environment for the simulation, modeling, and analysis of mathematical systems.

---

## 📑 Table of Contents

1. [About The Project](#-about-the-project)
2. [Key Features](#-key-features)
3. [Technology Stack](#-technology-stack)
4. [Architecture Pivot](#-architecture-pivot)
5. [Roadmap](#-roadmap)
6. [Contributing](#-contributing)
7. [License](#-license)

---

## 📖 About The Project

**UniLab** is an advanced platform designed for students, researchers, and engineers. It focuses on the simulation, modeling, and analysis of mathematical systems, with deep applications in artificial intelligence, control theory, and signal processing.

Historically, advanced mathematical modeling has been locked behind expensive, server-heavy, or visually outdated legacy software. UniLab provides a **modern, local-first alternative**. By moving computation directly to your device (Mobile, Desktop, or Web) using Rust and WebAssembly, UniLab eliminates latency and ensures your data stays private.

Whether you are designing a control system, training a machine learning model, or analyzing complex signals, UniLab provides the horsepower of a native environment in a sleek, high-fidelity interface.

---

## ✨ Key Features

* **Local-First Execution**: Computation happens on your device. No remote servers, no latency, no privacy concerns.
* **Cross-Platform Parity**: A unified experience across iOS, Android, macOS, Windows, Linux, and the Web.
* **High-Fidelity Graphics**: Interactive, real-time plotting and 3D visualizations powered by Flutter's Impeller/Skia engines.
* **Rust-Powered Engine**: A high-performance core designed for native speed and the future home of a custom mathematical compiler.
* **MATLAB-Compatible Syntax**: Leverage your existing knowledge with a familiar scientific syntax transpiled for speed.

---

## 🛠️ Technology Stack

UniLab is transitioning to a memory-safe, high-performance stack:

### **Engine & Computation**

* **Rust**: The core execution engine, providing safety and native performance.
* **WebAssembly (Wasm)**: Enables the Rust engine to run at near-native speeds in web browsers.
* **FFI**: Bridges the core engine to mobile and desktop platforms.

### **Frontend & UI**

* **Flutter**: Powers the pixel-perfect, interactive GUI across all platforms.
* **Dart**: The language behind Flutter's responsive and smooth user experience.

---

## 🔄 Architecture Pivot

We are currently in the process of migrating from a Python/React/Docker architecture to a **Native Flutter/Rust** stack. This change is driven by the need for:

1. **Offline Capability**: Removing the dependency on a backend server.
2. **Performance**: Leveraging Rust's zero-cost abstractions for heavy math.
3. **Consistency**: Ensuring a single codebase provides a premium experience on every device.

---

## 🚀 Getting Started

*Note: The project is currently in the middle of the architectural migration. Local Python execution is still supported via the CLI.*

### CLI Usage (Legacy Python)

```bash
cd backend
python3 UniLab.py console
```

### Building the New GUI (Coming Soon)

Stay tuned as we initialize the Flutter and Rust workspaces.

---

## 🗺️ Roadmap

- [X] Core computation engine (Python Transpiler)
- [X] 65+ Scientific Library toolboxes
- [X] Architectural Design for Cross-Platform GUI
- [X] Initialize Flutter + Rust (FFI/Wasm) bridge
- [ ] Port Parser/Transpiler to Rust
- [ ] Native high-performance plotting in Flutter
- [X] Local File/Workspace Manager
- [ ] Custom UniLab Compiler/Interpreter in Rust

---

## 📝 License

Distributed under the MIT License. See LICENSE for more information.

> Note: UniLab is a personal project currently in active development. Features and APIs are subject to change.
