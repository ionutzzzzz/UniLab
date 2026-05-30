import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'command.dart';

final commandRegistryProvider = Provider<CommandRegistry>((ref) {
  final registry = CommandRegistry();
  
  registry.registerAll([
    AppCommand(
      id: 'file.new',
      title: 'New File',
      category: 'File',
      icon: LucideIcons.filePlus,
      run: (ctx) async {
        // Implement
      },
    ),
    AppCommand(
      id: 'file.open',
      title: 'Open File...',
      category: 'File',
      icon: LucideIcons.folderOpen,
      run: (ctx) async {
        // Implement
      },
    ),
    AppCommand(
      id: 'file.save',
      title: 'Save',
      category: 'File',
      icon: LucideIcons.save,
      run: (ctx) async {
        // Implement
      },
    ),
    AppCommand(
      id: 'run.run',
      title: 'Run Script',
      category: 'Run',
      icon: LucideIcons.play,
      run: (ctx) async {
        // Implement
      },
    ),
    AppCommand(
      id: 'run.stop',
      title: 'Stop Execution',
      category: 'Run',
      icon: LucideIcons.square,
      run: (ctx) async {
        // Implement
      },
    ),
  ]);

  return registry;
});
