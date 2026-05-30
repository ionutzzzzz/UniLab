# UniLab Frontend Improvement Plan

## 1. Current UI/UX Analysis

### 1.1 Strengths
- **Modular Shell:** The 5-zone shell (Title, Ribbon, Sidebar, Editor, Console) provides a solid foundation.
- **Theme System:** `UiTheme` and `UiColors` allow for consistent styling.
- **Ribbon Interface:** The MATLAB-inspired ribbon is a great differentiator.
- **Pastel Slate Aesthetic:** The color palette is professional and easy on the eyes.

### 1.2 Weaknesses
- **Visual "Flatness":** Some areas lack depth and contrast, making it hard to distinguish between active and inactive elements.
- **Inconsistent Density:** Some panels feel too crowded, while others have wasted space.
- **Limited Interactivity:** Variables and plots panels are functional but don't feel "alive."
- **Desktop Polish:** Missing those "extra mile" features like smooth transitions, subtle blurs, and high-quality iconography.

## 2. MATLAB-Inspired Features to Add/Improve

- **Enhanced Variable Explorer:** A true spreadsheet-like view for matrices and dataframes with sorting and filtering.
- **Integrated Plot Gallery:** A dedicated space for viewing, managing, and exporting generated plots.
- **Command History:** A persistent, searchable history of commands entered in the console.
- **Contextual Ribbon Tabs:** Tabs that appear only when relevant (e.g., a "PLOT" tab when a figure is active).

## 3. Visual & Layout Improvements

### 3.1 Beauty
- **Depth & Shadows:** Use subtle multi-layered shadows for floating elements and active tabs.
- **Micro-interactions:** Add 100ms-200ms transitions for hover states, tab switches, and panel collapses.
- **Refined Typography:** Optimize line heights and letter spacing for the "Inter" and "JetBrains Mono" fonts.
- **Iconography:** Audit the current icon set and ensure consistent stroke weights and styles.

### 3.2 Polish
- **Glassmorphism:** Apply subtle `BackdropFilter` (blur) to the command palette and context menus.
- **Border Treatments:** Use multi-colored borders (e.g., a lighter top border) to give panels a 3D "beveled" feel without being dated.
- **Empty States:** Design beautiful, helpful empty states for the explorer and workspace.

### 3.3 Layout
- **Dynamic Resizing:** Improve the `SplitShell` to feel more fluid when resizing panels.
- **Status Bar Utility:** Add more real-time info like memory usage, current environment, and background task progress.

## 4. Implementation Roadmap

### Phase A: Design System & Atom Refinement
- Update `UiColors` with more granular tokens for shadows and blurs.
- Refine `UiButton`, `UiTab`, and `UiPanelHeader`.
- Implementation of "Glass" components.

### Phase B: Shell & Navigation Polish
- Refine `TitleStrip` with platform-specific window controls.
- Add animations to `AppRibbon` and `SplitShell`.
- Improve the `CommandPalette` UI.

### Phase C: Feature-Specific Enhancements
- Upgrade `WorkspacePanel` with `PlutoGrid` for variable inspection.
- Build the `PlotGallery` widget.
- Enhance the `ConsoleDock` with better tab styling.

### Phase D: Final Polish & QA
- Holistic review of spacing and alignment.
- Performance optimization for smooth 60fps animations.
- Accessibility audit.
