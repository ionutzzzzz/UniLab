import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/terminal_session.dart';

final terminalSessionsProvider = NotifierProvider<TerminalSessionsNotifier, List<TerminalSession>>(
  TerminalSessionsNotifier.new,
);

final activeTerminalSessionIdProvider = StateProvider<String?>((ref) {
  final sessions = ref.watch(terminalSessionsProvider);
  return sessions.isNotEmpty ? sessions.first.id : null;
});

class TerminalSessionsNotifier extends Notifier<List<TerminalSession>> {
  @override
  List<TerminalSession> build() {
    return [];
  }

  void addSession([String? name]) {
    final id = const Uuid().v4();
    final sessionName = name ?? 'Terminal ${state.length + 1}';
    final session = TerminalSession.create(id, sessionName);
    
    state = [...state, session];
    ref.read(activeTerminalSessionIdProvider.notifier).state = id;
  }

  void removeSession(String id) {
    final session = state.firstWhere((s) => s.id == id);
    session.dispose();
    
    state = state.where((s) => s.id != id).toList();
    
    if (state.isNotEmpty) {
      ref.read(activeTerminalSessionIdProvider.notifier).state = state.last.id;
    } else {
      ref.read(activeTerminalSessionIdProvider.notifier).state = null;
    }
  }

  void disposeAll() {
    for (var session in state) {
      session.dispose();
    }
    state = [];
  }
}
