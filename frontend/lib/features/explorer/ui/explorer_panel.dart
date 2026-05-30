import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart' as p;
import 'package:path/path.dart' as path_utils;
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_icon_button.dart';
import '../../../providers/app_provider.dart';

class ExplorerPanel extends ConsumerStatefulWidget {
  const ExplorerPanel({super.key});

  @override
  ConsumerState<ExplorerPanel> createState() => _ExplorerPanelState();
}

class _ExplorerPanelState extends ConsumerState<ExplorerPanel> {
  final Set<String> _expandedPaths = {};

  void _toggleExpand(String path) {
    setState(() {
      if (_expandedPaths.contains(path)) {
        _expandedPaths.remove(path);
      } else {
        _expandedPaths.add(path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final appProvider = p.Provider.of<AppProvider>(context);

    return Container(
      color: ui.colors.panel,
      child: Column(
        children: [
          // Header
          Container(
            height: 38,
            padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: ui.colors.panelHeader,
              border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    UiText(
                      text: 'Explorer',
                      variant: UiTextVariant.body,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ],
                ),
                Row(
                  children: [
                    UiIconButton(icon: LucideIcons.filePlus, tooltip: 'New File', size: 24, iconSize: 14, onPressed: () => appProvider.addNewFile()),
                    SizedBox(width: ui.spacing.xs),
                    UiIconButton(icon: LucideIcons.refreshCcw, tooltip: 'Refresh', size: 24, iconSize: 14, onPressed: () => appProvider.refreshProjectFiles()),
                  ],
                ),
              ],
            ),
          ),
          // Tree View
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: ui.spacing.xs),
              children: [
                _buildSectionHeader(ui, 'PROJECT'),
                if (appProvider.projectFiles.isEmpty)
                  _buildEmptyState(ui)
                else
                  ..._buildProjectTree(appProvider.projectFiles, 0, ui, appProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProjectTree(List<dynamic> entities, int depth, UiTheme ui, AppProvider appProvider) {
    List<Widget> items = [];
    
    for (var entity in entities) {
      final isDir = entity is io.Directory;
      final path = entity.path;
      final name = path_utils.basename(path);
      final isExpanded = _expandedPaths.contains(path);

      items.add(_FileTreeRow(
        name: name,
        path: path,
        isDir: isDir,
        depth: depth,
        isExpanded: isExpanded,
        onToggle: () {
          if (isDir) {
            _toggleExpand(path);
          } else {
            appProvider.openFile(entity);
          }
        },
      ));

      if (isDir && isExpanded) {
        // This is a simplified version. Ideally AppProvider would have a recursive structure
        // or we'd list directories on demand. For now, let's assume we can list it.
        try {
          final children = entity.listSync();
          items.addAll(_buildProjectTree(children, depth + 1, ui, appProvider));
        } catch (e) {
          // Access denied or other error
        }
      }
    }
    
    return items;
  }

  Widget _buildSectionHeader(UiTheme ui, String title) {
    return Padding(
      padding: EdgeInsets.only(left: ui.spacing.md, top: ui.spacing.sm, bottom: ui.spacing.xxs),
      child: Row(
        children: [
          Icon(LucideIcons.files, size: 10, color: ui.colors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          UiText(
            text: title,
            variant: UiTextVariant.label,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: ui.colors.textMuted.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: ui.colors.divider.withValues(alpha: 0.2), height: 1)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(UiTheme ui) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.folderOpen, size: 40, color: ui.colors.textDisabled),
            const SizedBox(height: 16),
            UiText(
              text: 'Empty folder',
              variant: UiTextVariant.body,
              color: ui.colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _FileTreeRow extends StatefulWidget {
  const _FileTreeRow({
    required this.name,
    required this.path,
    required this.isDir,
    required this.depth,
    required this.isExpanded,
    required this.onToggle,
  });

  final String name;
  final String path;
  final bool isDir;
  final int depth;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  State<_FileTreeRow> createState() => _FileTreeRowState();
}

class _FileTreeRowState extends State<_FileTreeRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final double paddingLeft = widget.depth * 12.0 + ui.spacing.sm;

    IconData getFileIcon(String name) {
      final lowerName = name.toLowerCase();
      if (lowerName.endsWith('.m')) return LucideIcons.fileCode2;
      if (lowerName.endsWith('.csv') || lowerName.endsWith('.xlsx')) return LucideIcons.table2;
      if (lowerName.endsWith('.md')) return LucideIcons.fileText;
      if (lowerName.endsWith('.json') || lowerName.endsWith('.yaml')) return LucideIcons.fileJson;
      if (lowerName.endsWith('.png') || lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) return LucideIcons.fileImage;
      if (lowerName.endsWith('.pdf')) return LucideIcons.fileText;
      if (lowerName.endsWith('.mp3') || lowerName.endsWith('.wav')) return LucideIcons.fileAudio;
      return LucideIcons.file;
    }

    Color getIconColor(String name) {
      final lowerName = name.toLowerCase();
      if (lowerName.endsWith('.m')) return const Color(0xFFB3CDE3);
      if (lowerName.endsWith('.md')) return const Color(0xFFCCEBC5);
      return ui.colors.icon;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (widget.isDir) {
            widget.onToggle();
          } else {
            // Get AppProvider from context and open the file
            final appProvider = p.Provider.of<AppProvider>(context, listen: false);
            appProvider.openFile(io.File(widget.path));
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 24,
          padding: EdgeInsets.only(left: paddingLeft, right: ui.spacing.sm),
          decoration: BoxDecoration(
            color: _isHovered ? ui.colors.accent.withValues(alpha: 0.15) : Colors.transparent,
          ),
          child: Row(
            children: [
              if (widget.isDir)
                Icon(
                  widget.isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                  size: 12,
                  color: ui.colors.textMuted,
                )
              else
                const SizedBox(width: 12),
              const SizedBox(width: 6),
              Icon(
                widget.isDir 
                  ? (widget.isExpanded ? LucideIcons.folderOpen : LucideIcons.folder) 
                  : getFileIcon(widget.name),
                size: 14,
                color: widget.isDir ? const Color(0xFFB3CDE3) : getIconColor(widget.name),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: UiText(
                  text: widget.name,
                  variant: UiTextVariant.body,
                  fontSize: 12,
                  color: _isHovered ? ui.colors.textPrimary : ui.colors.textSecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}