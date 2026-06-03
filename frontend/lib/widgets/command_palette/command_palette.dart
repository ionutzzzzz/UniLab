import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/ui_theme.dart';
import '../ui_glass_container.dart';
import '../../providers/riverpod_providers.dart';

class CommandItem {
  final String id;
  final String label;
  final IconData icon;
  final String? shortcut;
  final VoidCallback onExecute;
  final String category;

  CommandItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.onExecute,
    this.shortcut,
    this.category = 'General',
  });
}

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Command Palette',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => const CommandPalette(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  List<CommandItem> _allCommands = [];
  List<CommandItem> _filteredCommands = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchFocus.requestFocus();
    _searchController.addListener(_onSearchChanged);
    _initCommands();
  }

  void _initCommands() {
    // In a real app, these would come from a CommandRegistry service
    _allCommands = [
      CommandItem(
        id: 'file.new',
        label: 'File: New Script',
        category: 'File',
        icon: LucideIcons.filePlus,
        shortcut: 'Ctrl+N',
        onExecute: () {},
      ),
      CommandItem(
        id: 'file.open',
        label: 'File: Open File...',
        category: 'File',
        icon: LucideIcons.folderOpen,
        shortcut: 'Ctrl+O',
        onExecute: () {},
      ),
      CommandItem(
        id: 'file.save',
        label: 'File: Save Active',
        category: 'File',
        icon: LucideIcons.save,
        shortcut: 'Ctrl+S',
        onExecute: () {},
      ),
      CommandItem(
        id: 'run.active',
        label: 'Run: Execute Active Script',
        category: 'Run',
        icon: LucideIcons.play,
        shortcut: 'F5',
        onExecute: () {},
      ),
      CommandItem(
        id: 'run.debug',
        label: 'Debug: Start Debugging',
        category: 'Run',
        icon: LucideIcons.bug,
        shortcut: 'F11',
        onExecute: () {},
      ),
      CommandItem(
        id: 'view.toggle_sidebar',
        label: 'View: Toggle Left Sidebar',
        category: 'View',
        icon: LucideIcons.layoutPanelLeft,
        shortcut: 'Ctrl+B',
        onExecute: () {},
      ),
      CommandItem(
        id: 'view.toggle_console',
        label: 'View: Toggle Bottom Console',
        category: 'View',
        icon: LucideIcons.terminal,
        shortcut: 'Ctrl+J',
        onExecute: () {},
      ),
      CommandItem(
        id: 'view.theme_toggle',
        label: 'View: Toggle Theme (Light/Dark)',
        category: 'Appearance',
        icon: LucideIcons.sunMoon,
        onExecute: () {},
      ),
      CommandItem(
        id: 'settings.open',
        label: 'Preferences: Open User Settings',
        category: 'Settings',
        icon: LucideIcons.settings,
        shortcut: 'Ctrl+,',
        onExecute: () {},
      ),
      CommandItem(
        id: 'help.docs',
        label: 'Help: Open Documentation',
        category: 'Help',
        icon: LucideIcons.helpCircle,
        onExecute: () {},
      ),
    ];
    _filteredCommands = List.from(_allCommands);
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _filteredCommands = List.from(_allCommands);
        _selectedIndex = 0;
      });
      return;
    }

    final fuse = Fuzzy<CommandItem>(
      _allCommands,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'label',
            getter: (CommandItem item) => item.label,
            weight: 1,
          ),
          WeightedKey(
            name: 'category',
            getter: (CommandItem item) => item.category,
            weight: 0.5,
          ),
        ],
      ),
    );

    final results = fuse.search(query);
    setState(() {
      _filteredCommands = results.map((r) => r.item).toList();
      _selectedIndex = 0;
    });
  }

  void _executeCommand(CommandItem command) {
    ref.read(commandPaletteHistoryProvider.notifier).addCommand(command.label);
    Navigator.of(context).pop();
    command.onExecute();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dismiss barrier
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.transparent),
          ),
          // Command Palette Box
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Hero(
                tag: 'command_palette',
                child: Material(
                  color: Colors.transparent,
                  child: UiGlassContainer(
                    width: 650,
                    height: 420,
                    borderRadius: ui.spacing.radiusMd,
                    blur: 20,
                    opacity: 0.7,
                    child: Column(
                      children: [
                        // Search Bar Section
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: ui.colors.border.withValues(alpha: 0.5),
                                width: ui.spacing.strokeHair,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.search,
                                size: 18,
                                color: ui.colors.accent,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocus,
                                  cursorColor: ui.colors.accent,
                                  style: ui.typography.body.copyWith(
                                    fontSize: 14,
                                    color: ui.colors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search commands...',
                                    hintStyle: ui.typography.body.copyWith(
                                      color: ui.colors.textDisabled,
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onSubmitted: (_) {
                                    if (_filteredCommands.isNotEmpty) {
                                      _executeCommand(_filteredCommands[_selectedIndex]);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Results Section
                        Expanded(
                          child: _filteredCommands.isEmpty
                              ? _buildEmptyState(ui)
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: _filteredCommands.length,
                                  itemBuilder: (context, index) {
                                    return _buildCommandItem(
                                      context, 
                                      _filteredCommands[index], 
                                      index == _selectedIndex,
                                      ui,
                                    );
                                  },
                                ),
                        ),
                        // Footer
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: ui.colors.panelHeader.withValues(alpha: 0.5),
                            border: Border(
                              top: BorderSide(
                                color: ui.colors.border.withValues(alpha: 0.5),
                                width: ui.spacing.strokeHair,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildKbdHint(ui, '↑↓', 'Navigate'),
                              const SizedBox(width: 16),
                              _buildKbdHint(ui, 'Enter', 'Execute'),
                              const SizedBox(width: 16),
                              _buildKbdHint(ui, 'Esc', 'Close'),
                              const Spacer(),
                              Text(
                                '${_filteredCommands.length} commands available',
                                style: ui.typography.label.copyWith(
                                  color: ui.colors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(UiTheme ui) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.searchX, size: 40, color: ui.colors.textDisabled),
          const SizedBox(height: 16),
          Text(
            'No commands matching "${_searchController.text}"',
            style: ui.typography.body.copyWith(color: ui.colors.textDisabled),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandItem(BuildContext context, CommandItem command, bool isSelected, UiTheme ui) {
    return MouseRegion(
      onEnter: (_) => setState(() => _selectedIndex = _filteredCommands.indexOf(command)),
      child: GestureDetector(
        onTap: () => _executeCommand(command),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? ui.colors.hover : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: isSelected ? Border.all(color: ui.colors.accent.withValues(alpha: 0.3), width: 0.5) : null,
          ),
          child: Row(
            children: [
              Icon(
                command.icon,
                size: 16,
                color: isSelected ? ui.colors.accent : ui.colors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: _highlightMatches(command.label, _searchController.text, ui),
                        style: ui.typography.body.copyWith(
                          fontSize: 13,
                          color: isSelected ? ui.colors.textPrimary : ui.colors.textSecondary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Text(
                        command.category,
                        style: ui.typography.label.copyWith(
                          fontSize: 10,
                          color: ui.colors.accent.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              if (command.shortcut != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? ui.colors.canvas : ui.colors.panelHeader,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: ui.colors.border.withValues(alpha: 0.5),
                      width: ui.spacing.strokeHair,
                    ),
                  ),
                  child: Text(
                    command.shortcut!,
                    style: ui.typography.codeBody.copyWith(
                      fontSize: 10,
                      color: isSelected ? ui.colors.accent : ui.colors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _highlightMatches(String text, String query, UiTheme ui) {
    if (query.isEmpty) return [TextSpan(text: text)];

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    int start = 0;
    int indexOfMatch;
    
    while ((indexOfMatch = lowerText.indexOf(lowerQuery, start)) != -1) {
      if (indexOfMatch > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfMatch)));
      }
      spans.add(TextSpan(
        text: text.substring(indexOfMatch, indexOfMatch + query.length),
        style: TextStyle(
          color: ui.colors.accent,
          fontWeight: FontWeight.bold,
          backgroundColor: ui.colors.accent.withValues(alpha: 0.15),
        ),
      ));
      start = indexOfMatch + query.length;
    }
    
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    
    return spans;
  }

  Widget _buildKbdHint(UiTheme ui, String kbd, String action) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: ui.colors.panelHeader,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: ui.colors.border, width: 0.5),
          ),
          child: Text(
            kbd,
            style: ui.typography.codeBody.copyWith(fontSize: 9, color: ui.colors.textMuted),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          action,
          style: ui.typography.label.copyWith(fontSize: 10, color: ui.colors.textDisabled),
        ),
      ],
    );
    }
  }
  