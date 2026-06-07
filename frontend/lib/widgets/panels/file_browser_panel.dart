import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:context_menus/context_menus.dart';
import 'package:path/path.dart' as p;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/app_provider.dart';
import '../../utils/file_manager.dart';
import '../../theme/ui_theme.dart';
import '../../theme/ui_decorations.dart';

// Use a conditional import for io types
import 'dart:io' as io;

class FileBrowserPanel extends StatefulWidget {
  const FileBrowserPanel({super.key});

  @override
  State<FileBrowserPanel> createState() => _FileBrowserPanelState();
}

class _FileBrowserPanelState extends State<FileBrowserPanel> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final ui = UiTheme.of(context);

    return Container(
      decoration: ShellDecorations.panelDecoration(ui),
      margin: const EdgeInsets.all(2.0),
      child: Column(
        children: [
          // Header
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: ui.colors.panelHeader,
              border: Border(
                bottom: BorderSide(color: ui.colors.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _showSearch
                      ? TextField(
                          controller: _searchController,
                          style: TextStyle(
                            fontSize: 11,
                            color: ui.colors.textPrimary,
                          ),
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search files...',
                            hintStyle: TextStyle(
                              fontSize: 11,
                              color: ui.colors.textMuted,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) => setState(() {}),
                        )
                      : Text(
                          'FILES',
                          style: ui.typography.label.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            fontSize: 10,
                            color: ui.colors.textMuted,
                          ),
                        ),
                ),
                Row(
                  children: [
                    _HeaderAction(
                      icon: _showSearch ? LucideIcons.x : LucideIcons.search,
                      onPressed: () {
                        setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) _searchController.clear();
                        });
                      },
                      tooltip: 'Search',
                      ui: ui,
                    ),
                    _HeaderAction(
                      icon: LucideIcons.refreshCw,
                      onPressed: () => appProvider.refreshProjectFiles(),
                      tooltip: 'Refresh',
                      ui: ui,
                    ),
                    _HeaderAction(
                      icon: LucideIcons.filePlus,
                      onPressed: () => appProvider.addNewFile(),
                      tooltip: 'New File',
                      ui: ui,
                    ),
                    _HeaderAction(
                      icon: LucideIcons.folderPlus,
                      onPressed: () {
                        if (kIsWeb) return;
                        showDialog(
                          context: context,
                          builder: (context) {
                            final controller = TextEditingController();
                            return AlertDialog(
                              backgroundColor: ui.colors.panel,
                              title: Text(
                                'New Folder',
                                style: TextStyle(color: ui.colors.textPrimary),
                              ),
                              content: TextField(
                                controller: controller,
                                style: TextStyle(color: ui.colors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Folder Name',
                                  hintStyle: TextStyle(
                                    color: ui.colors.textMuted,
                                  ),
                                ),
                                autofocus: true,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: ui.colors.textMuted,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final name = controller.text;
                                    if (name.isNotEmpty) {
                                      final path = p.join(
                                        appProvider.projectRoot.toString(),
                                        name,
                                      );
                                      await io.Directory(
                                        path,
                                      ).create(recursive: true);
                                      appProvider.refreshProjectFiles();
                                    }
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: Text(
                                    'Create',
                                    style: TextStyle(color: ui.colors.accent),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      tooltip: 'New Folder',
                      ui: ui,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // File List
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, appProvider, _) {
                final files = appProvider.projectFiles.where((file) {
                  final path = kIsWeb
                      ? 'web-file'
                      : (file as io.FileSystemEntity).path;
                  final name = kIsWeb ? 'web-file' : p.basename(path);

                  if (_searchController.text.isEmpty) return true;
                  return name.toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  );
                }).toList();

                if (files.isEmpty) {
                  return Center(
                    child: Text(
                      'No files found',
                      style: ui.typography.label.copyWith(
                        color: ui.colors.textMuted,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  primary: false,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    return _FileTreeItem(entity: files[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final UiTheme ui;

  const _HeaderAction({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 14, color: ui.colors.icon),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
    );
  }
}

class _FileTreeItem extends StatefulWidget {
  final dynamic entity;
  final int depth;

  const _FileTreeItem({required this.entity, this.depth = 0});

  @override
  State<_FileTreeItem> createState() => _FileTreeItemState();
}

class _FileTreeItemState extends State<_FileTreeItem> {
  bool _isExpanded = false;
  List<dynamic> _children = [];
  bool _isLoading = false;

  void _toggleExpanded() async {
    if (kIsWeb) return;

    if (widget.entity is! io.Directory) {
      if (widget.entity is io.File) {
        Provider.of<AppProvider>(
          context,
          listen: false,
        ).openFile(widget.entity);
      }
      return;
    }

    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded && _children.isEmpty) {
      _refreshChildren();
    }
  }

  Future<void> _refreshChildren() async {
    if (kIsWeb || widget.entity is! io.Directory) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final children = await UniLabFileManager.listDirectory(
        (widget.entity as io.Directory).path,
      );
      // Sort: dirs first
      children.sort((a, b) {
        if (a is io.Directory && b is! io.Directory) return -1;
        if (a is! io.Directory && b is io.Directory) return 1;
        return p
            .basename((a as io.FileSystemEntity).path)
            .compareTo(p.basename((b as io.FileSystemEntity).path));
      });

      if (mounted) {
        setState(() {
          _children = children;
          _isExpanded = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isExpanded = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();

    final entity = widget.entity as io.FileSystemEntity;
    final name = p.basename(entity.path);
    final isDirectory = entity is io.Directory;
    final appProvider = Provider.of<AppProvider>(context);
    final isActive =
        !isDirectory && appProvider.activeFile?.path == entity.path;
    final ui = UiTheme.of(context);

    return Column(
      children: [
        ContextMenuRegion(
          contextMenu: GenericContextMenu(
            buttonConfigs: [
              ContextMenuButtonConfig(
                isDirectory ? 'Expand/Collapse' : 'Open',
                onPressed: _toggleExpanded,
                icon: Icon(
                  isDirectory ? LucideIcons.chevronRight : LucideIcons.fileText,
                  size: 16,
                ),
              ),
              if (isDirectory)
                ContextMenuButtonConfig(
                  'Refresh',
                  onPressed: () {
                    if (_isExpanded) {
                      _children = [];
                      _refreshChildren();
                    }
                  },
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                ),
              if (!isDirectory)
                ContextMenuButtonConfig(
                  'Run',
                  onPressed: appProvider.isExecuting
                      ? null
                      : () {
                          appProvider.openFile(entity).then((_) {
                            appProvider.runActiveFile();
                          });
                        },
                  icon: Icon(
                    LucideIcons.play,
                    size: 16,
                    color: appProvider.isExecuting
                        ? ui.colors.textDisabled
                        : ui.colors.success,
                  ),
                ),
              ContextMenuButtonConfig(
                'Rename',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File renaming coming soon.')),
                  );
                },
                icon: const Icon(LucideIcons.edit3, size: 16),
              ),
              ContextMenuButtonConfig(
                'Delete',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: ui.colors.panel,
                      title: Text(
                        'Delete File',
                        style: TextStyle(color: ui.colors.textPrimary),
                      ),
                      content: Text(
                        'Are you sure you want to delete "${p.basename(entity.path)}"?',
                        style: TextStyle(color: ui.colors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: ui.colors.textMuted),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            appProvider.deleteFile(entity);
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Delete',
                            style: TextStyle(color: ui.colors.danger),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(
                  LucideIcons.trash2,
                  size: 16,
                  color: ui.colors.danger,
                ),
              ),
              ContextMenuButtonConfig(
                'Properties',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File properties coming soon.'),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.info, size: 16),
              ),
            ],
          ),
          child: InkWell(
            onTap: _toggleExpanded,
            child: Container(
              padding: EdgeInsets.only(
                left: 12.0 + (widget.depth * 12.0),
                right: 12.0,
                top: 4.0,
                bottom: 4.0,
              ),
              decoration: BoxDecoration(
                color: isActive ? ui.colors.selected : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isActive ? ui.colors.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (isDirectory)
                    Icon(
                      _isExpanded
                          ? LucideIcons.chevronDown
                          : LucideIcons.chevronRight,
                      size: 14,
                      color: ui.colors.textMuted,
                    )
                  else
                    const SizedBox(width: 14),
                  const SizedBox(width: 2),
                  Icon(
                    isDirectory
                        ? (_isExpanded
                              ? LucideIcons.folderOpen
                              : LucideIcons.folder)
                        : (name.endsWith('.m')
                              ? LucideIcons.fileText
                              : LucideIcons.file),
                    size: 16,
                    color: isDirectory
                        ? ui.colors.tan
                        : (isActive
                              ? ui.colors.accent
                              : ui.colors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: ui.typography.label.copyWith(
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isActive
                            ? ui.colors.textInverse
                            : ui.colors.textPrimary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isDirectory && _isExpanded)
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  minHeight: 1,
                  backgroundColor: ui.colors.panel,
                  color: ui.colors.accent,
                ),
              ),
            )
          else
            ..._children.map(
              (child) => _FileTreeItem(entity: child, depth: widget.depth + 1),
            ),
      ],
    );
  }
}
