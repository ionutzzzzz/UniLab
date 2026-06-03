import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/workspace_variable.dart';

final workspaceVariablesProvider =
    StateNotifierProvider<WorkspaceVariablesNotifier, List<WorkspaceVariable>>((ref) {
  return WorkspaceVariablesNotifier();
});

class WorkspaceVariablesNotifier extends StateNotifier<List<WorkspaceVariable>> {
  WorkspaceVariablesNotifier() : super([]);

  /// Replace all variables with a new list (called from AppProvider when execution completes).
  void replaceAll(List<WorkspaceVariable> vars) {
    state = vars;
  }

  /// Clear all variables.
  void clear() {
    state = [];
  }
}
