import 'dart:io';
import 'dart:convert';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

class TerminalSession {
  final String id;
  final String name;
  final Terminal terminal;
  final Pty pty;
  
  TerminalSession({
    required this.id,
    required this.name,
    required this.terminal,
    required this.pty,
  });

  void dispose() {
    pty.kill();
  }

  static String get _shell {
    if (Platform.isWindows) {
      return 'powershell.exe';
    } else if (Platform.isMacOS) {
      final env = Platform.environment;
      return env['SHELL'] ?? 'zsh';
    } else {
      final env = Platform.environment;
      return env['SHELL'] ?? 'bash';
    }
  }

  static TerminalSession create(String id, String name) {
    final terminal = Terminal(
      maxLines: 10000,
    );

    final shell = _shell;

    final pty = Pty.start(
      shell,
      columns: terminal.viewWidth,
      rows: terminal.viewHeight,
    );

    pty.output.cast<List<int>>().listen((data) {
      terminal.write(String.fromCharCodes(data));
    });

    terminal.onOutput = (data) {
      pty.write(const Utf8Encoder().convert(data));
    };

    terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      pty.resize(height, width);
    };

    return TerminalSession(
      id: id,
      name: name,
      terminal: terminal,
      pty: pty,
    );
  }
}
