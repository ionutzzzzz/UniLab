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
      environment: {
        'LANG': 'en_US.UTF-8',
        'LC_ALL': 'en_US.UTF-8',
        'TERM': 'xterm-256color',
      },
    );

    // Use a stateful decoder to handle UTF-8 sequences correctly across chunks
    pty.output
        .cast<List<int>>()
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen((data) {
      terminal.write(data);
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
