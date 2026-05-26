# UniLab UI/UX Redesign Blueprint: Achieving Professional IDE Standards

This document outlines a comprehensive architectural and visual redesign to elevate the Flutter-based UniLab interface. The goal is to achieve the premium, highly functional aesthetic of industry-standard tools like MATLAB 2025R and Microsoft Word, optimizing specifically for heavy simulation, numerical analysis, and engineering workflows.

---

## 1. Critical Bug Fixes (Immediate Remediation)

Before polishing the aesthetics, the core layout constraints must be stabilized.

### 1.1. Ribbon Overflow ("BOTTOM OVERFLOWED BY 4.0 PIXELS")
The red and yellow warning tape under the "Run" section is a standard Flutter layout exception. It occurs when a child widget (likely a `Column` containing the icon and text) exceeds the fixed vertical bounds of its parent container.
* **The Fix:** Wrap the text labels under the ribbon icons in an `Expanded` or `Flexible` widget, or adjust the parent container's height to accommodate the font scaling. Ensure `Text` widgets have `overflow: TextOverflow.ellipsis` and `maxLines: 1`. 
* **UX Impact:** Prevents the UI from breaking on different monitor resolutions or OS scaling settings.

### 1.2. The Line Numbering Glitch
The line index in the editor is still wrapping digits inappropriately (e.g., displaying `1` and `4` vertically instead of `14`). 
* **The Fix:** The container holding the line numbers must have a strictly defined, fixed width. 
* **Implementation:**
    ```dart
    Container(
      width: 45.0, // Fixed width prevents wrapping
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 8.0),
      color: Color(0xFF252526), // Subtle contrast from editor background
      child: Text(
        lineNumber.toString(),
        style: TextStyle(
          fontFamily: 'JetBrains Mono', // STRICTLY Monospace
          color: Colors.grey[600],
        ),
        maxLines: 1,
        overflow: TextOverflow.clip, // Never wrap line numbers
      ),
    )
    ```

### 1.3. The Debug Banner
The yellow and black striped banner in the top right corner is the Flutter `Debug` banner interacting strangely with the window controls. 
* **The Fix:** Set `debugShowCheckedModeBanner: false` in your `MaterialApp` root widget to instantly clean up the title bar.

---

## 2. The Ribbon & Navigation Architecture (The "Word/MATLAB" Feel)

Professional tools use the ribbon to categorize complex actions without cluttering the main workspace. Your current ribbon is too sparse and the icons are too prominent.

### 2.1. Iconography and Density
* **Scale Down:** Reduce the size of the ribbon icons by at least 20%. Professional IDEs prioritize code space over UI elements.
* **Grouping:** Use subtle `VerticalDivider` widgets to separate logical groups (e.g., `File Operations` | `Execution` | `Environment`).
* **Action Text:** The text beneath the icons (e.g., "Run Section", "Stop") needs a smaller, cleaner sans-serif font (like Inter or Roboto, size 10-11pt) with reduced opacity (e.g., 70% white) so it doesn't compete with the editor text.

### 2.2. Tab States
The "HOME", "PLOTS", "EDITOR" tabs currently feel like plain text. 
* **Active State:** The active tab should have a distinct background color that merges seamlessly with the ribbon background below it, creating a unified physical "folder tab" look. 
* **Hover State:** Implement a subtle lighter background fill when hovering over inactive tabs.

---

## 3. Workspace Panel (Optimized for Analysis)

When debugging state-space models, computing Markov parameters, or inspecting large Hankel matrices, a floating "No variables in workspace" text is insufficient. The workspace needs to feel like a data laboratory.

### 3.1. Tabular Structure (Always On)
Even when the workspace is empty, it should display a data grid header. This establishes expectations for the user.
* **Headers:** `Name` | `Value` | `Size` | `Class` | `Min` | `Max`
* **Implementation:** Use a package like `pluto_grid` or `syncfusion_flutter_datagrid` to create a robust, resizable data table. This allows users to sort variables by size or class instantly.

### 3.2. Visual Hierarchy
* Remove the `Workspace`, `Variables`, `Inputs`, `Plots` nested accordion dropdowns if they aren't strictly necessary. Flat, tabbed structures at the bottom or top of the side panel are much faster to navigate than accordions.

---

## 4. Editor and Terminal Polish

The editor is the focal point. It must be visually flawless.

### 4.1. Strict Typography
* **The Rule:** The Editor and the Terminal/Output MUST use a dedicated programming font. `JetBrains Mono`, `Fira Code`, or `Cascadia Code` are highly recommended. 
* **Sizing:** Default editor font size should be around 14pt with a line height of 1.4 or 1.5 to prevent code from feeling cramped.

### 4.2. Terminal Layout
* **Padding:** The `>> Ready` prompt is touching the absolute left edge. Add a `Padding` of at least `12.0` pixels around the inner content of the terminal.
* **Input Field:** The "Filter output..." box is massively oversized. It should be a compact, subtle search bar (max height 28px) aligned to the right side of the terminal tab bar, not spanning the entire width above the console.

### 4.3. Editor Gutter and Active Line
* **Gutter:** Make the background color of the line number column slightly different from the main code area (e.g., Editor: `#1E1E1E`, Gutter: `#252526`).
* **Active Line Highlight:** Implement a feature where the line the cursor is currently on has a very faint, full-width highlight (e.g., `#2C2C2D`). This is standard in all modern IDEs and prevents losing track of the cursor during complex algorithmic work.

---

## 5. Global Panel Management

To truly mimic MATLAB's customizable layout:
* **Draggable Splitters:** The borders between "FILES", "EDITOR", and "WORKSPACE" must be draggable. Users need to be able to collapse the file tree entirely to focus on code and matrix outputs. Consider the `multi_split_view` Flutter package for robust, native-feeling panel resizing.
* **Borders:** Use a very subtle, dark grey (`#333333`) for all panel borders. Avoid thick lines; 1px borders are sufficient to define the structural boundaries of the IDE.
