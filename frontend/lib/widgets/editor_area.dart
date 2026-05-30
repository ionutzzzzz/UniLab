import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/app_provider.dart';
import '../theme/ui_theme.dart';
import 'editor/enhanced_editor.dart';
import '../models/models.dart';
import '../models/editor_models.dart';

class EditorArea extends ConsumerWidget {
  const EditorArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = UiTheme.of(context);
    // Use legacy provider for AppProvider while we are still migrating
    final appProvider = legacy_provider.Provider.of<AppProvider>(context);

    if (appProvider.activeFile == null) {
      return _buildEmptyState(ui);
    }

    // Convert UniLabFile to OpenFile for the enhanced editor
    final activeFile = appProvider.activeFile!;
    final openFile = OpenFile(
      id: activeFile.id,
      name: activeFile.name,
      path: activeFile.path,
      content: activeFile.content,
      isDirty: activeFile.isModified,
    );

    return Container(
      color: ui.colors.canvas,
      child: Column(
        children: [
          _buildTabBar(context, appProvider, ui),
          Expanded(
            child: EnhancedCodeEditor(
              // Unique key tied to file ID forces a clean widget swap when toggling
              key: ValueKey('editor_${openFile.id}'),
              file: openFile,
              onChanged: (val) => appProvider.updateActiveFileContent(val),
              onSave: () => appProvider.saveActiveFile(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, AppProvider appProvider, UiTheme ui) {
    return Container(
      height: 35,
      decoration: BoxDecoration(
        color: ui.colors.ribbonTabs,
        border: Border(
          bottom: BorderSide(color: ui.colors.border, width: ui.spacing.strokeHair),
        ),
      ),
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: appProvider.openFiles.length,
        onReorder: (oldIndex, newIndex) => appProvider.reorderOpenFile(oldIndex, newIndex),
        // buildDefaultDragHandles: false means we MUST use a listener
        buildDefaultDragHandles: false, 
        proxyDecorator: (child, index, animation) {
          return Material(
            elevation: 4,
            color: Colors.transparent,
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final file = appProvider.openFiles[index];
          final isActive = index == appProvider.activeFileIndex;

          return _buildTab(context, appProvider, file, index, isActive, ui);
        },
      ),
    );
  }

  Widget _buildTab(
    BuildContext context, 
    AppProvider appProvider, 
    UniLabFile file, 
    int index, 
    bool isActive, 
    UiTheme ui
  ) {
    // ReorderableDelayedDragStartListener ensures that normal clicks (taps) 
    // are NOT captured as drags, fixing the "cannot toggle" issue.
    // A slight hold is now required to start a drag.
    return ReorderableDelayedDragStartListener(
      key: ValueKey('tab_${file.id}'),
      index: index,
      child: Material(
        color: isActive ? ui.colors.canvas : ui.colors.ribbonTabs,
        child: InkWell(
          onTap: () {
            debugPrint('EditorArea: Tab clicked at index $index (${file.name})');
            appProvider.setActiveFile(index);
          },
          hoverColor: ui.colors.hover.withValues(alpha: 0.5),
          child: Container(
            width: 160,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isActive ? ui.colors.accent : Colors.transparent,
                  width: 2.0,
                ),
                right: BorderSide(
                  color: ui.colors.border,
                  width: ui.spacing.strokeHair,
                ),
                bottom: BorderSide(
                  color: isActive ? ui.colors.canvas : ui.colors.border,
                  width: 1,
                ),
              ),
              gradient: isActive ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ui.colors.accent.withValues(alpha: 0.05),
                  ui.colors.canvas,
                ],
              ) : null,
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.fileCode,
                  size: 14,
                  color: isActive ? ui.colors.accent : ui.colors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    file.name,
                    overflow: TextOverflow.ellipsis,
                    style: ui.typography.body.copyWith(
                      fontSize: 12,
                      color: isActive ? ui.colors.textPrimary : ui.colors.textMuted,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (file.isModified)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: ui.colors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                _buildCloseButton(context, appProvider, index, ui),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, AppProvider appProvider, int index, UiTheme ui) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint('EditorArea: Closing file at index $index');
          appProvider.closeFile(index);
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(LucideIcons.x, size: 12, color: ui.colors.textDisabled),
        ),
      ),
    );
  }

  Widget _buildEmptyState(UiTheme ui) {
    return Container(
      color: ui.colors.canvas,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.code, size: 48, color: ui.colors.border),
            const SizedBox(height: 16),
            Text(
              'No files open',
              style: ui.typography.body.copyWith(
                fontSize: 14,
                color: ui.colors.textDisabled,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Open a script from the explorer to begin.',
              style: ui.typography.label.copyWith(
                color: ui.colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
