import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/workspace_variable.dart';

final workspaceVariablesProvider =
    StateNotifierProvider<WorkspaceVariablesNotifier, List<WorkspaceVariable>>((ref) {
  return WorkspaceVariablesNotifier();
});

final selectedVariableNameProvider = StateProvider<String?>((ref) => null);

final selectedVariableProvider = Provider<WorkspaceVariable?>((ref) {
  final name = ref.watch(selectedVariableNameProvider);
  if (name == null) return null;
  final variables = ref.watch(workspaceVariablesProvider);
  try {
    return variables.firstWhere((v) => v.name == name);
  } catch (_) {
    return null;
  }
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
