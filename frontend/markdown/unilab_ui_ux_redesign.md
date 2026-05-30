# UniLab — IDE Redesign Blueprint

> A senior-level UI/UX and Flutter engineering plan to rebuild UniLab as a modern, premium desktop IDE for simulations, numerical analysis, modeling, and research. Inspired by MATLAB R2025, refined by VS Code's density and JetBrains' polish, and adapted to Flutter desktop best practices.

This document serves as the primary frontend redesign specification and the source of truth for the UniLab UI rewrite.

---

## 1. Design Audit & Product Principles

### 1.1 Product Principles (The Lens for Every Decision)

1. **Scientific IDE Workflow:** Transform UniLab into a professional desktop-class scientific IDE focused on numerical computing, simulations, data analysis, modeling, research, engineering workflows, and scientific scripting.
2. **Density is a Feature:** Researchers run UniLab in a window next to a paper PDF and a terminal. Every extra pixel of chrome is one fewer line of code visible. Default to *compact*; let users opt up.
3. **Keyboard Before Mouse:** Anything reachable by ribbon must also be reachable by command palette and ideally a shortcut.
4. **The Editor is the Hero:** Ribbon, sidebars, console — all of them must visually defer to the editor surface. Zero color competition; muted icons; recessed chrome.
5. **No Mystery State:** Variables, run status, kernel state, file dirty markers — always visible, never hidden behind a click.
6. **Flat, Not Floppy:** Sharp 1px borders, near-zero radii on shell panels, modest radii (6px) only on transient surfaces (popovers, menus, the palette). Avoid excessive card-based layouts and generic mobile-app styling.

---

## 2. MATLAB 2025 Inspired Features & Architecture

We aim to deliver an experience comparable to MATLAB 2025 and VS Code without merely cloning them. 

### 2.1 Workspace Experience
- **Variable Explorer:** Live representation of runtime variables.
- **Workspace Browser:** Intuitive tree/grid for navigating variables and objects.
- **Dataset Viewer & Data Inspector:** Deep inspection of matrices, dataframes, and arrays.
- **Memory Management Views:** Track memory usage of active variables and kernel state.

### 2.2 Editor Experience
Target quality comparable to VS Code and MATLAB Editor:
- **Advanced Code Editor:** Robust editing surface.
- **Syntax Highlighting & Formatting:** Professional syntax colors and code auto-formatting.
- **Minimap & Breadcrumbs:** Fast navigation across large scripts.
- **Code Folding & Auto-completion:** Reduce cognitive load.
- **Function Navigation & Multi-cursor support:** High-productivity text manipulation.
- **Diagnostics Panel & Error Highlighting:** Inline squiggles with clear, actionable problem panels.
- **Search and Replace:** Fully featured find/replace bar.
- **Editor Tabs:** Support for multiple open scripts, dirty markers, and context menus.

### 2.3 Integrated Terminal Experience
Do not create a fake terminal UI. Integrate with actual system processes using `xterm.dart` and `pty`.
- **Windows:** PowerShell or PowerShell Core (if available).
- **Linux:** User default shell (`bash`, `zsh`, `fish`).
- **macOS:** User default shell (`zsh`, `bash`).
- **Features:** Persistent sessions, multiple terminal tabs, terminal history, ANSI colors, resize support, split terminals, and terminal panel docking.

### 2.4 Project Management
- **Project & File Explorer:** Fast file tree for navigating the current workspace.
- **Search Panel:** Global project-wide search.
- **Open Editors Panel:** Quick access to dirty/open files.
- **Recent Projects & Workspace Management:** Quickly swap between environments.

### 2.5 Analysis Tools
- **Plot Management & Figure Windows:** Rich visualizations integrated directly into the UI or as detached windows.
- **Simulation Results Viewer:** Tailored tools for modeling outputs.
- **Data Tables & Model Explorer:** Structured views of algorithms.
- **Research Notebooks & Output Management:** Save, document, and reproduce findings easily.

### 2.6 Layout System
Support professional IDE layouts:
- **Dockable & Resizable Panels:** Use `multi_split_view` and similar tools.
- **Persistent Panel State:** Remember exact panel dimensions across sessions.
- **Saved Workspaces:** Named layouts.
- **Multiple Screen Support & Flexible Sidebars:** Tailor to heavy multi-monitor setups.

---

## 3. Flutter Architecture Modernization

Refactor toward a scalable architecture favoring composition over inheritance. 

### 3.1 Design System
A strict design token layer to handle responsive desktop behavior and theme consistency:
- `AppTheme`: The central hub for injecting themes via `ThemeExtension`.
- `ColorTokens`: Semantic mapping (e.g., `surface.panel`, `text.muted`).
- `TypographyTokens`: Role-tied scales (`ui.title`, `code.body`) rather than generic MD3 styles.
- `SpacingTokens`: Rigid constants for `space.sm`, `radius.md`, etc.
- `ElevationTokens` & `AnimationTokens`: Flat design defaults, snappy/invisible motion (e.g., 90ms ease-out hover states).

### 3.2 Reusable Component Library
Create reusable widgets for:
- IDE panels & Workspace panels
- Toolbars & Status bars
- Sidebars & Terminal containers
- Tabs, Split views, and Data viewers.

### 3.3 Layout & State Management System
- **State Management:** Riverpod to decouple UI components, ensuring 60fps performance during long simulations.
- **Command Model:** A unified `CommandRegistry` for every menu item, ribbon button, keyboard shortcut, and command-palette entry. 
- **Layout Architecture:** Dedicated Panel Manager and Workspace Manager for handling docking, splits, and breakpoints.

---

## 4. Visual Design Refresh — Soft "Pastel Slate" Aesthetic

Design goals inspired by MATLAB 2025's modern web/desktop iteration:
- **Premium Dark Theme (Muted/Pastel):** Instead of harsh blacks (`#000000`) and grays (`#1E1E1E`), the UI adopts a calm, professional slate aesthetic. 
    - Canvas (Editor background): `#1E2127`
    - Shell Panels (Sidebars, console): `#252A31`
    - Headers & Overlays: `#2B3038`
- **Soft Accent Colors:** Replace harsh primary blues (`#007ACC`) with a softer pastel accent (`#4AA3FF`).
- **Clean Typography & Spacing:** Use slightly rounded components (6px - 8px radii) for transient surfaces, but keep panel lines sharp (1px dividers using `#3A414C`).
- **Syntax Highlighting:** A softer, pastel-inspired syntax theme (similar to Nord or Tokyo Night) to reduce eye strain during long coding sessions. Muted pinks, soft teals, and calm blues.

---

## 5. Implementation Roadmap

Sequenced for **continuous shippability** — every phase must yield production-quality code.

### Phase 0 — Foundations (Completed)
- Create strict design tokens (`UiTheme`, `UiColors`, `UiTypography`).
- Build atom widgets (`UiButton`, `UiInputField`, `UiIcon`).
- Hide default title bar via `window_manager`.

### Phase 1 — Shell Skeleton (Completed)
- Build the persistent 5-zone shell (`MainShell`, `SplitShell`).
- Implement layout persistence and shell breakpoints.
- Build the `StatusBar` with priority-sorted left/right slots.

### Phase 2 — Editor (Completed)
- Replace generic textfields with `flutter_code_editor`.
- Implement `EditorTabBar`, `EditorBreadcrumbs`, and `GutterStyle`.
- Support multiple editor tabs.

### Phase 3 — Command Model & Ribbon (Completed)
- Implement `CommandRegistry` for uniform actions.
- Build the `RibbonTabBar`, `RibbonBody`, and `RibbonButton`s.
- Implement the Command Palette (`⌘K`) using fuzzy search.

### Phase 4 — Workspace & Console (Completed)
- Implement `WorkspaceSegmented` switchers for Variables, Inputs, Plots, Help.
- Build data grids using `pluto_grid`.
- Build `ConsoleDock` with Problems, Terminal, and Run tabs.

### Phase 5 — Terminal Integration (Completed)
- Integrate `xterm.dart` and `pty` for a real OS shell.
- Add split terminal and session management.

### Phase 6 — Visual Refinement & Polish (Completed)
- **Soft "Pastel Slate" Theme:** Successfully transitioned the entire UI from high-contrast black/gray to a softer, more professional slate palette (`#1E2127`, `#252A31`, `#2B3038`).
- **Pastel Accents:** Replaced harsh primary blues with a calming pastel blue (`#4AA3FF`).
- **Refined Component Geometry:** Updated border radii across the application (6px - 10px) to match the modern aesthetic of refined desktop IDEs.
- **Unified Tab Styling:** Synchronized the look of editor tabs, ribbon tabs, and console tabs for a cohesive experience.
- **Enhanced Data Grids:** Softened the appearance of `pluto_grid` in the variables workspace with refined borders and pastel tones.
- **Pastel Syntax Theme:** Updated the code editor's default syntax highlighting to use a muted, eye-friendly palette.

### Phase 7 — Advanced Workspace & Project Management (Future)
- Data Inspector & Memory Management Views.
- True panel tearing / docking via `docking` package.
- Saved workspaces and multi-window figure support.
- Collaborative cursors and research notebooks.

---

*Last updated: 2026-05-30. Owner: the UniLab UI rewrite stream. When in doubt about a UI decision, this document is the tiebreaker; if this document is wrong, fix the document first, then the code.*