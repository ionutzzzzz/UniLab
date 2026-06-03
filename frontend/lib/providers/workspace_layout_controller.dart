import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multi_split_view/multi_split_view.dart';

/// State class for Workspace Layout
class WorkspaceLayoutState {
  final Map<String, double> ratios;
  final Map<String, bool> visibility;
  final String activeWorkspaceName;

  WorkspaceLayoutState({
    required this.ratios,
    required this.visibility,
    this.activeWorkspaceName = 'Default',
  });

  factory WorkspaceLayoutState.defaultLayout() {
    return WorkspaceLayoutState(
      ratios: {
        'left': 0.2,
        'center': 0.55,
        'right': 0.25,
        'bottom': 0.3,
      },
      visibility: {
        'leftSidebar': true,
        'rightSidebar': true,
        'bottomConsole': true,
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'ratios': ratios,
    'visibility': visibility,
    'activeWorkspaceName': activeWorkspaceName,
  };

  factory WorkspaceLayoutState.fromJson(Map<String, dynamic> json) {
    return WorkspaceLayoutState(
      ratios: Map<String, double>.from(json['ratios'] ?? {}),
      visibility: Map<String, bool>.from(json['visibility'] ?? {}),
      activeWorkspaceName: json['activeWorkspaceName'] ?? 'Default',
    );
  }

  WorkspaceLayoutState copyWith({
    Map<String, double>? ratios,
    Map<String, bool>? visibility,
    String? activeWorkspaceName,
  }) {
    return WorkspaceLayoutState(
      ratios: ratios ?? this.ratios,
      visibility: visibility ?? this.visibility,
      activeWorkspaceName: activeWorkspaceName ?? this.activeWorkspaceName,
    );
  }
}

/// Controller to manage IDE layout persistence
class WorkspaceLayoutController extends StateNotifier<WorkspaceLayoutState> {
  final SharedPreferences _prefs;
  static const String _storageKey = 'unilab_workspace_layout';

  WorkspaceLayoutController(this._prefs) : super(WorkspaceLayoutState.defaultLayout()) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final jsonStr = _prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(jsonStr);
        state = WorkspaceLayoutState.fromJson(json);
      } catch (e) {
        debugPrint('Error loading workspace layout: $e');
      }
    }
  }

  Future<void> saveLayout() async {
    await _prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  void updateRatios(Map<String, double> newRatios) {
    state = state.copyWith(ratios: {...state.ratios, ...newRatios});
    saveLayout();
  }

  void toggleVisibility(String panelId) {
    final newVisibility = Map<String, bool>.from(state.visibility);
    newVisibility[panelId] = !(newVisibility[panelId] ?? true);
    state = state.copyWith(visibility: newVisibility);
    saveLayout();
  }

  void setVisibility(String panelId, bool visible) {
    final newVisibility = Map<String, bool>.from(state.visibility);
    newVisibility[panelId] = visible;
    state = state.copyWith(visibility: newVisibility);
    saveLayout();
  }

  /// Restores a named workspace preset
  void loadPreset(String name) {
    if (name == 'Plotting') {
      state = WorkspaceLayoutState(
        ratios: {'left': 0.15, 'center': 0.5, 'right': 0.35, 'bottom': 0.2},
        visibility: {'leftSidebar': true, 'rightSidebar': true, 'bottomConsole': true},
        activeWorkspaceName: 'Plotting',
      );
    } else if (name == 'Coding') {
      state = WorkspaceLayoutState(
        ratios: {'left': 0.2, 'center': 0.8, 'right': 0.0, 'bottom': 0.3},
        visibility: {'leftSidebar': true, 'rightSidebar': false, 'bottomConsole': true},
        activeWorkspaceName: 'Coding',
      );
    }
    saveLayout();
  }
}

/// Riverpod Provider for WorkspaceLayoutController
/// Requires a pre-initialized SharedPreferences instance
final workspaceLayoutProvider = StateNotifierProvider<WorkspaceLayoutController, WorkspaceLayoutState>((ref) {
  // Note: SharedPreferences should ideally be provided via another provider 
  // that is initialized at app startup (ref.watch(sharedPrefsProvider)).
  // For this exercise, we assume it's handled in the main.dart initialization.
  throw UnimplementedError('Initialize with SharedPreferences in ProviderScope');
});

/// Extension to convert state to MultiSplitViewController areas
extension WorkspaceLayoutX on WorkspaceLayoutState {
  List<Area> toMainAreas({
    required Widget leftChild,
    required Widget centerChild,
    required Widget rightChild,
  }) {
    final List<Area> areas = [];
    
    if (visibility['leftSidebar'] ?? true) {
      areas.add(Area(
        flex: ratios['left'] ?? 0.2,
        builder: (context, area) => leftChild,
      ));
    }
    
    areas.add(Area(
      flex: ratios['center'] ?? 0.5,
      builder: (context, area) => centerChild,
    ));
    
    if (visibility['rightSidebar'] ?? true) {
      areas.add(Area(
        flex: ratios['right'] ?? 0.3,
        builder: (context, area) => rightChild,
      ));
    }
    
    return areas;
  }
}
