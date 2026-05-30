import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/workspace_variable.dart';

final workspaceVariablesProvider = StreamProvider<List<WorkspaceVariable>>((ref) async* {
  // Mock data for initial UI
  yield [
    const WorkspaceVariable(name: 't', value: '1x200 double', size: '200x1', typeClass: 'double', min: '0', max: '5'),
    const WorkspaceVariable(name: 'y', value: '1x200 double', size: '200x1', typeClass: 'double', min: '0', max: '0.9933'),
    const WorkspaceVariable(name: 'sys', value: '1x1 tf', size: '1x1', typeClass: 'tf'),
    const WorkspaceVariable(name: 'options', value: '1x1 struct', size: '1x1', typeClass: 'struct'),
  ];
});
