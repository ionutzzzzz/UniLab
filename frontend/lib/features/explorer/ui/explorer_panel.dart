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
            height: 36,
            padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: ui.colors.panelHeader,
              border: Border(bottom: BorderSide(color: ui.colors.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                UiText(
                  text: 'EXPLORER',
                  variant: UiTextVariant.title,
                  color: ui.colors.textPrimary,
                ),
                Row(
                  children: [
                    UiIconButton(icon: LucideIcons.filePlus, tooltip: 'New File', size: 24, iconSize: 14),
                    SizedBox(width: ui.spacing.xs),
                    UiIconButton(icon: LucideIcons.folderPlus, tooltip: 'New Folder', size: 24, iconSize: 14),
                  ],
                ),
              ],
            ),
          ),
          // Tree View
          Expanded(
            child: rootAsync.when(
              data: (root) => ListView(
                padding: EdgeInsets.symmetric(vertical: ui.spacing.xs),
                children: _buildTree(root, 0, ui),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: UiText(text: 'Error: $err', color: ui.colors.danger)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTree(FileNode node, int depth, UiTheme ui) {
    List<Widget> items = [];
    
    // Skip rendering the synthetic root node itself, but render its children
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
  });

  final FileNode node;
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
      if (name.endsWith('.m')) return LucideIcons.fileCode;
      if (name.endsWith('.csv')) return LucideIcons.fileSpreadsheet;
      if (name.endsWith('.md')) return LucideIcons.fileText;
      return LucideIcons.file;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.node.isDirectory ? widget.onToggle : () {
          // Open file
        },
        child: Container(
          height: 24,
          padding: EdgeInsets.only(left: paddingLeft, right: ui.spacing.sm),
          decoration: BoxDecoration(
            color: _isHovered ? ui.colors.hover : Colors.transparent,
            borderRadius: ui.spacing.radiusSm,
          ),
          child: Row(
            children: [
              if (widget.node.isDirectory)
                Icon(
                  widget.isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                  size: 14,
                  color: ui.colors.textMuted,
                )
              else
                const SizedBox(width: 14),
              const SizedBox(width: 4),
              Icon(
                widget.node.isDirectory ? LucideIcons.folder : getFileIcon(widget.node.name),
                size: 14,
                color: widget.node.isDirectory ? ui.colors.accent : ui.colors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: UiText(
                  text: widget.node.name,
                  variant: UiTextVariant.body,
                  color: ui.colors.textPrimary,
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
