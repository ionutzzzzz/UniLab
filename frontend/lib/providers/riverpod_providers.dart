import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/editor_models.dart';

/// Provider for current active editor tab index
final activeEditorTabProvider = StateProvider<int>((ref) => 0);

/// Provider for open files in the editor
final openFilesProvider = StateNotifierProvider<OpenFilesNotifier, List<OpenFile>>((ref) {
  return OpenFilesNotifier();
});

/// Provider for editor content of active file
final activeEditorContentProvider = StateProvider<String>((ref) => '');

/// Provider for workspace variables
final workspaceVariablesProvider = StateNotifierProvider<WorkspaceVariablesNotifier, List<WorkspaceVariable>>((ref) {
  return WorkspaceVariablesNotifier();
});

/// Provider for console output
final consoleOutputProvider = StateNotifierProvider<ConsoleOutputNotifier, List<ConsoleMessage>>((ref) {
  return ConsoleOutputNotifier();
});

/// Provider for console filter
final consoleFilterProvider = StateProvider<String>((ref) => 'All');

/// Provider for currently executing file
final executingFileProvider = StateProvider<bool>((ref) => false);

/// Provider for plot gallery data
final plotGalleryProvider = StateNotifierProvider<PlotGalleryNotifier, List<PlotData>>((ref) {
  return PlotGalleryNotifier();
});

/// Provider for IDE theme mode (dark/light)
final themeModeProvider = StateProvider<bool>((ref) => true); // true = dark, false = light

/// Provider for keyboard shortcuts
final keyboardShortcutsProvider = StateNotifierProvider<KeyboardShortcutsNotifier, Map<String, String>>((ref) {
  return KeyboardShortcutsNotifier();
});

/// Provider for command palette history
final commandPaletteHistoryProvider = StateNotifierProvider<CommandHistoryNotifier, List<String>>((ref) {
  return CommandHistoryNotifier();
});

// ==================== Notifiers ====================

class OpenFilesNotifier extends StateNotifier<List<OpenFile>> {
  OpenFilesNotifier() : super([]);

  void addFile(OpenFile file) {
    state = [...state, file];
  }

  void removeFile(int index) {
    state = [...state]..removeAt(index);
  }

  void updateFile(int index, OpenFile file) {
    final files = [...state];
    files[index] = file;
    state = files;
  }

  void closeAllFiles() {
    state = [];
  }
}

class WorkspaceVariablesNotifier extends StateNotifier<List<WorkspaceVariable>> {
  WorkspaceVariablesNotifier() : super([]);

  void addVariable(WorkspaceVariable variable) {
    state = [...state, variable];
  }

  void removeVariable(String name) {
    state = state.where((v) => v.name != name).toList();
  }

  void updateVariable(String name, WorkspaceVariable variable) {
    state = [
      for (final v in state)
        if (v.name == name) variable else v,
    ];
  }

  void clearAll() {
    state = [];
  }
}

class ConsoleOutputNotifier extends StateNotifier<List<ConsoleMessage>> {
  ConsoleOutputNotifier() : super([]);

  void addMessage(ConsoleMessage message) {
    state = [...state, message];
  }

  void clearAll() {
    state = [];
  }
}

class PlotGalleryNotifier extends StateNotifier<List<PlotData>> {
  PlotGalleryNotifier() : super([]);

  void addPlot(PlotData plot) {
    state = [...state, plot];
  }

  void removePlot(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  void clearAll() {
    state = [];
  }

  /// Replace all plots with a new list (called from AppProvider).
  void replaceAll(List<PlotData> plots) {
    state = plots;
  }
}

class KeyboardShortcutsNotifier extends StateNotifier<Map<String, String>> {
  KeyboardShortcutsNotifier()
      : super({
          'new_file': 'Ctrl+N',
          'open_file': 'Ctrl+O',
          'save_file': 'Ctrl+S',
          'find': 'Ctrl+F',
          'find_replace': 'Ctrl+H',
          'command_palette': 'Ctrl+Shift+P',
          'run': 'Ctrl+Enter',
          'stop': 'Ctrl+.',
          'comment': 'Ctrl+/',
          'indent': 'Tab',
          'dedent': 'Shift+Tab',
          'format': 'Ctrl+Shift+I',
          'undo': 'Ctrl+Z',
          'redo': 'Ctrl+Y',
        });

  void updateShortcut(String action, String keys) {
    state = {...state, action: keys};
  }
}

class CommandHistoryNotifier extends StateNotifier<List<String>> {
  CommandHistoryNotifier() : super([]);

  void addCommand(String command) {
    state = [command, ...state.where((c) => c != command)];
    if (state.length > 50) {
      state = state.take(50).toList();
    }
  }

  void clearHistory() {
    state = [];
  }
}
