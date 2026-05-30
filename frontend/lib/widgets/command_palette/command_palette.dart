import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fuzzy/fuzzy.dart';
import '../../providers/app_provider.dart';
import '../../providers/settings_provider.dart';

class CommandItem {
  final String id;
  final String label;
  final IconData icon;
  final String? shortcut;
  final VoidCallback onExecute;

  CommandItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.onExecute,
    this.shortcut,
  });
}

class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => const CommandPalette(),
    );
  }

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  List<CommandItem> _allCommands = [];
  List<CommandItem> _filteredCommands = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchFocus.requestFocus();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initCommands();
  }

  void _initCommands() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    _allCommands = [
      CommandItem(
        id: 'file.new',
        label: 'File: New File',
        icon: Icons.note_add,
        shortcut: 'Ctrl+N',
        onExecute: () => appProvider.addNewFile(),
      ),
      CommandItem(
        id: 'file.save',
        label: 'File: Save',
        icon: Icons.save,
        shortcut: 'Ctrl+S',
        onExecute: () {},
      ),
      CommandItem(
        id: 'run.active',
        label: 'Run: Active File',
        icon: Icons.play_arrow,
        shortcut: 'F5',
        onExecute: () => appProvider.runActiveFile(),
      ),
      CommandItem(
        id: 'view.toggle_theme',
        label: 'View: Toggle Theme',
        icon: Icons.brightness_6,
        onExecute: () {
           final settings = settingsProvider.settings;
           final newMode = settings.themeMode == ThemeMode.dark 
              ? ThemeMode.light 
              : ThemeMode.dark;
           settingsProvider.updateSettings(settings.copyWith(themeMode: newMode));
        },
      ),
      CommandItem(
        id: 'console.clear',
        label: 'Console: Clear',
        icon: Icons.clear_all,
        onExecute: () => appProvider.clearConsole(),
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
          )
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
    Navigator.of(context).pop();
    command.onExecute();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.only(top: 100),
      alignment: Alignment.topCenter,
      child: Container(
        width: 600,
        height: 400,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.zero,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Type a command...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).canvasColor,
                ),
                onSubmitted: (_) {
                  if (_filteredCommands.isNotEmpty) {
                    _executeCommand(_filteredCommands[_selectedIndex]);
                  }
                },
              ),
            ),
            const Divider(height: 1),
            // Command List
            Expanded(
              child: ListView.builder(
                itemCount: _filteredCommands.length,
                itemBuilder: (context, index) {
                  final command = _filteredCommands[index];
                  final isSelected = index == _selectedIndex;

                  return MouseRegion(
                    onEnter: (_) => setState(() => _selectedIndex = index),
                    child: ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      leading: Icon(
                        command.icon,
                        color: isSelected 
                            ? Theme.of(context).primaryColor 
                            : Theme.of(context).textTheme.bodySmall?.color,
                        size: 16,
                      ),
                      title: Text(
                        command.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected 
                              ? Theme.of(context).primaryColor 
                              : null,
                        ),
                      ),
                      trailing: command.shortcut != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).canvasColor,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Text(
                                command.shortcut!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            )
                          : null,
                      onTap: () => _executeCommand(command),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
