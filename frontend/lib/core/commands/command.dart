import 'package:flutter/widgets.dart';

class CommandContext {
  final BuildContext context;
  CommandContext(this.context);
}

class AppCommand {
  final String id;
  final String title;
  final String? category;
  final IconData? icon;
  final List<ShortcutActivator> shortcuts;
  final bool Function(CommandContext)? enabled;
  final Future<void> Function(CommandContext) run;

  const AppCommand({
    required this.id,
    required this.title,
    this.category,
    this.icon,
    this.shortcuts = const [],
    this.enabled,
    required this.run,
  });
}

class CommandRegistry {
  final Map<String, AppCommand> _commands = {};

  void register(AppCommand command) {
    _commands[command.id] = command;
  }

  void registerAll(List<AppCommand> commands) {
    for (var command in commands) {
      register(command);
    }
  }

  AppCommand? get(String id) => _commands[id];

  List<AppCommand> getAll() => _commands.values.toList();
}
