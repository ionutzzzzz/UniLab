import 'package:flutter/material.dart';
import '../theme/ui_theme.dart';
import '../theme/ui_decorations.dart';
import 'ui_text.dart';

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
    final ui = UiTheme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
      child: ShellDecorations.buildGlassMenu(
        theme: ui,
        child: Container(
          width: 650,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: ui.colors.divider.withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  autofocus: true,
                  style: ui.typography.body.copyWith(color: ui.colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Type command name, description, or shortcut...',
                    hintStyle: ui.typography.body.copyWith(color: ui.colors.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(Icons.search, size: 18, color: ui.colors.accent),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
              ),

              // Commands list
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 450),
                  child: _filteredCommands.isEmpty
                      ? _buildEmptyState(ui)
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredCommands.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            final command = _filteredCommands[index];
                            final isSelected = index == _selectedIndex;

                            return _CommandItem(
                              command: command,
                              isSelected: isSelected,
                              onTap: () => _executeCommand(command),
                              onHover: () => setState(() => _selectedIndex = index),
                            );
                          },
                        ),
                ),
              ),

              // Footer with tips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: ui.colors.panelHeader.withValues(alpha: 0.4),
                  border: Border(
                    top: BorderSide(
                      color: ui.colors.divider.withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    UiText(
                      text: 'Showing ${_filteredCommands.length} command${_filteredCommands.length != 1 ? 's' : ''}',
                      variant: UiTextVariant.label,
                      color: ui.colors.textMuted,
                      fontSize: 10,
                    ),
                    Row(
                      children: [
                        _KeyBindingFooter('↑↓', 'Navigate'),
                        const SizedBox(width: 20),
                        _KeyBindingFooter('↵', 'Execute'),
                        const SizedBox(width: 20),
                        _KeyBindingFooter('Esc', 'Close'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(UiTheme ui) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: ui.colors.divider,
            ),
            const SizedBox(height: 16),
            UiText(
              text: 'No commands found matching your search',
              variant: UiTextVariant.body,
              color: ui.colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandItem extends StatelessWidget {
  const _CommandItem({
    required this.command,
    required this.isSelected,
    required this.onTap,
    required this.onHover,
  });

  final Command command;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onHover;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);

    return MouseRegion(
      onEnter: (_) => onHover(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
            color: isSelected ? ui.colors.accent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: ui.spacing.radiusMd,
            border: Border.all(
              color: isSelected ? ui.colors.accent.withValues(alpha: 0.2) : Colors.transparent,
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected 
                    ? ui.colors.accent.withValues(alpha: 0.2) 
                    : ui.colors.panelHeader.withValues(alpha: 0.5),
                  borderRadius: ui.spacing.radiusSm,
                ),
                child: Icon(
                  command.icon ?? Icons.code,
                  size: 18,
                  color: isSelected ? ui.colors.accent : ui.colors.icon,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: UiText(
                            text: command.title,
                            variant: UiTextVariant.body,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? ui.colors.textPrimary : ui.colors.textSecondary,
                          ),
                        ),
                        if (command.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: ui.colors.divider.withValues(alpha: 0.3),
                              borderRadius: ui.spacing.radiusSm,
                            ),
                            child: UiText(
                              text: command.category!.toUpperCase(),
                              variant: UiTextVariant.label,
                              fontSize: 9,
                              letterSpacing: 0.5,
                              color: ui.colors.textMuted,
                            ),
                          ),
                      ],
                    ),
                    if (command.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: UiText(
                          text: command.description,
                          variant: UiTextVariant.label,
                          color: ui.colors.textMuted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (command.shortcut != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ui.colors.canvas.withValues(alpha: 0.3),
                      borderRadius: ui.spacing.radiusSm,
                      border: Border.all(color: ui.colors.divider.withValues(alpha: 0.2)),
                    ),
                    child: UiText(
                      text: command.shortcut!,
                      variant: UiTextVariant.label,
                      fontSize: 10,
                      color: ui.colors.textMuted,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Key binding footer widget
class _KeyBindingFooter extends StatelessWidget {
  final String keyName;
  final String description;

  const _KeyBindingFooter(this.keyName, this.description);

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: ui.colors.canvas.withValues(alpha: 0.3),
            borderRadius: ui.spacing.radiusSm,
            border: Border.all(
              color: ui.colors.divider.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          child: UiText(
            text: keyName,
            variant: UiTextVariant.label,
            fontSize: 10,
            color: ui.colors.textMuted,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        const SizedBox(width: 8),
        UiText(
          text: description,
          variant: UiTextVariant.label,
          fontSize: 10,
          color: ui.colors.textMuted,
        ),
      ],
    );
  }
}
