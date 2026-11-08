import '../utils/platform_io.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:isolate';
import 'platform_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import '../models/models.dart';

// FFI Signatures
typedef UnilabInitNative = Int32 Function(Pointer<Utf8> backendPath);
typedef UnilabInit = int Function(Pointer<Utf8> backendPath);

typedef UnilabCreateSessionNative = Pointer<Utf8> Function(Pointer<Utf8> username);
typedef UnilabCreateSession = Pointer<Utf8> Function(Pointer<Utf8> username);

typedef UnilabDestroySessionNative = Int32 Function(Pointer<Utf8> sessionId);
typedef UnilabDestroySession = int Function(Pointer<Utf8> sessionId);

typedef UnilabExecuteNative = Pointer<Utf8> Function(
  Pointer<Utf8> sessionId,
  Pointer<Utf8> code,
  Double timeout,
);
typedef UnilabExecute = Pointer<Utf8> Function(
  Pointer<Utf8> sessionId,
  Pointer<Utf8> code,
  double timeout,
);

typedef UnilabExecuteWithFilenameNative = Pointer<Utf8> Function(
  Pointer<Utf8> sessionId,
  Pointer<Utf8> code,
  Pointer<Utf8> filename,
  Double timeout,
);
typedef UnilabExecuteWithFilename = Pointer<Utf8> Function(
  Pointer<Utf8> sessionId,
  Pointer<Utf8> code,
  Pointer<Utf8> filename,
  double timeout,
);

typedef UnilabGetWorkspaceNative = Pointer<Utf8> Function(Pointer<Utf8> sessionId);
typedef UnilabGetWorkspace = Pointer<Utf8> Function(Pointer<Utf8> sessionId);

typedef UnilabGetAutocompleteNative = Pointer<Utf8> Function(
  Pointer<Utf8> sessionId,
  Pointer<Utf8> text,
  Pointer<Utf8> line,
);
typedef UnilabGetAutocomplete = Pointer<Utf8> Function(
  Pointer<Utf8> sessionId,
  Pointer<Utf8> text,
  Pointer<Utf8> line,
);

typedef UnilabListFilesNative = Pointer<Utf8> Function(Pointer<Utf8> sessionId);
typedef UnilabListFiles = Pointer<Utf8> Function(Pointer<Utf8> sessionId);

typedef UnilabTranspileNative = Pointer<Utf8> Function(Pointer<Utf8> code);
typedef UnilabTranspile = Pointer<Utf8> Function(Pointer<Utf8> code);

typedef UnilabCreateFileNative = Pointer<Utf8> Function(
  Pointer<Utf8> sessionId,
  Pointer<Utf8> filename,
  Pointer<Utf8> content,
);
typedef UnilabCreateFile = Pointer<Utf8> Function(
  Pointer<Utf8> sessionId,
  Pointer<Utf8> filename,
  Pointer<Utf8> content,
);

typedef UnilabFreeStringNative = Void Function(Pointer<Utf8> ptr);
typedef UnilabFreeString = void Function(Pointer<Utf8> ptr);

typedef UnilabPingNative = Int32 Function();
typedef UnilabPing = int Function();

typedef WorkspaceCallbackNative = Void Function(
  Pointer<Utf8> sessionId,
  Pointer<Utf8> variablesJson,
);
typedef UnilabSetWorkspaceCallbackNative = Void Function(
  Pointer<NativeFunction<WorkspaceCallbackNative>> callback,
);
typedef UnilabSetWorkspaceCallback = void Function(
  Pointer<NativeFunction<WorkspaceCallbackNative>> callback,
);

typedef EventCallbackNative = Void Function(
  Pointer<Utf8> sessionId,
  Pointer<Utf8> eventType,
  Pointer<Utf8> dataJson,
);
typedef UnilabSetEventCallbackNative = Void Function(
  Pointer<NativeFunction<EventCallbackNative>> callback,
);
typedef UnilabSetEventCallback = void Function(
  Pointer<NativeFunction<EventCallbackNative>> callback,
);

typedef UnilabSendSimEventNative = Void Function(Pointer<Utf8> eventJson);
typedef UnilabSendSimEvent = void Function(Pointer<Utf8> eventJson);

class UniLabBridge {
  static UniLabBridge? _instance;
  static final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  // Shared library and functions available on the main isolate
  static DynamicLibrary? _mainLib;
  static UnilabFreeString? _unilabFreeString;
  static UnilabSendSimEvent? _mainSendSimEvent;
  static UnilabDestroySession? _mainDestroySession;
  static UnilabSetWorkspaceCallback? _mainSetWorkspaceCallback;
  static UnilabSetEventCallback? _mainSetEventCallback;

  String? _sessionId;
  String? _backendPath;
  bool _initialized = false;
  bool _disposed = false;

  // Keep native callbacks alive
  NativeCallable<WorkspaceCallbackNative>? _wsCallback;
  NativeCallable<EventCallbackNative>? _eventCallback;

  // Worker isolate communication
  Isolate? _workerIsolate;
  SendPort? _workerSendPort;
  ReceivePort _mainReceivePort = ReceivePort();
  Completer<void> _workerReady = Completer<void>();
  final Set<SendPort> _inFlightReplyPorts = {};

  UniLabBridge._() {
    _startWorker();
  }

  static UniLabBridge get instance {
    _instance ??= UniLabBridge._();
    return _instance!;
  }

  static void resetInstance() {
    final prev = _instance;
    _instance = null;
    if (prev != null) {
      unawaited(prev.dispose());
    }
  }

  String? get sessionId => _sessionId;
  bool get initialized => _initialized;
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  /// Optional configuration hook (used by Web client; accepted on Native for parity).
  void configure({String? kernelAddress, int? connectionTimeout}) {}

  static DynamicLibrary _loadLibraryHandle(String backendPath) {
    final String libName = Platform.isLinux
        ? 'libunilab_core.so'
        : (Platform.isMacOS ? 'libunilab_core.dylib' : 'unilab_core.dll');

    final candidates = <String>[];
    try {
      if (Platform.resolvedExecutable.isNotEmpty) {
        final exeDir = Directory(Platform.resolvedExecutable).parent.path;
        candidates.addAll([
          p.join(exeDir, 'lib', libName),
          p.join(exeDir, '..', 'Frameworks', libName),
          p.join(exeDir, libName),
          p.join(p.dirname(exeDir), 'python', 'lib', libName),
        ]);
      }
    } catch (_) {}

    final cwd = Directory.current.path;
    final parentCwd = p.dirname(cwd);

    candidates.addAll([
      p.join(backendPath, 'backend', 'target', 'release', libName),
      p.join(backendPath, 'backend', 'target', 'debug', libName),
      p.join(backendPath, 'target', 'release', libName),
      p.join(backendPath, 'target', 'debug', libName),
      p.join(backendPath, 'frontend', 'macos', 'Frameworks', libName),
      p.join(backendPath, 'frontend', 'linux', libName),
      p.join(backendPath, 'frontend', 'windows', libName),
      p.join(cwd, 'backend', 'target', 'release', libName),
      p.join(cwd, 'backend', 'target', 'debug', libName),
      p.join(cwd, 'macos', 'Frameworks', libName),
      p.join(cwd, 'linux', libName),
      p.join(cwd, 'windows', libName),
      p.join(parentCwd, 'backend', 'target', 'release', libName),
      p.join(parentCwd, 'backend', 'target', 'debug', libName),
      p.join(parentCwd, 'frontend', 'macos', 'Frameworks', libName),
      p.join(parentCwd, 'frontend', 'linux', libName),
      p.join(parentCwd, 'frontend', 'windows', libName),
      p.join(cwd, libName),
      libName,
    ]);

    for (final loc in candidates) {
      try {
        debugPrint('[UniLabBridge] Attempting to load library from: $loc');
        return DynamicLibrary.open(loc);
      } catch (e) {
        debugPrint('[UniLabBridge] Failed to load from $loc: $e');
      }
    }
    throw Exception('Could not load library $libName. Searched in: $candidates');
  }

  Future<void> _startWorker() async {
    _workerIsolate = await Isolate.spawn(_workerEntry, _mainReceivePort.sendPort);

    _mainReceivePort.listen((message) {
      if (message is SendPort) {
        _workerSendPort = message;
        if (!_workerReady.isCompleted) {
          _workerReady.complete();
        }
      } else if (message is Map<String, dynamic>) {
        if (message['type'] == 'event') {
          _eventController.add(message);
        }
      }
    });
  }

  Future<dynamic> _sendCommand(
    String command,
    Map<String, dynamic> params, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (_disposed) {
      throw StateError('UniLabBridge has been disposed');
    }
    await _workerReady.future;
    final responsePort = ReceivePort();
    final replySendPort = responsePort.sendPort;
    if (command == 'execute') {
      _inFlightReplyPorts.add(replySendPort);
    }
    _workerSendPort!.send({
      'command': command,
      'params': params,
      'replyPort': replySendPort,
    });

    try {
      final result = await responsePort.first.timeout(timeout);
      if (result is Map && result['error'] != null) {
        throw Exception(result['error']);
      }
      return result;
    } on TimeoutException {
      throw Exception('Command $command timed out after ${timeout.inSeconds}s');
    } finally {
      _inFlightReplyPorts.remove(replySendPort);
      responsePort.close();
    }
  }

  /// Initialize the bridge.
  Future<void> initialize([String? customBackendPath]) async {
    if (_initialized) return;

    debugPrint('[UniLabBridge] Starting initialization sequence...');
    final backendPath = (customBackendPath != null && customBackendPath.isNotEmpty)
        ? customBackendPath
        : await findBackendPath();
    _backendPath = backendPath;
    debugPrint('[UniLabBridge] Resolved backend path: $backendPath');

    // Load library in main isolate for callbacks, non-blocking sim events, and cleanup
    _mainLib = _loadLibraryHandle(backendPath);
    _unilabFreeString =
        _mainLib!.lookupFunction<UnilabFreeStringNative, UnilabFreeString>(
          'unilab_free_string',
        );
    _mainSendSimEvent =
        _mainLib!.lookupFunction<UnilabSendSimEventNative, UnilabSendSimEvent>(
          'unilab_send_sim_event',
        );
    _mainDestroySession =
        _mainLib!.lookupFunction<UnilabDestroySessionNative, UnilabDestroySession>(
          'unilab_destroy_session',
        );
    _mainSetWorkspaceCallback = _mainLib!.lookupFunction<
        UnilabSetWorkspaceCallbackNative,
        UnilabSetWorkspaceCallback>('unilab_set_workspace_callback');
    _mainSetEventCallback = _mainLib!.lookupFunction<
        UnilabSetEventCallbackNative,
        UnilabSetEventCallback>('unilab_set_event_callback');

    _wsCallback =
        NativeCallable<WorkspaceCallbackNative>.listener(_onWorkspaceChanged);
    _eventCallback = NativeCallable<EventCallbackNative>.listener(_onSimEvent);

    _mainSetWorkspaceCallback!(_wsCallback!.nativeFunction);
    _mainSetEventCallback!(_eventCallback!.nativeFunction);

    final initRes = await _sendCommand(
      'initialize',
      {'backendPath': backendPath},
      timeout: const Duration(seconds: 60),
    );
    if (initRes is! Map || initRes['success'] != true) {
      throw Exception(
        (initRes is Map ? initRes['error'] : null) ??
            'Failed to initialize Python/Rust backend',
      );
    }

    bool isReady = false;
    int retries = 0;
    const maxRetries = 20;

    while (!isReady && retries < maxRetries) {
      try {
        final res = await _sendCommand(
          'ping',
          const {},
          timeout: const Duration(seconds: 10),
        );
        if (res is Map && res['success'] == true) {
          isReady = true;
          debugPrint('[UniLabBridge] Backend is ready after ${retries + 1} checks.');
        } else {
          throw Exception('Ping failed');
        }
      } catch (_) {
        retries++;
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }

    if (!isReady) {
      throw StateError(
        'Backend failed to reach ready state after $maxRetries attempts.',
      );
    }

    _initialized = true;
    debugPrint('[UniLabBridge] Bridge and Backend initialized successfully.');
  }

  /// Dispose sessions, clear FFI callbacks, and shut down the worker isolate.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _initialized = false;

    final sid = _sessionId;
    _sessionId = null;
    if (sid != null && _mainDestroySession != null) {
      final sidPtr = sid.toNativeUtf8();
      try {
        _mainDestroySession!(sidPtr);
      } catch (e) {
        debugPrint('[UniLabBridge] Error destroying session on dispose: $e');
      } finally {
        malloc.free(sidPtr);
      }
    }

    try {
      _mainSetWorkspaceCallback?.call(
        nullptr.cast<NativeFunction<WorkspaceCallbackNative>>(),
      );
    } catch (_) {}
    try {
      _mainSetEventCallback?.call(
        nullptr.cast<NativeFunction<EventCallbackNative>>(),
      );
    } catch (_) {}

    try {
      _wsCallback?.close();
    } catch (_) {}
    _wsCallback = null;

    try {
      _eventCallback?.close();
    } catch (_) {}
    _eventCallback = null;

    try {
      _workerSendPort?.send({'command': 'shutdown'});
    } catch (_) {}
    _workerSendPort = null;

    try {
      _mainReceivePort.close();
    } catch (_) {}
  }

  static void _onSimEvent(
    Pointer<Utf8> sessionIdPtr,
    Pointer<Utf8> eventTypePtr,
    Pointer<Utf8> dataJsonPtr,
  ) {
    if (sessionIdPtr.address == 0 ||
        eventTypePtr.address == 0 ||
        dataJsonPtr.address == 0) {
      if (sessionIdPtr.address != 0) _unilabFreeString?.call(sessionIdPtr);
      if (eventTypePtr.address != 0) _unilabFreeString?.call(eventTypePtr);
      if (dataJsonPtr.address != 0) _unilabFreeString?.call(dataJsonPtr);
      return;
    }

    String sessionId = '';
    String eventType = '';
    String dataJson = '';
    try {
      sessionId = sessionIdPtr.toDartString();
      eventType = eventTypePtr.toDartString();
      dataJson = dataJsonPtr.toDartString();
    } finally {
      _unilabFreeString?.call(sessionIdPtr);
      _unilabFreeString?.call(eventTypePtr);
      _unilabFreeString?.call(dataJsonPtr);
    }

    try {
      final data = jsonDecode(dataJson);
      _eventController.add({
        'type': 'sim_event',
        'event': eventType,
        'session_id': sessionId,
        'data': data,
      });
    } catch (e) {
      debugPrint('[UniLabBridge] Error parsing sim event: $e');
    }
  }

  static void _onWorkspaceChanged(
    Pointer<Utf8> sessionIdPtr,
    Pointer<Utf8> variablesJsonPtr,
  ) {
    if (sessionIdPtr.address == 0 || variablesJsonPtr.address == 0) {
      if (sessionIdPtr.address != 0) _unilabFreeString?.call(sessionIdPtr);
      if (variablesJsonPtr.address != 0) {
        _unilabFreeString?.call(variablesJsonPtr);
      }
      return;
    }

    String sessionId = '';
    String variablesJson = '';
    try {
      sessionId = sessionIdPtr.toDartString();
      variablesJson = variablesJsonPtr.toDartString();
    } finally {
      _unilabFreeString?.call(sessionIdPtr);
      _unilabFreeString?.call(variablesJsonPtr);
    }

    try {
      final variables = jsonDecode(variablesJson) as Map<String, dynamic>;
      _eventController.add({
        'type': 'event',
        'event': 'workspace_updated',
        'session_id': sessionId,
        'variables': variables,
      });
    } catch (e) {
      debugPrint('[UniLabBridge] Error parsing workspace update: $e');
    }
  }

  /// Create a new session
  Future<String> createSession(String username) async {
    final response = await _sendCommand('create_session', {'username': username});
    final sid = response['session_id']?.toString();
    if (sid == null || sid.isEmpty) {
      throw Exception(response['error'] ?? 'Failed to create session');
    }
    _sessionId = sid;
    return _sessionId!;
  }

  /// Destroy the active session explicitly
  Future<void> destroySession() async {
    final sid = _sessionId;
    if (sid == null) return;
    _sessionId = null;
    if (_mainDestroySession != null) {
      final sidPtr = sid.toNativeUtf8();
      try {
        _mainDestroySession!(sidPtr);
      } finally {
        malloc.free(sidPtr);
      }
    } else {
      await _sendCommand('destroy_session', {'sessionId': sid});
    }
  }

  /// Execute code in the current session
  Future<ExecutionResult> execute(
    String code, {
    String? filename,
    double timeout = 300.0,
  }) async {
    if (_sessionId == null) throw StateError('Session not created');
    final timeoutSeconds = timeout.isFinite && timeout > 0 ? timeout.ceil() : 300;
    final response = await _sendCommand(
      'execute',
      {
        'sessionId': _sessionId,
        'code': code,
        'filename': filename,
        'timeout': timeout,
      },
      timeout: Duration(seconds: timeoutSeconds + 15),
    );
    return ExecutionResult.fromJson(
      response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response as Map),
    );
  }

  /// Get workspace variables
  Future<Map<String, dynamic>> getWorkspace() async {
    if (_sessionId == null) return {};
    final response = await _sendCommand('get_workspace', {'sessionId': _sessionId});
    final vars = response['variables'];
    if (vars is Map<String, dynamic>) return vars;
    if (vars is Map) return Map<String, dynamic>.from(vars);
    return {};
  }

  /// Get autocomplete suggestions
  Future<List<String>> getAutocomplete(String text, {String? fullLine}) async {
    if (_sessionId == null) return [];
    final response = await _sendCommand('get_autocomplete', {
      'sessionId': _sessionId,
      'text': text,
      'line': fullLine ?? text,
    });
    return (response['suggestions'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
  }

  /// List files in the session workspace
  Future<List<Map<String, dynamic>>> listFiles() async {
    if (_sessionId == null) return [];
    final response = await _sendCommand('list_files', {'sessionId': _sessionId});
    return List<Map<String, dynamic>>.from(response['files'] ?? []);
  }

  /// Transpile code to Python
  Future<String> transpile(String code) async {
    final response = await _sendCommand('transpile', {'code': code});
    if (response['success'] == true) {
      return response['python_code']?.toString() ?? '';
    } else {
      throw Exception(response['error'] ?? 'Transpilation failed');
    }
  }

  /// Send an event to the active simulation directly on the main isolate
  /// (non-blocking in Rust so Stop and live sliders work during worker execution).
  Future<void> sendSimEvent(Map<String, dynamic> event) async {
    if (_mainSendSimEvent != null) {
      final evPtr = jsonEncode(event).toNativeUtf8();
      try {
        _mainSendSimEvent!(evPtr);
      } finally {
        malloc.free(evPtr);
      }
      return;
    }
    await _sendCommand('send_sim_event', {'event': jsonEncode(event)});
  }

  /// Immediately cancel any running script or simulation and ensure the worker
  /// isolate is ready to execute the next script without delay.
  Future<void> cancelExecution() async {
    await sendSimEvent({'type': 'STOP'});
    if (_inFlightReplyPorts.isEmpty) return;

    // Wait up to 350ms for Python's async KeyboardInterrupt to return cleanly.
    final deadline = DateTime.now().add(const Duration(milliseconds: 350));
    while (_inFlightReplyPorts.isNotEmpty && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 20));
    }

    // If the worker is still blocked in a native call, release pending callers
    // and recycle the worker isolate so the next script executes immediately.
    if (_inFlightReplyPorts.isNotEmpty) {
      for (final port in _inFlightReplyPorts.toList()) {
        try {
          port.send({
            'success': false,
            'stdout': '',
            'stderr': 'Execution stopped by user.',
            'return_code': 130,
            'execution_time': 0.0,
            'variables': <String, dynamic>{},
            'plots': <dynamic>[],
          });
        } catch (_) {}
      }
      _inFlightReplyPorts.clear();

      try {
        _workerIsolate?.kill(priority: Isolate.immediate);
      } catch (_) {}
      _workerIsolate = null;
      _workerSendPort = null;
      try {
        _mainReceivePort.close();
      } catch (_) {}
      _mainReceivePort = ReceivePort();
      _workerReady = Completer<void>();
      await _startWorker();
      if (_backendPath != null) {
        await _sendCommand(
          'initialize',
          {'backendPath': _backendPath!},
          timeout: const Duration(seconds: 15),
        );
      }
    }
  }

  Future<void> createFile(String filename, String content) async {
    if (_sessionId == null) return;
    await _sendCommand('create_file', {
      'sessionId': _sessionId,
      'filename': filename,
      'content': content,
    });
  }

  Future<Map<String, dynamic>> getInfo() async {
    return {
      'version': '0.1.0 (FFI-Worker)',
      'name': 'UniLab Core FFI Worker',
      'status': _initialized ? 'active' : 'uninitialized',
      'capabilities': ['execution', 'workspace', 'files', 'autocomplete'],
    };
  }

  static Future<String> findBackendPath() async {
    final locations = <String>[];

    final envPath = Platform.environment['UNILAB_BACKEND_PATH'];
    if (envPath != null && envPath.isNotEmpty) {
      locations.add(envPath);
    }

    final cwd = Directory.current.path;
    final parentCwd = p.dirname(cwd);
    locations.addAll([
      cwd,
      parentCwd,
    ]);

    try {
      if (Platform.resolvedExecutable.isNotEmpty) {
        final exePath =
            File(Platform.resolvedExecutable).resolveSymbolicLinksSync();
        final exeDir = Directory(exePath).parent.path;
        locations.addAll([
          p.dirname(exeDir),
          p.join(exeDir, 'backend'),
          p.join(exeDir, 'data', 'flutter_assets', 'assets', 'backend'),
          p.join(
            exeDir,
            '..',
            'Resources',
            'flutter_assets',
            'assets',
            'backend',
          ),
          p.normalize(p.join(exeDir, '..')),
          p.normalize(p.join(exeDir, '..', '..', '..')),
        ]);
      }
    } catch (_) {}

    locations.add(p.join(cwd, 'assets', 'backend'));

    for (final candidate in locations) {
      // Case 1: candidate contains a 'backend/' subdirectory
      final subBackendDir = p.join(candidate, 'backend');
      if (await Directory(subBackendDir).exists()) {
        return candidate;
      }
      // Case 2: candidate itself is the 'backend' directory (e.g., UNILAB_BACKEND_PATH points directly to backend/)
      if (p.basename(candidate) == 'backend' &&
          await Directory(candidate).exists()) {
        return p.dirname(candidate);
      }
    }

    throw StateError('Cannot find backend directory. Searched in: $locations');
  }

  static Future<String> findSamplesPath() async {
    final locations = <String>[];

    try {
      if (Platform.resolvedExecutable.isNotEmpty) {
        final exePath =
            File(Platform.resolvedExecutable).resolveSymbolicLinksSync();
        final exeDir = Directory(exePath).parent.path;
        locations.addAll([
          p.join(exeDir, 'sample'),
          p.join(p.dirname(exeDir), 'sample'),
          p.join(exeDir, 'data', 'flutter_assets', 'assets', 'samples'),
          p.join(
            exeDir,
            '..',
            'Resources',
            'flutter_assets',
            'assets',
            'samples',
          ),
        ]);
      }
    } catch (_) {}

    final cwd = Directory.current.path;
    final parentCwd = p.dirname(cwd);
    locations.addAll([
      p.join(cwd, 'sample'),
      p.join(parentCwd, 'sample'),
      p.join(cwd, 'assets', 'samples'),
    ]);

    for (final path in locations) {
      if (await Directory(path).exists()) return path;
    }
    return p.join(parentCwd, 'sample');
  }

  // --- Worker Isolate Entry Point ---
  static void _workerEntry(SendPort mainSendPort) {
    final workerReceivePort = ReceivePort();
    mainSendPort.send(workerReceivePort.sendPort);

    late DynamicLibrary lib;
    late UnilabInit unilabInit;
    late UnilabCreateSession unilabCreateSession;
    late UnilabDestroySession unilabDestroySession;
    late UnilabExecute unilabExecute;
    late UnilabExecuteWithFilename unilabExecuteWithFilename;
    late UnilabGetWorkspace unilabGetWorkspace;
    late UnilabGetAutocomplete unilabGetAutocomplete;
    late UnilabListFiles unilabListFiles;
    late UnilabTranspile unilabTranspile;
    late UnilabCreateFile unilabCreateFile;
    late UnilabSendSimEvent unilabSendSimEvent;
    late UnilabPing unilabPing;
    late UnilabFreeString unilabFreeString;

    Map<String, dynamic> decodeAndFree(Pointer<Utf8> resPtr) {
      if (resPtr.address == 0) {
        return {'error': 'Native FFI returned null pointer'};
      }
      try {
        final str = resPtr.toDartString();
        final decoded = jsonDecode(str);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
        return {'data': decoded};
      } finally {
        unilabFreeString(resPtr);
      }
    }

    workerReceivePort.listen((message) {
      if (message is! Map) return;
      final command = message['command'];
      final params = message['params'] ?? const {};
      final SendPort? replyPort = message['replyPort'] as SendPort?;

      try {
        switch (command) {
          case 'initialize':
            final backendPath = params['backendPath'] as String;
            lib = _loadLibraryHandle(backendPath);

            unilabInit =
                lib.lookupFunction<UnilabInitNative, UnilabInit>('unilab_init');
            unilabCreateSession = lib.lookupFunction<
                UnilabCreateSessionNative,
                UnilabCreateSession>('unilab_create_session');
            unilabDestroySession = lib.lookupFunction<
                UnilabDestroySessionNative,
                UnilabDestroySession>('unilab_destroy_session');
            unilabExecute = lib.lookupFunction<UnilabExecuteNative, UnilabExecute>(
              'unilab_execute',
            );
            unilabExecuteWithFilename = lib.lookupFunction<
                UnilabExecuteWithFilenameNative,
                UnilabExecuteWithFilename>('unilab_execute_with_filename');
            unilabGetWorkspace = lib.lookupFunction<
                UnilabGetWorkspaceNative,
                UnilabGetWorkspace>('unilab_get_workspace');
            unilabGetAutocomplete = lib.lookupFunction<
                UnilabGetAutocompleteNative,
                UnilabGetAutocomplete>('unilab_get_autocomplete');
            unilabListFiles =
                lib.lookupFunction<UnilabListFilesNative, UnilabListFiles>(
                  'unilab_list_files',
                );
            unilabTranspile =
                lib.lookupFunction<UnilabTranspileNative, UnilabTranspile>(
                  'unilab_transpile',
                );
            unilabCreateFile =
                lib.lookupFunction<UnilabCreateFileNative, UnilabCreateFile>(
                  'unilab_create_file',
                );
            unilabSendSimEvent = lib.lookupFunction<
                UnilabSendSimEventNative,
                UnilabSendSimEvent>('unilab_send_sim_event');
            unilabPing =
                lib.lookupFunction<UnilabPingNative, UnilabPing>('unilab_ping');
            unilabFreeString = lib.lookupFunction<
                UnilabFreeStringNative,
                UnilabFreeString>('unilab_free_string');

            final pathPtr = backendPath.toNativeUtf8();
            int initRc;
            try {
              initRc = unilabInit(pathPtr);
            } finally {
              malloc.free(pathPtr);
            }

            if (initRc != 0) {
              replyPort?.send({
                'success': false,
                'error': 'Failed to initialize Python/Rust backend (code $initRc)',
              });
            } else {
              replyPort?.send({'success': true});
            }
            break;

          case 'ping':
            final res = unilabPing();
            replyPort?.send({'success': res == 0});
            break;

          case 'create_session':
            final userPtr = (params['username'] as String).toNativeUtf8();
            Pointer<Utf8> resPtr = nullptr.cast<Utf8>();
            try {
              resPtr = unilabCreateSession(userPtr);
              replyPort?.send(decodeAndFree(resPtr));
              resPtr = nullptr.cast<Utf8>();
            } finally {
              malloc.free(userPtr);
              if (resPtr.address != 0) unilabFreeString(resPtr);
            }
            break;

          case 'destroy_session':
            final sidPtr = (params['sessionId'] as String).toNativeUtf8();
            try {
              final rc = unilabDestroySession(sidPtr);
              replyPort?.send({'success': rc == 0});
            } finally {
              malloc.free(sidPtr);
            }
            break;

          case 'execute':
            final sidPtr = (params['sessionId'] as String).toNativeUtf8();
            final codePtr = (params['code'] as String).toNativeUtf8();
            final filename = params['filename'] as String?;
            final timeout = (params['timeout'] as num?)?.toDouble() ?? 300.0;
            Pointer<Utf8>? filePtr;
            Pointer<Utf8> resPtr = nullptr.cast<Utf8>();

            try {
              if (filename != null) {
                filePtr = filename.toNativeUtf8();
                resPtr = unilabExecuteWithFilename(
                  sidPtr,
                  codePtr,
                  filePtr,
                  timeout,
                );
              } else {
                resPtr = unilabExecute(sidPtr, codePtr, timeout);
              }
              replyPort?.send(decodeAndFree(resPtr));
              resPtr = nullptr.cast<Utf8>();
            } finally {
              if (filePtr != null) malloc.free(filePtr);
              malloc.free(sidPtr);
              malloc.free(codePtr);
              if (resPtr.address != 0) unilabFreeString(resPtr);
            }
            break;

          case 'get_workspace':
            final sidPtr = (params['sessionId'] as String).toNativeUtf8();
            Pointer<Utf8> resPtr = nullptr.cast<Utf8>();
            try {
              resPtr = unilabGetWorkspace(sidPtr);
              replyPort?.send(decodeAndFree(resPtr));
              resPtr = nullptr.cast<Utf8>();
            } finally {
              malloc.free(sidPtr);
              if (resPtr.address != 0) unilabFreeString(resPtr);
            }
            break;

          case 'get_autocomplete':
            final sidPtr = (params['sessionId'] as String).toNativeUtf8();
            final textPtr = (params['text'] as String).toNativeUtf8();
            final linePtr =
                (params['line'] as String? ?? params['text'] as String)
                    .toNativeUtf8();
            Pointer<Utf8> resPtr = nullptr.cast<Utf8>();
            try {
              resPtr = unilabGetAutocomplete(sidPtr, textPtr, linePtr);
              replyPort?.send(decodeAndFree(resPtr));
              resPtr = nullptr.cast<Utf8>();
            } finally {
              malloc.free(sidPtr);
              malloc.free(textPtr);
              malloc.free(linePtr);
              if (resPtr.address != 0) unilabFreeString(resPtr);
            }
            break;

          case 'list_files':
            final sidPtr = (params['sessionId'] as String).toNativeUtf8();
            Pointer<Utf8> resPtr = nullptr.cast<Utf8>();
            try {
              resPtr = unilabListFiles(sidPtr);
              replyPort?.send(decodeAndFree(resPtr));
              resPtr = nullptr.cast<Utf8>();
            } finally {
              malloc.free(sidPtr);
              if (resPtr.address != 0) unilabFreeString(resPtr);
            }
            break;

          case 'transpile':
            final codePtr = (params['code'] as String).toNativeUtf8();
            Pointer<Utf8> resPtr = nullptr.cast<Utf8>();
            try {
              resPtr = unilabTranspile(codePtr);
              replyPort?.send(decodeAndFree(resPtr));
              resPtr = nullptr.cast<Utf8>();
            } finally {
              malloc.free(codePtr);
              if (resPtr.address != 0) unilabFreeString(resPtr);
            }
            break;

          case 'send_sim_event':
            final evPtr = (params['event'] as String).toNativeUtf8();
            try {
              unilabSendSimEvent(evPtr);
              replyPort?.send({'success': true});
            } finally {
              malloc.free(evPtr);
            }
            break;

          case 'create_file':
            final sidPtr = (params['sessionId'] as String).toNativeUtf8();
            final namePtr = (params['filename'] as String).toNativeUtf8();
            final contPtr = (params['content'] as String).toNativeUtf8();
            Pointer<Utf8> resPtr = nullptr.cast<Utf8>();
            try {
              resPtr = unilabCreateFile(sidPtr, namePtr, contPtr);
              replyPort?.send(decodeAndFree(resPtr));
              resPtr = nullptr.cast<Utf8>();
            } finally {
              malloc.free(sidPtr);
              malloc.free(namePtr);
              malloc.free(contPtr);
              if (resPtr.address != 0) unilabFreeString(resPtr);
            }
            break;

          case 'shutdown':
            workerReceivePort.close();
            Isolate.exit();
        }
      } catch (e) {
        replyPort?.send({'error': e.toString()});
      }
    });
  }
}
