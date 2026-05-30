import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_icon_button.dart';
import '../state/explorer_providers.dart';
import '../domain/file_node.dart';

class ExplorerPanel extends ConsumerStatefulWidget {
  const ExplorerPanel({super.key});

  @override
  ConsumerState<ExplorerPanel> createState() => _ExplorerPanelState();
}

class _ExplorerPanelState extends ConsumerState<ExplorerPanel> {
  final Set<String> _expandedPaths = {'/', '/src'};

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
    final rootAsync = ref.watch(explorerRootProvider);

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
                    UiIconButton(icon: LucideIcons.filePlus, tooltip: 'New File', size: 24, iconSize: 14),
                    SizedBox(width: ui.spacing.xs),
                    UiIconButton(icon: LucideIcons.folderPlus, tooltip: 'New Folder', size: 24, iconSize: 14),
                    SizedBox(width: ui.spacing.xs),
                    UiIconButton(icon: LucideIcons.refreshCcw, tooltip: 'Refresh', size: 24, iconSize: 14),
                  ],
                ),
              ],
            ),
          ),
          // Tree View
          Expanded(
            child: rootAsync.when(
              data: (root) {
                final recentFiles = ref.watch(recentFilesProvider);
                return ListView(
                  padding: EdgeInsets.symmetric(vertical: ui.spacing.xs),
                  children: [
                    if (recentFiles.isNotEmpty) ...[
                      _buildSectionHeader(ui, 'RECENT'),
                      ...recentFiles.map((file) => _FileTreeRow(
                        node: file,
                        depth: 1,
                        isExpanded: false,
                        onToggle: () {},
                        isRecent: true,
                      )),
                      SizedBox(height: ui.spacing.sm),
                    ],
                    _buildSectionHeader(ui, 'PROJECT'),
                    if (root.children.isEmpty)
                      _buildEmptyState(ui)
                    else
                      ..._buildTree(root, 0, ui),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.alertCircle, color: ui.colors.danger, size: 32),
                      const SizedBox(height: 12),
                      UiText(text: 'Failed to load files', color: ui.colors.textMuted, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(UiTheme ui, String title) {
    IconData headerIcon = title == 'RECENT' ? LucideIcons.clock : LucideIcons.files;
    return Padding(
      padding: EdgeInsets.only(left: ui.spacing.md, top: ui.spacing.sm, bottom: ui.spacing.xxs),
      child: Row(
        children: [
          Icon(headerIcon, size: 10, color: ui.colors.textMuted.withValues(alpha: 0.4)),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ui.colors.panelHeader.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.folderOpen, size: 40, color: ui.colors.textDisabled),
            ),
            const SizedBox(height: 20),
            UiText(
              text: 'No workspace open',
              variant: UiTextVariant.body,
              fontWeight: FontWeight.bold,
              color: ui.colors.textSecondary,
            ),
            const SizedBox(height: 8),
            UiText(
              text: 'Open a folder or drag one here to begin exploring your projects.',
              variant: UiTextVariant.label,
              color: ui.colors.textMuted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTree(FileNode node, int depth, UiTheme ui) {
    List<Widget> items = [];
    
    if (depth > 0 || node.path != '/') {
      items.add(_FileTreeRow(
        node: node,
        depth: depth,
        isExpanded: _expandedPaths.contains(node.path),
        onToggle: () => _toggleExpand(node.path),
      ));
    }

    if (node.isDirectory && (depth == 0 || _expandedPaths.contains(node.path))) {
      for (var child in node.children) {
        items.addAll(_buildTree(child, depth == 0 && node.path == '/' ? 0 : depth + 1, ui));
      }
    }
    
    return items;
  }
}

class _FileTreeRow extends StatefulWidget {
  const _FileTreeRow({
    required this.node,
    required this.depth,
    required this.isExpanded,
    required this.onToggle,
    this.isRecent = false,
  });

  final FileNode node;
  final int depth;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool isRecent;

  @override
  State<_FileTreeRow> createState() => _FileTreeRowState();
}

class _FileTreeRowState extends State<_FileTreeRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final double paddingLeft = widget.depth * 14.0 + (widget.isRecent ? ui.spacing.xs : ui.spacing.sm);

    IconData getFileIcon(String name) {
      final lowerName = name.toLowerCase();
      if (lowerName.endsWith('.m')) return LucideIcons.binary;
      if (lowerName.endsWith('.csv') || lowerName.endsWith('.xlsx')) return LucideIcons.table2;
      if (lowerName.endsWith('.md')) return LucideIcons.fileText;
      if (lowerName.endsWith('.json') || lowerName.endsWith('.yaml')) return LucideIcons.settings2;
      if (lowerName.endsWith('.py') || lowerName.endsWith('.js') || lowerName.endsWith('.ts')) return LucideIcons.code2;
      if (lowerName.endsWith('.png') || lowerName.endsWith('.jpg') || lowerName.endsWith('.svg')) return LucideIcons.image;
      return LucideIcons.file;
    }

    Color getIconColor(String name) {
      final lowerName = name.toLowerCase();
      if (lowerName.endsWith('.m')) return const Color(0xFFB3CDE3); // Soft Pastel Blue
      if (lowerName.endsWith('.md')) return const Color(0xFFCCEBC5); // Soft Pastel Green
      if (lowerName.endsWith('.py') || lowerName.endsWith('.js') || lowerName.endsWith('.ts')) return const Color(0xFFDECBE4); // Soft Pastel Purple
      if (lowerName.endsWith('.csv') || lowerName.endsWith('.xlsx')) return const Color(0xFFFED9A6); // Pastel Orange/Tan
      if (lowerName.endsWith('.json') || lowerName.endsWith('.yaml')) return const Color(0xFFFFFFCC); // Pastel Yellow
      if (lowerName.endsWith('.png') || lowerName.endsWith('.jpg') || lowerName.endsWith('.svg')) return const Color(0xFFFBB4AE); // Pastel Red
      return ui.colors.icon;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.node.isDirectory ? widget.onToggle : () {
          // Open file
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 26,
          padding: EdgeInsets.only(left: paddingLeft, right: ui.spacing.sm),
          decoration: BoxDecoration(
            color: _isHovered ? ui.colors.selected.withValues(alpha: 0.3) : Colors.transparent,
            borderRadius: ui.spacing.radiusSm,
            border: Border.all(
              color: _isHovered ? ui.colors.accent.withValues(alpha: 0.1) : Colors.transparent,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              if (widget.node.isDirectory)
                Icon(
                  widget.isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                  size: 12,
                  color: _isHovered ? ui.colors.textPrimary : ui.colors.textMuted,
                )
              else if (!widget.isRecent)
                const SizedBox(width: 12),
              const SizedBox(width: 6),
              Icon(
                widget.node.isDirectory 
                  ? (widget.isExpanded ? LucideIcons.folderOpen : LucideIcons.folder) 
                  : getFileIcon(widget.node.name),
                size: 14,
                color: widget.node.isDirectory ? const Color(0xFFB3CDE3) : getIconColor(widget.node.name),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: UiText(
                  text: widget.node.name,
                  variant: UiTextVariant.body,
                  fontSize: 12,
                  fontWeight: _isHovered ? FontWeight.w500 : FontWeight.w400,
                  color: _isHovered ? ui.colors.textPrimary : (widget.isRecent ? ui.colors.textMuted : ui.colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isRecent && _isHovered)
                Icon(LucideIcons.history, size: 12, color: ui.colors.textMuted.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
