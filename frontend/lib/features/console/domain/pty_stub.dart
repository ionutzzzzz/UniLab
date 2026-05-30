import 'dart:async';

class Pty {
  static Pty start(
    String executable, {
    List<String> arguments = const [],
    String? workingDirectory,
    Map<String, String>? environment,
    int columns = 80,
    int rows = 24,
  }) {
    return Pty();
  }

  Stream<List<int>> get output => const Stream.empty();

  void write(List<int> data) {}

  void resize(int rows, int columns) {}

  void kill() {}
}

class Platform {
  static bool get isWindows => false;
  static bool get isMacOS => false;
  static bool get isLinux => false;
}
