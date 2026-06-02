import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart' as p;
import '../../providers/app_provider.dart';
import 'command.dart';

final commandRegistryProvider = StateNotifierProvider<CommandRegistryNotifier, CommandRegistry>((ref) {
  return CommandRegistryNotifier();
});

class CommandRegistryNotifier extends StateNotifier<CommandRegistry> {
  CommandRegistryNotifier() : super(_buildRegistry());

  static CommandRegistry _buildRegistry() {
    final registry = CommandRegistry();
    registry.registerAll([
      AppCommand(
        id: 'file.new',
        title: 'New File',
        category: 'File',
        icon: LucideIcons.filePlus,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          app.addNewFile();
        },
      ),
      AppCommand(
        id: 'file.open',
        title: 'Open File...',
        category: 'File',
        icon: LucideIcons.folderOpen,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          await app.openFilePicker();
        },
      ),
      AppCommand(
        id: 'file.save',
        title: 'Save',
        category: 'File',
        icon: LucideIcons.save,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          await app.saveActiveFile();
        },
      ),
      AppCommand(
        id: 'run.run',
        title: 'Run Script',
        category: 'Run',
        icon: LucideIcons.play,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          await app.runActiveFile();
        },
      ),
      AppCommand(
        id: 'run.stop',
        title: 'Stop Execution',
        category: 'Run',
        icon: LucideIcons.square,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          app.stopExecution();
        },
      ),
    ]);

    return registry;
  }
}
