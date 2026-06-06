# 🧪 UniLab Frontend

A professional, high-fidelity scientific computing GUI built with Flutter.

## 🚀 Overview
The UniLab frontend is designed to provide a MATLAB-inspired workspace for mathematical modeling, simulation, and analysis. It is part of the architectural pivot to a native, local-first stack using Flutter and Rust.

## ✨ Key Features
- **3-Panel Layout**: File browser, code editor, and workspace/properties panel.
- **Ribbon Interface**: Intuitive, tab-based navigation for Home, Plots, Apps, and more.
- **High-Performance Plotting**: Real-time visualizations powered by Flutter's Impeller engine.
- **Cross-Platform**: Unified codebase for Desktop (Windows, macOS, Linux), Mobile (iOS, Android), and Web (Wasm).

## 🛠️ Getting Started

### Prerequisites
- Flutter SDK (Latest Stable)
- Rust (for the core engine)
- `flutter_rust_bridge` dependencies

### Build & Run
1. From the project root, run the bridge build script:
   ```bash
   ./script/build_bridge.sh
   ```
2. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
3. Run the application:
   ```bash
   flutter run
   ```

## 📂 Project Structure
- `lib/core`: Foundational logic and theme definitions.
- `lib/features`: Specific functional modules (Editor, Console, Plotting).
- `lib/widgets`: Reusable UI components.
- `lib/bridge`: FFI bindings to the Rust core.
- `markdown/`: Design plans and UI/UX documentation.

## 🗺️ UI Roadmap
See `markdown/UI_REDESIGN_PLAN.md` for a detailed implementation strategy.
