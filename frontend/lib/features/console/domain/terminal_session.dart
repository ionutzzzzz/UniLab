import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';

// Conditional imports for PTY
import 'pty_stub.dart' if (dart.library.io) 'package:flutter_pty/flutter_pty.dart';
// Conditional import for Platform info
import 'dart:io' if (dart.library.html) 'pty_stub.dart' as platform_impl;

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
    if (kIsWeb) return 'web-shell';
    
    if (platform_impl.Platform.isWindows) {
      return 'powershell.exe';
    } else {
      // For Linux/macOS
      return 'bash';
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

    // Only listen if it's not a stub (stub output is empty stream)
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
