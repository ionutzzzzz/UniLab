import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class UniLabBridge {
  static UniLabBridge? _instance;
  late Socket _socket;
  StreamSubscription<List<int>>? _subscription;
  final Queue<Completer<Map<String, dynamic>>> _pendingRequests = Queue();

  String? _sessionId;
  bool _initialized = false;
  String? _serverProcessHandle;

  UniLabBridge._();

  static UniLabBridge get instance {
    _instance ??= UniLabBridge._();
    return _instance!;
  }

  String? get sessionId => _sessionId;
  bool get initialized => _initialized;

  /// Initialize the bridge and start the Python server
  Future<void> initialize(String backendPath) async {
    if (_initialized) return;

    try {
      // Start Python server as subprocess
      await _startPythonServer(backendPath);

      // Connect to the server
      await _connectToServer();

      _initialized = true;
      debugPrint('[UniLabBridge] Initialized successfully');
    } catch (e) {
      _initialized = false;
      debugPrint('[UniLabBridge] Initialization failed: $e');
      rethrow;
    }
  }

  Future<void> _startPythonServer(String backendPath) async {
    try {
      // Start server in background (don't wait for it)
      Process.start(
        'python3',
        [
          p.join(backendPath, 'unilab_server.py'),
          '--host', '127.0.0.1',
          '--port', '9999',
        ],
        workingDirectory: backendPath,
      ).then((process) {
        debugPrint('[UniLabBridge] Python server process started (PID: ${process.pid})');
        // Stream output for debugging
        process.stdout
            .transform(utf8.decoder)
            .listen((output) => debugPrint('[Server] $output'));
        process.stderr
            .transform(utf8.decoder)
            .listen((output) => debugPrint('[Server Error] $output'));
      }).catchError((e) {
        debugPrint('[UniLabBridge] Failed to start server process: $e');
      });

      debugPrint('[UniLabBridge] Started Python server process');
    } catch (e) {
      debugPrint('[UniLabBridge] Error starting server: $e');
      // Server might already be running, try to connect anyway
    }
  }

  Future<void> _connectToServer() async {
    // Wait for server to be ready (give it time to start)
    await Future.delayed(const Duration(seconds: 2));

    try {
      _socket = await Socket.connect('127.0.0.1', 9999);
      debugPrint('[UniLabBridge] Connected to Python server');

      // Listen for responses - accumulate data and process line by line
      var buffer = '';
      _subscription = _socket.listen((data) {
        buffer += utf8.decode(data);
        final parts = buffer.split('\n');
        // Process all complete lines
        for (int i = 0; i < parts.length - 1; i++) {
          if (parts[i].isNotEmpty) {
            _handleServerResponse(parts[i]);
          }
        }
        // Keep the incomplete last part in buffer
        buffer = parts.last;
      });
    } catch (e) {
      debugPrint('[UniLabBridge] Failed to connect to server: $e');
      rethrow;
    }
  }

  void _handleServerResponse(String line) {
    try {
      if (line.isEmpty) return;

      final response = jsonDecode(line) as Map<String, dynamic>;

      if (_pendingRequests.isNotEmpty) {
        final completer = _pendingRequests.removeFirst();
        completer.complete(response);
      }
    } catch (e) {
      debugPrint('[UniLabBridge] Error handling server response: $e');
    }
  }

  Future<Map<String, dynamic>> _sendRequest(String method, Map<String, dynamic> params) async {
    if (!_initialized) throw StateError('Bridge not initialized');

    final request = {
      'method': method,
      'params': params,
    };

    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests.add(completer);

    _socket.writeln(jsonEncode(request));

    return completer.future.timeout(Duration(seconds: 30));
  }

  /// Create a new session
  Future<String> createSession(String username) async {
    try {
      final response = await _sendRequest('create_session', {'username': username});

      if (response['success'] == true && response['session_id'] != null) {
        _sessionId = response['session_id'] as String;
        debugPrint('[UniLabBridge] Session created: $_sessionId');
        return _sessionId!;
      } else {
        throw Exception('Failed to create session: ${response['error']}');
      }
    } catch (e) {
      debugPrint('[UniLabBridge] createSession error: $e');
      rethrow;
    }
  }

  /// Execute code in the current session
  Future<ExecutionResult> execute(String code) async {
    if (!_initialized || _sessionId == null) {
      throw StateError('Bridge not initialized or session not created');
    }

    try {
      final response = await _sendRequest('execute', {
        'session_id': _sessionId,
        'code': code,
      });

      return ExecutionResult.fromJson(response);
    } catch (e) {
      debugPrint('[UniLabBridge] execute error: $e');
      rethrow;
    }
  }

  /// Get workspace variables
  Future<Map<String, dynamic>> getWorkspace() async {
    if (!_initialized || _sessionId == null) {
      throw StateError('Bridge not initialized');
    }

    try {
      final response = await _sendRequest('get_workspace', {
        'session_id': _sessionId,
      });

      return response['variables'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      debugPrint('[UniLabBridge] getWorkspace error: $e');
      return {};
    }
  }

  /// Get autocomplete suggestions
  Future<List<String>> getAutocomplete(String text) async {
    if (!_initialized || _sessionId == null) {
      return [];
    }

    try {
      final response = await _sendRequest('get_autocomplete', {
        'session_id': _sessionId,
        'text': text,
      });

      if (response['suggestions'] is List) {
        return List<String>.from(response['suggestions'] as List<dynamic>);
      }
      return [];
    } catch (e) {
      debugPrint('[UniLabBridge] getAutocomplete error: $e');
      return [];
    }
  }

  /// List files in the session workspace
  Future<List<Map<String, dynamic>>> listFiles() async {
    if (!_initialized || _sessionId == null) {
      return [];
    }

    try {
      final response = await _sendRequest('list_files', {
        'session_id': _sessionId,
      });

      if (response['files'] is List) {
        return List<Map<String, dynamic>>.from(
          (response['files'] as List<dynamic>).map((f) => f as Map<String, dynamic>)
        );
      }
      return [];
    } catch (e) {
      debugPrint('[UniLabBridge] listFiles error: $e');
      return [];
    }
  }

  /// Create or overwrite a file
  Future<void> createFile(String filename, String content) async {
    if (!_initialized || _sessionId == null) {
      throw StateError('Bridge not initialized');
    }

    try {
      final response = await _sendRequest('create_file', {
        'session_id': _sessionId,
        'filename': filename,
        'content': content,
      });

      if (response['success'] != true) {
        throw Exception('Failed to create file: ${response['error']}');
      }
      debugPrint('[UniLabBridge] File created: $filename');
    } catch (e) {
      debugPrint('[UniLabBridge] createFile error: $e');
      rethrow;
    }
  }

  /// Find the backend path
  static Future<String> findBackendPath() async {
    try {
      // Try relative path from executable
      final exe = File(Platform.resolvedExecutable);
      final backendPath = p.join(exe.parent.path, '..', '..', '..', 'backend');
      final backendDir = Directory(backendPath);
      if (await backendDir.exists()) {
        debugPrint('[UniLabBridge] Found backend at: $backendPath');
        return backendPath;
      }
    } catch (e) {
      debugPrint('[UniLabBridge] Relative path lookup failed: $e');
    }

    // Try environment variable
    final envPath = Platform.environment['UNILAB_BACKEND_PATH'];
    if (envPath != null && await Directory(envPath).exists()) {
      debugPrint('[UniLabBridge] Found backend via UNILAB_BACKEND_PATH: $envPath');
      return envPath;
    }

    // Try common paths
    final commonPaths = [
      '/home/john/Documents/GitHub/UniLab/backend',
      p.join(Directory.current.path, 'backend'),
    ];

    for (final path in commonPaths) {
      if (await Directory(path).exists()) {
        debugPrint('[UniLabBridge] Found backend at: $path');
        return path;
      }
    }

    throw StateError(
      'Cannot find backend directory. '
      'Set UNILAB_BACKEND_PATH environment variable or ensure backend/ is relative to the executable.',
    );
  }

  Future<void> dispose() async {
    if (_initialized) {
      await _subscription?.cancel();
      await _socket.close();
      _initialized = false;
    }
  }
}

// Helper for managing a queue
class Queue<T> {
  final _list = <T>[];

  void add(T value) => _list.add(value);
  T removeFirst() => _list.removeAt(0);
  bool get isEmpty => _list.isEmpty;
  bool get isNotEmpty => _list.isNotEmpty;
}
