import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/commands/command.dart';
import '../../../core/commands/commands_registration.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_input_field.dart';
import '../../../widgets/ui_text.dart';

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => const CommandPalette(),
    );
  }

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  List<AppCommand> _filteredCommands = [];
  List<AppCommand> _allCommands = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _allCommands = ref.read(commandRegistryProvider).getAll();
    _filteredCommands = List.from(_allCommands);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    final fuse = Fuzzy<AppCommand>(
      _allCommands,
      options: FuzzyOptions(
        keys: [
          WeightedKey(name: 'title', getter: (c) => c.title, weight: 1.0),
          WeightedKey(name: 'category', getter: (c) => c.category ?? '', weight: 0.5),
        ],
      ),
    );

    final results = fuse.search(query);
    setState(() {
      _filteredCommands = results.map((r) => r.item).toList();
      _selectedIndex = 0;
    });
  }

  void _executeCommand(AppCommand command) {
    Navigator.of(context).pop();
    if (command.enabled?.call(CommandContext(context)) ?? true) {
      command.run(CommandContext(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.only(top: 100),
      alignment: Alignment.topCenter,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: ui.colors.overlay,
          borderRadius: ui.spacing.radiusMd,
          border: Border.all(color: ui.colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(ui.spacing.sm),
              child: UiInputField(
                controller: _searchController,
                hintText: 'Type a command...',
                prefixIcon: LucideIcons.chevronRight,
                isDense: false,
              ),
            ),
            if (_filteredCommands.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredCommands.length,
                  itemBuilder: (context, index) {
                    final cmd = _filteredCommands[index];
                    final isSelected = index == _selectedIndex;

                    return MouseRegion(
                      onEnter: (_) => setState(() => _selectedIndex = index),
                      child: GestureDetector(
                        onTap: () => _executeCommand(cmd),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: ui.spacing.md, vertical: ui.spacing.sm),
                          color: isSelected ? ui.colors.selected : Colors.transparent,
                          child: Row(
                            children: [
                              Icon(
                                cmd.icon ?? LucideIcons.circle,
                                size: 16,
                                color: isSelected ? ui.colors.textInverse : ui.colors.textSecondary,
                              ),
                              SizedBox(width: ui.spacing.sm),
                              Expanded(
                                child: UiText(
                                  text: cmd.title,
                                  variant: UiTextVariant.body,
                                  color: isSelected ? ui.colors.textInverse : ui.colors.textPrimary,
                                ),
                              ),
                              if (cmd.category != null)
                                UiText(
                                  text: cmd.category!,
                                  variant: UiTextVariant.caption,
                                  color: isSelected ? ui.colors.textInverse.withOpacity(0.7) : ui.colors.textMuted,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Padding(
                padding: EdgeInsets.all(ui.spacing.lg),
                child: UiText(
                  text: 'No commands found.',
                  variant: UiTextVariant.body,
                  color: ui.colors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
