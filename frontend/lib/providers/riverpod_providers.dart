import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/editor_models.dart';

/// Provider for plot gallery data
final plotGalleryProvider = StateNotifierProvider<PlotGalleryNotifier, List<PlotData>>((ref) {
  return PlotGalleryNotifier();
});

/// Provider for keyboard shortcuts
final keyboardShortcutsProvider = StateNotifierProvider<KeyboardShortcutsNotifier, Map<String, String>>((ref) {
  return KeyboardShortcutsNotifier();
});

/// Provider for current cursor position (line, column)
final cursorPositionProvider = StateProvider<Map<String, int>>((ref) => {'line': 1, 'column': 1});

// ==================== Notifiers ====================

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

  void replaceAll(Map<String, String> shortcuts) {
    state = Map<String, String>.from(shortcuts);
  }

  void resetDefaults() {
    state = {
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
    };
  }
}
