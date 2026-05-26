import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:context_menus/context_menus.dart';
import '../../providers/app_provider.dart';
import '../../utils/file_manager.dart';
import '../draggable/draggable_component.dart';

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
    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _showSearch
                      ? TextField(
                          controller: _searchController,
                          style: Theme.of(context).textTheme.bodySmall,
                          decoration: InputDecoration(
                            hintText: 'Search files...',
                            hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF858585),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) => setState(() {}),
                        )
                      : Text(
                          'FILES',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _showSearch ? Icons.close : Icons.search,
                        size: 14,
                      ),
                      onPressed: () {
                        setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) _searchController.clear();
                        });
                      },
                      tooltip: 'Search',
                      iconSize: 14,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 14),
                      onPressed: () {
                        Provider.of<AppProvider>(context, listen: false).addNewFile();
                      },
                      tooltip: 'New File',
                      iconSize: 14,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
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
                  if (_searchController.text.isEmpty) return true;
                  return p.basename(file.path)
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase());
                }).toList();

                if (files.isEmpty) {
                  return Center(
                    child: Text(
                      'No files found',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF858585),
                      ),
                    ),
                  );
                }

                return ListView.builder(
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

class _FileTreeItem extends StatefulWidget {
  final FileSystemEntity entity;
  final int depth;

  const _FileTreeItem({
    required this.entity,
    this.depth = 0,
  });

  @override
  State<_FileTreeItem> createState() => _FileTreeItemState();
}

class _FileTreeItemState extends State<_FileTreeItem> {
  bool _isExpanded = false;
  List<FileSystemEntity> _children = [];
  bool _isLoading = false;

  void _toggleExpanded() async {
    if (widget.entity is! Directory) {
      if (widget.entity is File) {
        Provider.of<AppProvider>(context, listen: false).openFile(widget.entity as File);
      }
      return;
    }

    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded && _children.isEmpty) {
      setState(() {
        _isLoading = true;
      });
      final children = await UniLabFileManager.listDirectory(widget.entity.path);
      // Sort: dirs first
      children.sort((a, b) {
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;
        return p.basename(a.path).compareTo(p.basename(b.path));
      });
      if (mounted) {
        setState(() {
          _children = children;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = p.basename(widget.entity.path);
    final isDirectory = widget.entity is Directory;
    final appProvider = Provider.of<AppProvider>(context);
    final isActive = !isDirectory && appProvider.activeFile?.path == widget.entity.path;

    return Column(
      children: [
        ContextMenuRegion(
          contextMenu: GenericContextMenu(
            buttonConfigs: [
              ContextMenuButtonConfig(
                isDirectory ? 'Expand/Collapse' : 'Open',
                onPressed: _toggleExpanded,
                icon: Icon(isDirectory ? Icons.unfold_more : Icons.file_open, size: 16),
              ),
              if (!isDirectory)
                ContextMenuButtonConfig(
                  'Run',
                  onPressed: () {
                     appProvider.openFile(widget.entity as File).then((_) {
                       appProvider.runActiveFile();
                     });
                  },
                  icon: const Icon(Icons.play_arrow, size: 16, color: Colors.green),
                ),
              ContextMenuButtonConfig(
                'Rename',
                onPressed: () {},
                icon: const Icon(Icons.edit, size: 16),
              ),
                ContextMenuButtonConfig(
                  'Delete',
                  onPressed: () {},
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                ),
                ContextMenuButtonConfig(
                  'Properties',
                  onPressed: () {},
                  icon: const Icon(Icons.info_outline, size: 16),
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
                  color: isActive 
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                      : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (isDirectory)
                      Icon(
                        _isExpanded ? Icons.expand_more : Icons.chevron_right,
                        size: 16,
                        color: const Color(0xFF858585),
                      )
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 4),
                    Icon(
                      isDirectory
                          ? (_isExpanded ? Icons.folder_open : Icons.folder)
                          : (name.endsWith('.m') ? Icons.description : Icons.file_present),
                      size: 16,
                      color: isDirectory ? const Color(0xFFCCA700) : const Color(0xFFCCCCCC),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? Theme.of(context).primaryColor : null,
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
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(minHeight: 1),
                ),
              )
            else
              ..._children.map((child) => _FileTreeItem(
                entity: child,
                depth: widget.depth + 1,
              )),
      ],
    );
  }
}
