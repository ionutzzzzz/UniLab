import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart' as p;
import '../../providers/app_provider.dart';
import '../layout/shell_layout_state.dart';
import 'command.dart';

final commandRegistryProvider = StateNotifierProvider<CommandRegistryNotifier, CommandRegistry>((ref) {
  return CommandRegistryNotifier(ref);
});

class CommandRegistryNotifier extends StateNotifier<CommandRegistry> {
  CommandRegistryNotifier(Ref ref) : super(_buildRegistry(ref));

  static CommandRegistry _buildRegistry(Ref ref) {
    final registry = CommandRegistry();
    registry.registerAll([
      AppCommand(
        id: 'file.new',
        title: 'New Script',
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
        id: 'file.openFolder',
        title: 'Open Project Folder...',
        category: 'File',
        icon: LucideIcons.folder,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          await app.openFolderPicker();
        },
      ),
      AppCommand(
        id: 'file.save',
        title: 'Save Active File',
        category: 'File',
        icon: LucideIcons.save,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          await app.saveActiveFile();
        },
      ),
      AppCommand(
        id: 'file.saveAs',
        title: 'Save File As...',
        category: 'File',
        icon: LucideIcons.save,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          await app.saveActiveFileAs();
        },
      ),
      AppCommand(
        id: 'file.importData',
        title: 'Import Data Wizard',
        category: 'File',
        icon: LucideIcons.database,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          app.openImportDataTab();
        },
      ),
      AppCommand(
        id: 'file.exportPdf',
        title: 'Export Script to PDF',
        category: 'File',
        icon: LucideIcons.fileText,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          await app.exportToPdf();
        },
      ),
      AppCommand(
        id: 'file.exportPython',
        title: 'Export Script to Python (.py)',
        category: 'File',
        icon: LucideIcons.code,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          await app.exportToPython();
        },
      ),
      AppCommand(
        id: 'file.exportHtml',
        title: 'Export HTML Report',
        category: 'File',
        icon: LucideIcons.globe,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          await app.exportToHtmlReport();
        },
      ),
      AppCommand(
        id: 'file.print',
        title: 'Print Active Script',
        category: 'File',
        icon: LucideIcons.printer,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          await app.printActiveFile();
        },
      ),
      AppCommand(
        id: 'file.closeProject',
        title: 'Close Project (Return to Welcome)',
        category: 'File',
        icon: LucideIcons.logOut,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          app.resetToWelcome();
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
      AppCommand(
        id: 'editor.find',
        title: 'Find in File',
        category: 'Editor',
        icon: LucideIcons.search,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          app.triggerEditorAction('editor.find');
        },
      ),
      AppCommand(
        id: 'editor.replace',
        title: 'Find and Replace in File',
        category: 'Editor',
        icon: LucideIcons.replace,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          app.triggerEditorAction('editor.replace');
        },
      ),
      AppCommand(
        id: 'editor.gotoLine',
        title: 'Go to Line...',
        category: 'Editor',
        icon: LucideIcons.cornerDownRight,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          app.triggerEditorAction('editor.gotoLine');
        },
      ),
      AppCommand(
        id: 'editor.autoIndent',
        title: 'Auto Indent Script',
        category: 'Editor',
        icon: LucideIcons.indentIncrease,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          app.triggerEditorAction('editor.autoIndent');
        },
      ),
      AppCommand(
        id: 'editor.comment',
        title: 'Toggle Line Comment',
        category: 'Editor',
        icon: LucideIcons.messageSquareCode,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          app.triggerEditorAction('editor.comment');
        },
      ),
      AppCommand(
        id: 'workspace.clear',
        title: 'Clear Workspace Variables',
        category: 'Workspace',
        icon: LucideIcons.trash2,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          await app.clearWorkspace();
        },
      ),
      AppCommand(
        id: 'console.clear',
        title: 'Clear Console Output',
        category: 'Console',
        icon: LucideIcons.eraser,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          app.clearConsole();
        },
      ),
      AppCommand(
        id: 'view.toggleExplorer',
        title: 'Toggle File Explorer Panel',
        category: 'View',
        icon: LucideIcons.folder,
        run: (ctx) async {
          ref.read(shellLayoutProvider.notifier).toggleLeftPanel();
        },
      ),
      AppCommand(
        id: 'view.toggleWorkspace',
        title: 'Toggle Workspace Panel',
        category: 'View',
        icon: LucideIcons.layoutGrid,
        run: (ctx) async {
          ref.read(shellLayoutProvider.notifier).toggleRightPanel();
        },
      ),
      AppCommand(
        id: 'view.toggleConsole',
        title: 'Toggle Console Dock',
        category: 'View',
        icon: LucideIcons.terminal,
        run: (ctx) async {
          ref.read(shellLayoutProvider.notifier).toggleBottomPanel();
        },
      ),
      AppCommand(
        id: 'view.splitEditor',
        title: 'Toggle Split Editor',
        category: 'View',
        icon: LucideIcons.columns2,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          app.toggleSplitEditor();
        },
      ),
      AppCommand(
        id: 'view.resetLayout',
        title: 'Reset Layout to Default',
        category: 'View',
        icon: LucideIcons.layoutTemplate,
        run: (ctx) async {
          ref.read(shellLayoutProvider.notifier).resetLayout();
        },
      ),
      AppCommand(
        id: 'view.commandOnly',
        title: 'Toggle Command Only Mode',
        category: 'View',
        icon: LucideIcons.terminal,
        run: (ctx) async {
          final layout = ref.read(shellLayoutProvider);
          if (layout.isCommandOnlyMode) {
            ref.read(shellLayoutProvider.notifier).resetLayout();
          } else {
            ref.read(shellLayoutProvider.notifier).setCommandOnlyMode();
          }
        },
      ),
      AppCommand(
        id: 'backend.restart',
        title: 'Restart Computation Kernel',
        category: 'Backend',
        icon: LucideIcons.refreshCw,
        run: (ctx) async {
          final app = p.Provider.of<AppProvider>(ctx.context, listen: false);
          await app.restartBackend();
        },
      ),
    ]);

    return registry;
  }
}
