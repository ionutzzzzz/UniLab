# UniLab Flutter App - Professional UI/UX Redesign Plan

## Vision

Transform the UniLab Flutter app to match the professional, polished look and feel of **MATLAB R2025**, **Microsoft Office (Word/Excel)**, and modern desktop IDEs like **VS Code**. The result will be a sophisticated, productive application that feels enterprise-grade with intelligent layout management, drag-and-drop capabilities, and customizable workspace.

---

## Design Reference Analysis

### Key Characteristics from Reference UIs:

1. **MATLAB R2025**

   - Left sidebar: File browser / Project explorer (collapsible/resizable)
   - Center area: Main editor/canvas (dominant space)
   - Right sidebar: Workspace/Variables panel (properties/state)
   - Top ribbon: Tabbed navigation (HOME, PLOTS, APPS, EDITOR, PUBLISH, VIEW)
   - Bottom: Command window / Console output
   - Clean dark theme with accent colors (blue/cyan)
2. **Microsoft Office (Word/Excel)**

   - Top ribbon with tabs (File, Home, Insert, Design, Layout, Review, View)
   - Sub-menus and button groups under each tab
   - Quick access toolbar at the top
   - Modern flat design with hover states
   - Right sidebar: Properties/Settings panel
   - Left sidebar: Navigation/Styles panel
3. **VS Code / Professional Editors**

   - Modular panel system (resizable, collapsible)
   - Drag-and-drop support for rearranging panels
   - Quick action buttons in sidebars
   - Status bar at bottom
   - Customizable color schemes and preferences

---

## Overall Layout Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ UniLab | File  Edit  View  Insert  Tools  Help        🔍 🛠️ ⊙  │ <- Top Menu Bar
├─────────────────────────────────────────────────────────────────┤
│ 🏠 Home │ 📊 Plots │ 📱 Apps │ 📝 Editor │ 🔧 Tools    [View ▼] │ <- Ribbon/Tabs Bar
├────────┬──────────────────────────────────────────┬─────────────┤
│        │                                          │             │
│ Files  │                                          │ Properties  │
│ 📁 src │       MAIN EDITOR/CANVAS AREA           │ & Workspace │
│ 📁 data│                                          │             │
│ 📄 f.m │       (Code Editor / Script View)       │ 📊 Variables│
│ 📄 s.m │                                          │ 🔍 Inputs   │
│        │                                          │ 📈 Plots    │
│ ☰ More │                                          │ ⚙️ Settings │
│        │                                          │             │
├────────┴──────────────────────────────────────────┴─────────────┤
│ ► Run | ⏸ Stop | 🐛 Debug  [Output] [Issues] [Terminal]         │ <- Bottom Panel
└────────────────────────────────────────────────────────────────┘
```

---

## Detailed Implementation Plan

### Phase 1: Core Layout Architecture

**Goal**: Implement the foundational 3-panel system with resizable sections

#### 1.1 New Main Layout System

- **File**: `lib/widgets/layouts/main_layout.dart`
- **Components**:
  - Multi-split view for 3-panel layout (Left | Center | Right)
  - Resizable dividers between panels
  - Collapsible sidebar buttons (hamburger menu icons)
  - Visibility toggles for each panel

#### 1.2 Left Sidebar - File Browser Panel

- **File**: `lib/widgets/panels/file_browser_panel.dart`
- **Features**:
  - Tree view of project files with icons
  - Expandable/collapsible folders
  - Right-click context menu (Open, Rename, Delete, etc.)
  - Search filter for files
  - Favorite/Pin files
  - Double-click to open in editor
  - Drag-and-drop support for file organization

#### 1.3 Center Area - Main Editor/Canvas

- **File**: `lib/widgets/panels/editor_panel.dart`
- **Features**:
  - Syntax-highlighted code editor (already present)
  - Tab system for multiple open files
  - File modification indicators (dot on tab)
  - Close button on each tab
  - "+" button to create new file
  - Line numbers, code folding, minimap

#### 1.4 Right Sidebar - Workspace/Properties Panel

- **File**: `lib/widgets/panels/workspace_panel.dart`
- **Features**:
  - Expandable sections (Accordion-style):
    - 📊 **Variables/Workspace**: Display script variables, types, values
    - 🔍 **Inputs**: Input parameters panel
    - 📈 **Plots**: Thumbnail previews of generated plots
    - ⚙️ **Settings**: Quick access to local settings
  - Properties inspector for selected objects
  - Real-time variable updates during script execution

#### 1.5 Bottom Panel - Output/Console

- **File**: `lib/widgets/panels/console_panel.dart`
- **Features**:
  - Command window / Console output
  - Tabs: [Output] [Issues/Warnings] [Terminal] [Debug]
  - Clear button, Search in console
  - Copy/Export output
  - Auto-scroll toggle

### Phase 2: Top Navigation & Ribbon System

**Goal**: Implement professional menu and ribbon UI

#### 2.1 Menu Bar with Tabs

- **File**: `lib/widgets/top_bar/menu_bar.dart`
- **Tabs**: HOME | PLOTS | APPS | EDITOR | TOOLS | VIEW
- **Features**:
  - Tab-based navigation to switch views/modes
  - Dynamic ribbon content changes based on selected tab
  - Keyboard shortcuts displayed in menus
  - Help/Search icon in top-right corner

#### 2.2 Ribbon/Toolbar System

- **File**: `lib/widgets/top_bar/ribbon_bar.dart`
- **Structure**:
  - Icon buttons organized in groups (File, Edit, Run, Analyze, etc.)
  - Button groups separated by vertical dividers
  - Dropdown menus for related commands
  - Tooltips on hover
  - Quick actions (Save, Run, Stop)

#### 2.3 Quick Access Buttons

- **File**: `lib/widgets/top_bar/quick_actions.dart`
- **Buttons**:
  - 📁 New File / 💾 Save / 📂 Open
  - ▶️ Run / ⏸ Stop / 🐛 Debug
  - 🔄 Undo / ↩️ Redo
  - 🔍 Find / 🔄 Replace
  - 🌙 Dark/Light Theme Toggle

#### 2.4 Status Bar & System Tray

- **File**: `lib/widgets/bottom_bar/status_bar.dart`
- **Elements**:
  - Connection status (API/Backend)
  - Current mode indicator (Edit/Run/Debug)
  - Memory/CPU usage indicators
  - Line:Column indicator
  - Zoom level control
  - Notification bell

### Phase 3: Drag-and-Drop & Interactivity

**Goal**: Add drag-and-drop support for components and panels

#### 3.1 Draggable Panels

- **File**: `lib/widgets/draggable/draggable_panel.dart`
- **Features**:
  - Drag headers to reorder panels
  - Visual feedback during drag (highlight zones)
  - Snap to grid behavior
  - Persist layout configuration to SharedPreferences

#### 3.2 Draggable Components

- **File**: `lib/widgets/draggable/draggable_component.dart`
- **Examples**:
  - Drag plots from workspace to canvas
  - Drag variables into code
  - Drag files into editor
  - Drag components between panels (workspace → canvas)

#### 3.3 Drag-and-Drop File Browser

- **Enhancement to file_browser_panel.dart**
- **Features**:
  - Drag files to reorder
  - Drag files between folders
  - Drop zone indicators
  - Undo support

### Phase 4: Visualization & Plots System

**Goal**: Implement plot display and management

#### 4.1 Plot Gallery/Viewer

- **File**: `lib/widgets/panels/plots_panel.dart`
- **Features**:
  - Thumbnail grid view of plots
  - Large preview window
  - Plot metadata (size, type, creation time)
  - Export options (PNG, SVG, PDF)
  - Plot history with timestamps
  - Search/filter plots by name or type

#### 4.2 Plot Integration in Workspace

- **File**: `lib/widgets/plot_viewer/plot_widget.dart`
- **Features**:
  - Embedded plot viewer in right panel
  - Zoom and pan controls
  - Crosshair / measurement tools
  - Save plot button
  - Copy plot to clipboard

#### 4.3 Plot Rendering Engine

- **Dependencies**: Add `fl_chart` or `charts_flutter` to pubspec.yaml
- **File**: `lib/services/plot_service.dart`
- **Features**:
  - Render MATLAB-style plots
  - Support line plots, scatter, bar, heatmaps, 3D surface plots
  - Customizable colors, legends, axes labels

### Phase 5: Settings & Customization

**Goal**: Allow users to customize the UI to their preferences

#### 5.1 Settings Screen Enhancement

- **File**: `lib/screens/settings_screen.dart` (expand existing)
- **Categories**:

  **Appearance**:

  - Theme: Dark / Light / Custom
  - Color scheme: Blue (default), Green, Purple, Orange
  - Font family: Inter, Consolas, JetBrains Mono
  - Font size: 10-16px
  - Accent color picker
  - UI Scale: 0.8x - 1.5x

  **Workspace**:

  - Default panel visibility (which panels show on startup)
  - Panel sizes (relative widths)
  - Auto-hide sidebars
  - Smooth animations on/off
  - Remember layout on close

  **Editor**:

  - Tab size: 2/4/8 spaces
  - Line numbers on/off
  - Word wrap on/off
  - Syntax highlighting style
  - Minimap visible

  **Shortcuts**:

  - Customizable keyboard shortcuts
  - Export/import shortcuts
  - Reset to defaults

  **Notifications**:

  - Sound on run complete
  - Desktop notifications
  - Log level (Debug / Info / Warning / Error)

#### 5.2 Settings Provider Enhancement

- **File**: `lib/providers/settings_provider.dart` (expand existing)
- **New Fields**:
  - `themeColor`: Primary color
  - `accentColor`: Secondary color
  - `panelVisibility`: Map<String, bool> (left, right, bottom panels)
  - `panelSizes`: Map<String, double> (left_width, right_width)
  - `editorSettings`: CodeEditor configuration
  - `uiScale`: double
  - `animationEnabled`: bool
  - `remember_layout`: bool
  - `fontFamily`: String
  - `fontSize`: int

#### 5.3 UI Preferences Panel

- **File**: `lib/widgets/settings/ui_preferences_panel.dart`
- **Location**: Right sidebar → Settings section (when no workspace data)
- **Quick toggles**:
  - 🌙 Dark/Light mode
  - 👁️ Show/Hide file browser
  - 📊 Show/Hide workspace panel
  - 💾 Auto-save toggle
  - 🔔 Sound toggle

### Phase 6: Advanced Features

**Goal**: Add polish and productivity features

#### 6.1 Keyboard Shortcuts Manager

- **File**: `lib/services/shortcuts_service.dart`
- **Features**:
  - Global keyboard shortcuts
  - Custom shortcuts per mode (Edit/Run/Debug)
  - Shortcut help popup (Cmd+? / Ctrl+?)
  - Conflict detection

#### 6.2 Recent Files & Projects

- **File**: `lib/widgets/recent/recent_items.dart`
- **Features**:
  - Quick access menu
  - Pin favorite projects
  - Clear history option

#### 6.3 Search & Find System

- **File**: `lib/services/search_service.dart`
- **Features**:
  - Global file search (Ctrl+P / Cmd+P)
  - File content search (Ctrl+Shift+F)
  - Symbol search in code
  - Replace functionality

#### 6.4 Command Palette

- **File**: `lib/widgets/command_palette/command_palette.dart`
- **Features**:
  - Command search (Ctrl+Shift+P)
  - Quick access to any action
  - Fuzzy search
  - Command history

#### 6.5 Statusbar with Real-time Info

- **File**: `lib/widgets/status_bar/status_indicator.dart`
- **Indicators**:
  - Server connection status
  - Execution status (Idle / Running / Error)
  - Memory usage (if available)
  - Zoom level display

#### 6.6 Window Controls

- **File**: `lib/widgets/window_controls/window_controls.dart`
- **Features** (desktop only):
  - Minimize, Maximize, Close buttons
  - Window title bar customization
  - Menu access via title bar

---

## File Structure

```
lib/
├── main.dart (updated)
├── providers/
│   ├── app_provider.dart (updated)
│   └── settings_provider.dart (significantly expanded)
├── screens/
│   ├── main_screen.dart (refactored)
│   └── settings_screen.dart (expanded)
├── widgets/
│   ├── layouts/
│   │   └── main_layout.dart (NEW)
│   ├── panels/
│   │   ├── file_browser_panel.dart (NEW)
│   │   ├── editor_panel.dart (NEW)
│   │   ├── workspace_panel.dart (NEW)
│   │   ├── console_panel.dart (NEW)
│   │   ├── plots_panel.dart (NEW)
│   │   └── properties_panel.dart (NEW)
│   ├── top_bar/
│   │   ├── menu_bar.dart (NEW)
│   │   ├── ribbon_bar.dart (NEW)
│   │   └── quick_actions.dart (NEW)
│   ├── bottom_bar/
│   │   └── status_bar.dart (NEW)
│   ├── draggable/
│   │   ├── draggable_panel.dart (NEW)
│   │   └── draggable_component.dart (NEW)
│   ├── settings/
│   │   ├── ui_preferences_panel.dart (NEW)
│   │   ├── appearance_settings.dart (NEW)
│   │   ├── workspace_settings.dart (NEW)
│   │   └── shortcuts_settings.dart (NEW)
│   ├── command_palette/
│   │   └── command_palette.dart (NEW)
│   ├── recent/
│   │   └── recent_items.dart (NEW)
│   ├── window_controls/
│   │   └── window_controls.dart (NEW)
│   └── plot_viewer/
│       └── plot_widget.dart (NEW)
├── services/
│   ├── shortcuts_service.dart (NEW)
│   ├── search_service.dart (NEW)
│   └── plot_service.dart (NEW)
├── models/
│   ├── keyboard_shortcut.dart (NEW)
│   ├── panel_layout.dart (NEW)
│   └── plot_data.dart (NEW)
└── utils/
    ├── constants.dart (updated)
    └── theme_utils.dart (NEW)
```

---

## Updated pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  multi_split_view: ^3.1.0
  flutter_code_editor: ^0.3.5
  google_fonts: ^6.2.1
  file_picker: ^8.1.7
  path_provider: ^2.1.5
  http: ^1.2.2
  flutter_highlight: ^0.7.0
  shared_preferences: ^2.5.2
  path: ^1.9.1
  highlight: ^0.7.0
  
  # NEW DEPENDENCIES
  fl_chart: ^0.68.0                    # Plot rendering
  context_menus: ^1.0.0               # Right-click context menus
  window_manager: ^0.3.7              # Desktop window controls (Windows, macOS, Linux)
  desktop_drop: ^0.4.4                # Drag-drop support (desktop)
  intl: ^0.19.0                       # Internationalization
  fuzzy: ^0.4.0                       # Fuzzy search for command palette
  uuid: ^4.0.0                        # Unique IDs for components
  
  # Optional - for better desktop feel
  # bitsdojo_window: ^0.1.5            # Custom window chrome (alternative to window_manager)
  # sidebar_action_controller: ^0.0.2  # Collapsible sidebar management
```

---

## Development Phases & Timeline

### Phase 1: Foundation (2-3 weeks)

- [ ] Refactor main_screen.dart with 3-panel layout
- [ ] Implement file_browser_panel.dart
- [ ] Implement editor_panel.dart
- [ ] Implement workspace_panel.dart
- [ ] Implement console_panel.dart
- [ ] Set up multi_split_view with resizable dividers
- [ ] Add panel collapse/expand buttons

### Phase 2: Top Navigation (1-2 weeks)

- [ ] Implement menu_bar.dart with tabs
- [ ] Implement ribbon_bar.dart
- [ ] Implement quick_actions.dart
- [ ] Connect buttons to existing functionality
- [ ] Add keyboard shortcuts

### Phase 3: Interactivity (2-3 weeks)

- [ ] Implement draggable panels
- [ ] Add drag-drop file browser
- [ ] Implement file reordering
- [ ] Add visual feedback for drag operations
- [ ] Persist layout to SharedPreferences

### Phase 4: Settings & Customization (2 weeks)

- [ ] Expand settings_provider.dart
- [ ] Implement appearance_settings.dart
- [ ] Implement workspace_settings.dart
- [ ] Implement shortcuts_settings.dart
- [ ] Add UI scale support
- [ ] Add theme color picker

### Phase 5: Visualization (2 weeks)

- [ ] Add fl_chart dependency
- [ ] Implement plot_widget.dart
- [ ] Implement plots_panel.dart
- [ ] Add plot export functionality
- [ ] Integrate with script execution

### Phase 6: Polish (1-2 weeks)

- [ ] Implement command_palette.dart
- [ ] Implement search_service.dart
- [ ] Add status_bar.dart
- [ ] Add window_controls.dart (desktop)
- [ ] Refine animations and transitions
- [ ] Cross-browser/platform testing

### Phase 7: Testing & Optimization (1 week)

- [ ] Comprehensive UI testing
- [ ] Performance optimization
- [ ] Accessibility review
- [ ] Documentation

---

## Design System & Theme

### Color Palette

```
Primary:           #007ACC (Professional Blue)
Secondary:         #00A4EF (Light Blue)
Accent:            #CE9178 (Orange/Warn)
Success:           #4EC9B0 (Teal)
Error:             #F48771 (Red)

Dark Theme:
  Background:      #1E1E1E
  Surface:         #252526
  Sidebar:         #252526
  Toolbar:         #2D2D30
  Border:          #3F3F46
  Text:            #CCCCCC
  Text Secondary:  #858585
  Hover:           #3E3E42
  Active:          #007ACC

Light Theme (future):
  Background:      #FFFFFF
  Surface:         #F3F3F3
  Sidebar:         #ECECEC
  Toolbar:         #E0E0E0
  Border:          #D0D0D0
  Text:            #333333
  Text Secondary:  #666666
  Hover:           #E5E5E5
  Active:          #0078D4
```

### Typography

```
Font Family:       Inter, Segoe UI, Roboto
Monospace:         Consolas, 'JetBrains Mono', 'Courier New'
Body:              12px / 1.5
Heading:           14px bold
Label:             11px
Code:              11px monospace
```

### Spacing & Sizing

```
Unit:              4px
Padding:           8px, 12px, 16px, 24px
Border Radius:     2px (compact), 4px (default)
Icon Size:         16px (default), 20px (large), 12px (small)
Divider:           1px solid #3F3F46
```

---

## Migration Strategy

### Current State → New State

1. **Keep all existing functionality** in AppProvider and logic layers
2. **Refactor UI rendering** to use new panel-based architecture
3. **Preserve script execution** and variable tracking
4. **Maintain code editor** functionality with enhancements
5. **Enhance settings system** with new customization options

### Backward Compatibility

- All scripts and functionality remain compatible
- Settings migration: Add fallback defaults for new settings fields
- No breaking changes to APIs or providers

---

## Success Criteria

✅ **Visual & UX**

- Professional MATLAB/Office-like appearance
- 3-panel responsive layout with collapsible panels
- Smooth drag-and-drop interactions
- Accessible navigation and keyboard shortcuts
- Works seamlessly on desktop platforms (Windows, macOS, Linux)

✅ **Functionality**

- All existing features preserved and working
- New customization options fully functional
- Plot display and export working
- Settings persist across sessions
- Performance: < 100ms panel transitions, smooth 60 FPS UI

✅ **Code Quality**

- Clean, modular widget structure
- Proper separation of concerns
- Well-documented code
- No UI jank or lag

---

## Future Enhancements (Phase 8+)

- 🎨 Light theme support
- 📱 Mobile/tablet responsive layout variants
- 🌐 Multi-language support
- 🔌 Plugin system for custom components
- 📊 Advanced data visualization (3D plots, interactive dashboards)
- 🔗 Collaborative editing features
- 🧠 AI-assisted code completion
- 🎯 Custom workspace templates
- 🔐 User authentication & cloud sync
- 📦 Built-in package manager UI

---

## Notes for Implementation

1. **Test on multiple platforms**: Windows, macOS, Linux - ensure layout looks good on all
2. **Responsive sizing**: Use MediaQuery to adapt to different screen sizes
3. **Performance**: Use const constructors, avoid rebuilds, implement proper key management
4. **Accessibility**: ARIA labels, keyboard navigation, proper contrast ratios
5. **Documentation**: Add inline comments for complex widgets and logic
6. **Version control**: Commit each phase separately for easier review and rollback
7. **User feedback**: Consider adding telemetry to understand which features users prefer

---

## References

- MATLAB R2025 UI: Professional multi-panel layout, ribbon interface
- Microsoft Office: Tab-based navigation, ribbon buttons, right-side properties
- VS Code: Resizable panels, command palette, customizable workspace
- Flutter Best Practices: Modular widgets, provider pattern, responsive design
- Material Design 3: Dark theme, accessibility, spacing guidelines

##  📋 Plan Summary

  Layout Vision

  Transform the app to match MATLAB 2025 and Microsoft Office with:

- Left Sidebar: File browser (collapsible)
- Center: Main editor/canvas (dominant)
- Right Sidebar: Workspace/properties panel
- Top: Ribbon/tabs navigation (HOME, PLOTS, APPS, EDITOR, TOOLS, VIEW)
- Bottom: Console/output panel

  6 Implementation Phases

1. Core Layout - 3-panel system with resizable dividers
2. Top Navigation - Menu bar with ribbon & quick actions
3. Drag-and-Drop - Draggable panels & components
4. Visualization - Plot gallery & viewer system
5. Settings - Customizable appearance, workspace, shortcuts
6. Polish - Command palette, search, status bar, window controls

  Key Features Planned

  ✅ Collapsible/resizable panels with drag-and-drop
  ✅ Professional dark theme (MATLAB-style)
  ✅ Customizable UI: colors, fonts, scale, theme
  ✅ File browser with tree view & search
  ✅ Tab-based editor with multiple files
  ✅ Workspace variables display
  ✅ Plot gallery with export
  ✅ Keyboard shortcuts manager
  ✅ Command palette
  ✅ Real-time status indicators

  New Dependencies

  Includes FL Chart (plots), Context Menus, Window Manager, Drag-Drop support, Fuzzy search, and more.
