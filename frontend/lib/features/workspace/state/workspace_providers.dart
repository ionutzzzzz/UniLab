import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/workspace_variable.dart';

const defaultSystemVariables = {
  'ans',
  'i',
  'j',
  'pi',
  'inf',
  'Inf',
  'nan',
  'NaN',
  'eps',
  'realmax',
  'realmin',
  'true',
  'false',
  'IS_HEADLESS',
  'np',
  'plt',
  'signal',
  'unilab_cwd_ctx',
  'unilab_workspace_ctx',
  'unilab_update_ctx',
  'unilab_end',
  'UnilabEnd',
  'UnilabHandle',
  'UnilabCVPartition',
  'ContextVar',
  'addpath',
  'abs',
  'stats',
  'ml',
  'scipy_fft',
  'scipy_ifft',
  'scipy_fftshift',
  'scipy_ifftshift',
};

bool isDefaultSystemVariable(String name) {
  if (name.startsWith('_')) return true;
  final lower = name.toLowerCase();
  if (lower.startsWith('unilab_') || lower.startsWith('unilab')) return true;
  return defaultSystemVariables.contains(name);
}

final showDefaultVariablesProvider = StateProvider<bool>((ref) => false);

final workspaceVariablesProvider =
    StateNotifierProvider<WorkspaceVariablesNotifier, List<WorkspaceVariable>>((ref) {
  return WorkspaceVariablesNotifier();
});

final filteredWorkspaceVariablesProvider = Provider<List<WorkspaceVariable>>((ref) {
  final allVars = ref.watch(workspaceVariablesProvider);
  final showDefaults = ref.watch(showDefaultVariablesProvider);
  if (showDefaults) return allVars;
  return allVars.where((v) => !isDefaultSystemVariable(v.name)).toList();
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
