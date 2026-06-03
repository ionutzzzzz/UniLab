import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_menus/context_menus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart' as p;
import 'package:path/path.dart' as path_utils;
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_icon_button.dart';
import '../../../providers/app_provider.dart';
import 'package:flutter/services.dart';
import '../../../widgets/ui_glass_container.dart';
import '../../../core/layout/shell_layout_state.dart';

class ExplorerPanel extends ConsumerStatefulWidget {
  const ExplorerPanel({super.key});

  @override
  ConsumerState<ExplorerPanel> createState() => _ExplorerPanelState();
}

class _ExplorerPanelState extends ConsumerState<ExplorerPanel> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  final Set<String> _expandedPaths = {};
  final Set<String> _selectedPaths = {};
  String? _lastSelectedPath;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Flat list to determine order for shift-click
  final List<String> _flatVisiblePaths = [];

  void _toggleExpand(String path) {
    setState(() {
      if (_expandedPaths.contains(path)) {
        _expandedPaths.remove(path);
      } else {
        _expandedPaths.add(path);
      }
    });
  }

  void _handleSelect(
    String path, {
    bool isCtrlPressed = false,
    bool isShiftPressed = false,
  }) {
    setState(() {
      if (isCtrlPressed) {
        if (_selectedPaths.contains(path)) {
          _selectedPaths.remove(path);
        } else {
          _selectedPaths.add(path);
        }
        _lastSelectedPath = path;
      } else if (isShiftPressed && _lastSelectedPath != null) {
        final currentIndex = _flatVisiblePaths.indexOf(path);
        final lastIndex = _flatVisiblePaths.indexOf(_lastSelectedPath!);

        if (currentIndex != -1 && lastIndex != -1) {
          final start = currentIndex < lastIndex ? currentIndex : lastIndex;
          final end = currentIndex > lastIndex ? currentIndex : lastIndex;

          _selectedPaths.clear();
          for (int i = start; i <= end; i++) {
            _selectedPaths.add(_flatVisiblePaths[i]);
          }
        }
      } else {
        _selectedPaths.clear();
        _selectedPaths.add(path);
        _lastSelectedPath = path;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final appProvider = p.Provider.of<AppProvider>(context);

    // Rebuild the flat list for shift-click before building tree
    _flatVisiblePaths.clear();
    _buildFlatPaths(appProvider.projectFiles);

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
              border: Border(
                bottom: BorderSide(
                  color: ui.colors.divider.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: UiText(
                      text: 'Explorer',
                      variant: UiTextVariant.body,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                                  style: TextStyle(
                                    color: ui.colors.textPrimary,
                                  ),
                                ),
                                content: TextField(
                                  controller: controller,
                                  style: TextStyle(
                                    color: ui.colors.textPrimary,
                                  ),
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
                                        final path = path_utils.join(
                                          appProvider.projectRoot,
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
                      _HeaderAction(
                        icon: LucideIcons.chevronLeft,
                        onPressed: () => ref
                            .read(shellLayoutProvider.notifier)
                            .toggleLeftPanel(),
                        tooltip: 'Collapse',
                        ui: ui,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tree View
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 50) {
                  return const SizedBox.shrink();
                }
                return ListView(
                  padding: EdgeInsets.symmetric(vertical: ui.spacing.xs),
                  children: [
                    _buildSectionHeader(ui, 'PROJECT'),
                    if (appProvider.projectFiles.isEmpty)
                      _buildEmptyState(ui)
                    else
                      ..._buildProjectTree(
                        appProvider.projectFiles,
                        0,
                        ui,
                        appProvider,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _buildFlatPaths(List<dynamic> entities) {
    for (var entity in entities) {
      final isDir = entity is io.Directory;
      final path = entity.path;
      _flatVisiblePaths.add(path);

      if (isDir && _expandedPaths.contains(path)) {
        try {
          final children = entity.listSync();
          // Sort to match tree view
          children.sort((a, b) {
            if (a is io.Directory && b is! io.Directory) return -1;
            if (a is! io.Directory && b is io.Directory) return 1;
            return path_utils
                .basename(a.path)
                .compareTo(path_utils.basename(b.path));
          });
          _buildFlatPaths(children);
        } catch (e) {
          // Ignore
        }
      }
    }
  }

  List<Widget> _buildProjectTree(
    List<dynamic> entities,
    int depth,
    UiTheme ui,
    AppProvider appProvider,
  ) {
    List<Widget> items = [];

    for (var entity in entities) {
      final isDir = entity is io.Directory;
      final path = entity.path;
      final name = path_utils.basename(path);
      final isExpanded = _expandedPaths.contains(path);

      items.add(
        _FileTreeRow(
          key: ValueKey(path),
          name: name,
          path: path,
          isDir: isDir,
          depth: depth,
          isExpanded: isExpanded,
          isSelected: _selectedPaths.contains(path),
          onSelect:
              ({bool isCtrlPressed = false, bool isShiftPressed = false}) =>
                  _handleSelect(
                    path,
                    isCtrlPressed: isCtrlPressed,
                    isShiftPressed: isShiftPressed,
                  ),
          onToggle: () {
            if (!HardwareKeyboard.instance.logicalKeysPressed.contains(
                  LogicalKeyboardKey.controlLeft,
                ) &&
                !HardwareKeyboard.instance.logicalKeysPressed.contains(
                  LogicalKeyboardKey.controlRight,
                ) &&
                !HardwareKeyboard.instance.logicalKeysPressed.contains(
                  LogicalKeyboardKey.shiftLeft,
                ) &&
                !HardwareKeyboard.instance.logicalKeysPressed.contains(
                  LogicalKeyboardKey.shiftRight,
                )) {
              _handleSelect(path);
            }
            if (isDir) {
              _toggleExpand(path);
            } else {
              appProvider.openFile(entity);
            }
          },
          onMove: (sourcePath, targetPath) async {
            if (sourcePath == targetPath) return;
            final sourceEntity = io.FileSystemEntity.isDirectorySync(sourcePath)
                ? io.Directory(sourcePath)
                : io.File(sourcePath);
            final newPath = path_utils.join(
              targetPath,
              path_utils.basename(sourcePath),
            );

            if (sourcePath != newPath) {
              try {
                await sourceEntity.rename(newPath);
                appProvider.refreshProjectFiles();
                appProvider.updateMovedFilePaths(sourcePath, newPath);
              } catch (e) {
                // Handle error if necessary
              }
            }
          },
        ),
      );

      if (isDir && isExpanded) {
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
      padding: EdgeInsets.only(
        left: ui.spacing.md,
        top: ui.spacing.sm,
        bottom: ui.spacing.xxs,
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.files,
            size: 10,
            color: ui.colors.textMuted.withValues(alpha: 0.4),
          ),
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
          Expanded(
            child: Divider(
              color: ui.colors.divider.withValues(alpha: 0.2),
              height: 1,
            ),
          ),
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
            Icon(
              LucideIcons.folderOpen,
              size: 40,
              color: ui.colors.textDisabled,
            ),
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

class _FileTreeRow extends StatefulWidget {
  const _FileTreeRow({
    super.key,
    required this.name,
    required this.path,
    required this.isDir,
    required this.depth,
    required this.isExpanded,
    required this.isSelected,
    required this.onSelect,
    required this.onToggle,
    required this.onMove,
  });

  final String name;
  final String path;
  final bool isDir;
  final int depth;
  final bool isExpanded;
  final bool isSelected;
  final void Function({bool isCtrlPressed, bool isShiftPressed}) onSelect;
  final VoidCallback onToggle;
  final void Function(String sourcePath, String targetPath) onMove;

  @override
  State<_FileTreeRow> createState() => _FileTreeRowState();
}

class _FileTreeRowState extends State<_FileTreeRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final double paddingLeft = widget.depth * 12.0 + ui.spacing.sm;
    final appProvider = p.Provider.of<AppProvider>(context, listen: false);

    return ContextMenuRegion(
      contextMenu: GenericContextMenu(
        buttonConfigs: [
          ContextMenuButtonConfig(
            widget.isDir ? 'Expand/Collapse' : 'Open',
            onPressed: widget.onToggle,
            icon: Icon(
              widget.isDir ? LucideIcons.chevronRight : LucideIcons.fileText,
              size: 16,
            ),
          ),
          if (widget.isDir)
            ContextMenuButtonConfig(
              'New File',
              onPressed: () =>
                  _createNewEntity(context, appProvider, isFile: true),
              icon: const Icon(LucideIcons.filePlus, size: 16),
            ),
          if (widget.isDir)
            ContextMenuButtonConfig(
              'New Folder',
              onPressed: () =>
                  _createNewEntity(context, appProvider, isFile: false),
              icon: const Icon(LucideIcons.folderPlus, size: 16),
            ),
          ContextMenuButtonConfig(
            'Rename',
            onPressed: () => _renameEntity(context, appProvider),
            icon: const Icon(LucideIcons.edit3, size: 16),
          ),
          ContextMenuButtonConfig(
            'Delete',
            onPressed: () => _deleteEntity(context, appProvider),
            icon: Icon(LucideIcons.trash2, size: 16, color: ui.colors.danger),
          ),
        ],
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: DragTarget<String>(
          onWillAcceptWithDetails: (details) {
            final dragPath = details.data;
            if (dragPath == widget.path) return false;
            if (widget.path.startsWith(dragPath + '/')) return false;
            return true;
          },
          onAcceptWithDetails: (details) {
            final targetPath = widget.isDir
                ? widget.path
                : path_utils.dirname(widget.path);
            widget.onMove(details.data, targetPath);
          },
          builder: (context, candidateData, rejectedData) {
            final isDragHovering = candidateData.isNotEmpty;
            return LongPressDraggable<String>(
              data: widget.path,
              delay: const Duration(milliseconds: 300),
              dragAnchorStrategy: pointerDragAnchorStrategy,
              feedback: Material(
                elevation: 12,
                borderRadius: ui.spacing.radiusMd,
                color: Colors.transparent,
                child: UiGlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  opacity: 0.9,
                  blur: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isDir
                            ? LucideIcons.folder
                            : _getFileIcon(widget.name),
                        size: 16,
                        color: widget.isDir
                            ? const Color(0xFFB3CDE3)
                            : _getIconColor(widget.name, ui),
                      ),
                      const SizedBox(width: 10),
                      UiText(
                        text: widget.name,
                        variant: UiTextVariant.body,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildRowContent(ui, paddingLeft, false, false),
              ),
              child: Listener(
                onPointerDown: (event) {
                  final isCtrl =
                      HardwareKeyboard.instance.logicalKeysPressed.contains(
                        LogicalKeyboardKey.controlLeft,
                      ) ||
                      HardwareKeyboard.instance.logicalKeysPressed.contains(
                        LogicalKeyboardKey.controlRight,
                      ) ||
                      HardwareKeyboard.instance.logicalKeysPressed.contains(
                        LogicalKeyboardKey.metaLeft,
                      ) ||
                      HardwareKeyboard.instance.logicalKeysPressed.contains(
                        LogicalKeyboardKey.metaRight,
                      );
                  final isShift =
                      HardwareKeyboard.instance.logicalKeysPressed.contains(
                        LogicalKeyboardKey.shiftLeft,
                      ) ||
                      HardwareKeyboard.instance.logicalKeysPressed.contains(
                        LogicalKeyboardKey.shiftRight,
                      );

                  if (event.buttons == 2) {
                    // Right click
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted)
                        widget.onSelect(
                          isCtrlPressed: isCtrl,
                          isShiftPressed: isShift,
                        );
                    });
                  } else if (event.buttons == 1) {
                    // Left click
                    widget.onSelect(
                      isCtrlPressed: isCtrl,
                      isShiftPressed: isShift,
                    );
                  }
                },
                child: GestureDetector(
                  onTap: widget.onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: _buildRowContent(
                    ui,
                    paddingLeft,
                    widget.isSelected,
                    isDragHovering || _isHovered,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRowContent(
    UiTheme ui,
    double paddingLeft,
    bool isSelected,
    bool isHighlighted,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < paddingLeft + 30) {
          return const SizedBox.shrink();
        }
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 24,
          padding: EdgeInsets.only(left: paddingLeft, right: ui.spacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? ui.colors.selected
                : (isHighlighted
                      ? ui.colors.accent.withValues(alpha: 0.15)
                      : Colors.transparent),
          ),
          child: Row(
            children: [
              if (widget.isDir)
                Icon(
                  widget.isExpanded
                      ? LucideIcons.chevronDown
                      : LucideIcons.chevronRight,
                  size: 12,
                  color: ui.colors.textMuted,
                )
              else
                const SizedBox(width: 12),
              const SizedBox(width: 6),
              Icon(
                widget.isDir
                    ? (widget.isExpanded
                          ? LucideIcons.folderOpen
                          : LucideIcons.folder)
                    : _getFileIcon(widget.name),
                size: 14,
                color: widget.isDir
                    ? const Color(0xFFB3CDE3)
                    : _getIconColor(widget.name, ui),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: UiText(
                  text: widget.name,
                  variant: UiTextVariant.body,
                  fontSize: 12,
                  color: (isSelected || isHighlighted)
                      ? ui.colors.textPrimary
                      : ui.colors.textSecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getFileIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.endsWith('.m')) return LucideIcons.fileCode2;
    if (lowerName.endsWith('.csv') || lowerName.endsWith('.xlsx'))
      return LucideIcons.table2;
    if (lowerName.endsWith('.md')) return LucideIcons.fileText;
    if (lowerName.endsWith('.json') || lowerName.endsWith('.yaml'))
      return LucideIcons.fileJson;
    if (lowerName.endsWith('.png') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg'))
      return LucideIcons.fileImage;
    if (lowerName.endsWith('.pdf')) return LucideIcons.fileText;
    if (lowerName.endsWith('.mp3') || lowerName.endsWith('.wav'))
      return LucideIcons.fileAudio;
    return LucideIcons.file;
  }

  Color _getIconColor(String name, UiTheme ui) {
    final lowerName = name.toLowerCase();
    if (lowerName.endsWith('.m')) return const Color(0xFFB3CDE3);
    if (lowerName.endsWith('.md')) return const Color(0xFFCCEBC5);
    return ui.colors.icon;
  }

  void _deleteEntity(BuildContext context, AppProvider appProvider) {
    final ui = UiTheme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        title: UiText(text: 'Delete', variant: UiTextVariant.title),
        content: UiText(
          text: 'Are you sure you want to delete "${widget.name}"?',
          color: ui.colors.textSecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: UiText(text: 'Cancel', color: ui.colors.textMuted),
          ),
          TextButton(
            onPressed: () {
              final entity = widget.isDir
                  ? io.Directory(widget.path)
                  : io.File(widget.path);
              appProvider.deleteFile(entity);
              Navigator.pop(context);
            },
            child: UiText(text: 'Delete', color: ui.colors.danger),
          ),
        ],
      ),
    );
  }

  void _renameEntity(BuildContext context, AppProvider appProvider) {
    final ui = UiTheme.of(context);
    final controller = TextEditingController(text: widget.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        title: UiText(text: 'Rename', variant: UiTextVariant.title),
        content: TextField(
          controller: controller,
          style: TextStyle(color: ui.colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'New Name',
            hintStyle: TextStyle(color: ui.colors.textMuted),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: ui.colors.accent),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: UiText(text: 'Cancel', color: ui.colors.textMuted),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text;
              if (newName.isNotEmpty && newName != widget.name) {
                final newPath = path_utils.join(
                  path_utils.dirname(widget.path),
                  newName,
                );
                final entity = widget.isDir
                    ? io.Directory(widget.path)
                    : io.File(widget.path);
                await entity.rename(newPath);
                appProvider.refreshProjectFiles();
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: UiText(text: 'Rename', color: ui.colors.accent),
          ),
        ],
      ),
    );
  }

  void _createNewEntity(
    BuildContext context,
    AppProvider appProvider, {
    required bool isFile,
  }) {
    final ui = UiTheme.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        title: UiText(
          text: isFile ? 'New File' : 'New Folder',
          variant: UiTextVariant.title,
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: ui.colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Name',
            hintStyle: TextStyle(color: ui.colors.textMuted),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: ui.colors.accent),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: UiText(text: 'Cancel', color: ui.colors.textMuted),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text;
              if (name.isNotEmpty) {
                final newPath = path_utils.join(widget.path, name);
                if (isFile) {
                  await io.File(newPath).create();
                  appProvider.openFile(io.File(newPath)); // Auto open new files
                } else {
                  await io.Directory(newPath).create();
                }
                appProvider.refreshProjectFiles();
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: UiText(text: 'Create', color: ui.colors.accent),
          ),
        ],
      ),
    );
  }
}
