import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Represents a command that can be executed
class Command {
  final String id;
  final String title;
  final String description;
  final String? shortcut;
  final IconData? icon;
  final VoidCallback onExecute;
  final String? category; // e.g., 'File', 'Edit', 'Run', 'Debug'

  Command({
    required this.id,
    required this.title,
    this.description = '',
    this.shortcut,
    this.icon,
    required this.onExecute,
    this.category,
  });
}

/// Command Palette overlay dialog
class CommandPalette extends StatefulWidget {
  final List<Command> commands;
  final Function(String)? onCommandExecuted;

  const CommandPalette({
    super.key,
    required this.commands,
    this.onCommandExecuted,
  });

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  late TextEditingController _searchController;
  late FocusNode _focusNode;
  List<Command> _filteredCommands = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();
    _filteredCommands = widget.commands;
    _focusNode.requestFocus();

    _searchController.addListener(_filterCommands);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterCommands() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _filteredCommands = widget.commands;
        _selectedIndex = 0;
      });
      return;
    }

    // Simple search on command titles and descriptions
    setState(() {
      _filteredCommands = widget.commands.where((cmd) {
        final titleLower = cmd.title.toLowerCase();
        final descLower = cmd.description.toLowerCase();
        final queryLower = query.toLowerCase();

        return titleLower.contains(queryLower) ||
            descLower.contains(queryLower) ||
            (cmd.category?.toLowerCase().contains(queryLower) ?? false);
      }).toList();
      _selectedIndex = 0;
    });
  }

  void _executeCommand(Command command) {
    command.onExecute();
    widget.onCommandExecuted?.call(command.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.darkPanelBackground,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1.0,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.darkTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Type command name, description, or shortcut...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkTextSecondary,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.zero,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                prefixIcon: const Icon(Icons.search, size: 16),
              ),
            ),
          ),

          // Commands list
          Flexible(
            child: Container(
              color: AppTheme.darkCanvasBackground,
              constraints: const BoxConstraints(maxHeight: 400, minWidth: 600),
              child: _filteredCommands.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 32,
                              color: Theme.of(context).dividerColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No commands found',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredCommands.length,
                      itemBuilder: (context, index) {
                        final command = _filteredCommands[index];
                        final isSelected = index == _selectedIndex;

                        return MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          child: GestureDetector(
                            onTap: () => _executeCommand(command),
                            child: Container(
                              color: isSelected
                                  ? AppTheme.darkHoverColor
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  if (command.icon != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Icon(
                                        command.icon,
                                        size: 16,
                                        color: AppTheme.darkAccentColor,
                                      ),
                                    ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                command.title,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      AppTheme.darkTextPrimary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (command.category != null)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  left: 12,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppTheme.darkBorderColor,
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                ),
                                                child: Text(
                                                  command.category!,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: AppTheme
                                                        .darkTextTertiary,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (command.description.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              command.description,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppTheme.darkTextSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (command.shortcut != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: Text(
                                        command.shortcut!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.darkTextTertiary,
                                          fontFamily: 'JetBrains Mono',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Footer with tips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.darkPanelBackground,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${_filteredCommands.length} command${_filteredCommands.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.darkTextTertiary,
                  ),
                ),
                Row(
                  children: [
                    _KeyBindingFooter('↑↓', 'Navigate'),
                    const SizedBox(width: 16),
                    _KeyBindingFooter('↵', 'Execute'),
                    const SizedBox(width: 16),
                    _KeyBindingFooter('Esc', 'Close'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Key binding display widget
class KeyBindingDisplay extends StatelessWidget {
  final String keyName;
  final String description;

  const KeyBindingDisplay(this.keyName, this.description);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1.0,
            ),
          ),
          child: Text(
            keyName,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.darkTextTertiary,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.darkTextTertiary,
          ),
        ),
      ],
    );
  }
}

/// Key binding footer widget
class _KeyBindingFooter extends StatelessWidget {
  final String keyName;
  final String description;

  const _KeyBindingFooter(this.keyName, this.description, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1.0,
            ),
          ),
          child: Text(
            keyName,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.darkTextTertiary,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.darkTextTertiary,
          ),
        ),
      ],
    );
  }
}
