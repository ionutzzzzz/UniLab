import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import '../models/models.dart';

// FFI Signatures
typedef UnilabInitNative = Int32 Function(Pointer<Utf8> backendPath);
typedef UnilabInit = int Function(Pointer<Utf8> backendPath);

typedef UnilabCreateSessionNative = Pointer<Utf8> Function(Pointer<Utf8> username);
typedef UnilabCreateSession = Pointer<Utf8> Function(Pointer<Utf8> username);

typedef UnilabExecuteNative = Pointer<Utf8> Function(Pointer<Utf8> sessionId, Pointer<Utf8> code);
typedef UnilabExecute = Pointer<Utf8> Function(Pointer<Utf8> sessionId, Pointer<Utf8> code);

typedef UnilabGetWorkspaceNative = Pointer<Utf8> Function(Pointer<Utf8> sessionId);
typedef UnilabGetWorkspace = Pointer<Utf8> Function(Pointer<Utf8> sessionId);

typedef UnilabGetAutocompleteNative = Pointer<Utf8> Function(Pointer<Utf8> sessionId, Pointer<Utf8> text);
typedef UnilabGetAutocomplete = Pointer<Utf8> Function(Pointer<Utf8> sessionId, Pointer<Utf8> text);

typedef UnilabListFilesNative = Pointer<Utf8> Function(Pointer<Utf8> sessionId);
typedef UnilabListFiles = Pointer<Utf8> Function(Pointer<Utf8> sessionId);

typedef UnilabCreateFileNative = Pointer<Utf8> Function(Pointer<Utf8> sessionId, Pointer<Utf8> filename, Pointer<Utf8> content);
typedef UnilabCreateFile = Pointer<Utf8> Function(Pointer<Utf8> sessionId, Pointer<Utf8> filename, Pointer<Utf8> content);

typedef UnilabFreeStringNative = Void Function(Pointer<Utf8> ptr);
typedef UnilabFreeString = void Function(Pointer<Utf8> ptr);

typedef WorkspaceCallbackNative = Void Function(Pointer<Utf8> sessionId, Pointer<Utf8> variablesJson);
typedef UnilabSetWorkspaceCallbackNative = Void Function(Pointer<NativeFunction<WorkspaceCallbackNative>> callback);
typedef UnilabSetWorkspaceCallback = void Function(Pointer<NativeFunction<WorkspaceCallbackNative>> callback);

class UniLabBridge {
  static UniLabBridge? _instance;
  static final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  
  String? _sessionId;
  bool _initialized = false;
  
  // Keep callback alive
  NativeCallable<WorkspaceCallbackNative>? _wsCallback;
  
  // Isolate communication
  SendPort? _workerSendPort;
  final ReceivePort _mainReceivePort = ReceivePort();
  final Completer<void> _workerReady = Completer<void>();

  UniLabBridge._() {
    _startWorker();
  }

  static UniLabBridge get instance {
    _instance ??= UniLabBridge._();
    return _instance!;
  }

  static void resetInstance() {
    _instance?._initialized = false;
    _instance?._workerSendPort?.send({'command': 'shutdown'});
    _instance = null;
  }

  String? get sessionId => _sessionId;
  bool get initialized => _initialized;
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  Future<void> _startWorker() async {
    await Isolate.spawn(_workerEntry, _mainReceivePort.sendPort);
    
    _mainReceivePort.listen((message) {
      if (message is SendPort) {
        _workerSendPort = message;
        _workerReady.complete();
      } else if (message is Map<String, dynamic>) {
        if (message['type'] == 'event') {
          _eventController.add(message);
        }
      }
    });
  }

  Future<dynamic> _sendCommand(String command, Map<String, dynamic> params) async {
    await _workerReady.future;
    final responsePort = ReceivePort();
    _workerSendPort!.send({
      'command': command,
      'params': params,
      'replyPort': responsePort.sendPort,
    });
    
    try {
      final result = await responsePort.first.timeout(const Duration(seconds: 15));
      if (result is Map && result['error'] != null) {
        throw Exception(result['error']);
      }
      return result;
    } on TimeoutException {
      throw Exception('Command $command timed out');
    } finally {
      responsePort.close();
    }
  }

  /// Initialize the bridge.
  Future<void> initialize(String backendPath) async {
    if (_initialized) return;

    // Create the workspace callback in the main isolate
    _wsCallback = NativeCallable<WorkspaceCallbackNative>.listener(_onWorkspaceChanged);
    
    await _sendCommand('initialize', {
      'backendPath': backendPath,
      'callbackPtr': _wsCallback!.nativeFunction.address,
    });

    _initialized = true;
    debugPrint('[UniLabBridge] FFI Bridge Initialized successfully (via Worker Isolate)');
  }

  static void _onWorkspaceChanged(Pointer<Utf8> sessionIdPtr, Pointer<Utf8> variablesJsonPtr) {
    final sessionId = sessionIdPtr.toDartString();
    final variablesJson = variablesJsonPtr.toDartString();
    
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
    _sessionId = response['session_id'];
    return _sessionId!;
  }

  /// Execute code in the current session
  Future<ExecutionResult> execute(String code) async {
    if (_sessionId == null) throw StateError('Session not created');
    final response = await _sendCommand('execute', {
      'sessionId': _sessionId,
      'code': code,
    });
    return ExecutionResult.fromJson(response);
  }

  /// Get workspace variables
  Future<Map<String, dynamic>> getWorkspace() async {
    if (_sessionId == null) return {};
    final response = await _sendCommand('get_workspace', {'sessionId': _sessionId});
    return response['variables'] ?? {};
  }

  /// Get autocomplete suggestions
  Future<List<String>> getAutocomplete(String text) async {
    if (_sessionId == null) return [];
    final response = await _sendCommand('get_autocomplete', {
      'sessionId': _sessionId,
      'text': text,
    });
    return List<String>.from(response['suggestions'] ?? []);
  }

  /// List files in the session workspace
  Future<List<Map<String, dynamic>>> listFiles() async {
    if (_sessionId == null) return [];
    final response = await _sendCommand('list_files', {'sessionId': _sessionId});
    return List<Map<String, dynamic>>.from(response['files'] ?? []);
  }

  /// Create or overwrite a file
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
      'status': 'active',
      'capabilities': ['execution', 'workspace', 'files', 'autocomplete']
    };
  }

  // Find the backend path
  static Future<String> findBackendPath() async {
    try {
      final exe = File(Platform.resolvedExecutable);
      final backendPath = p.join(exe.parent.path, '..', '..', '..', 'backend');
      if (await Directory(backendPath).exists()) return backendPath;
    } catch (_) {}
    
    final envPath = Platform.environment['UNILAB_BACKEND_PATH'];
    if (envPath != null && await Directory(envPath).exists()) return envPath;
    
    final commonPaths = [
      '/home/john/Documents/GitHub/UniLab/backend', 
      p.join(Directory.current.path, 'backend')
    ];
    for (final path in commonPaths) {
      if (await Directory(path).exists()) return path;
    }
    throw StateError('Cannot find backend directory.');
  }

  // --- Worker Isolate Entry Point ---
  static void _workerEntry(SendPort mainSendPort) {
    final workerReceivePort = ReceivePort();
    mainSendPort.send(workerReceivePort.sendPort);

    late DynamicLibrary lib;
    late UnilabInit unilabInit;
    late UnilabCreateSession unilabCreateSession;
    late UnilabExecute unilabExecute;
    late UnilabGetWorkspace unilabGetWorkspace;
    late UnilabGetAutocomplete unilabGetAutocomplete;
    late UnilabListFiles unilabListFiles;
    late UnilabCreateFile unilabCreateFile;
    late UnilabFreeString unilabFreeString;
    late UnilabSetWorkspaceCallback unilabSetWorkspaceCallback;

    workerReceivePort.listen((message) {
      if (message is! Map) return;
      final command = message['command'];
      final params = message['params'] ?? {};
      final SendPort? replyPort = message['replyPort'];

      try {
        switch (command) {
          case 'initialize':
            final backendPath = params['backendPath'] as String;
            final callbackAddr = params['callbackPtr'] as int;

            // Load library
            String libName = Platform.isLinux ? 'libunilab_core.so' : (Platform.isMacOS ? 'libunilab_core.dylib' : 'unilab_core.dll');
            final locations = [
              p.join(backendPath, 'target', 'release', libName),
              p.join(backendPath, 'target', 'debug', libName),
              libName,
              p.join(Directory.current.path, libName),
            ];
            
            bool loaded = false;
            for (final loc in locations) {
              try {
                lib = DynamicLibrary.open(loc);
                loaded = true;
                break;
              } catch (_) {}
            }
            if (!loaded) throw Exception('Could not load library $libName');

            unilabInit = lib.lookupFunction<UnilabInitNative, UnilabInit>('unilab_init');
            unilabCreateSession = lib.lookupFunction<UnilabCreateSessionNative, UnilabCreateSession>('unilab_create_session');
            unilabExecute = lib.lookupFunction<UnilabExecuteNative, UnilabExecute>('unilab_execute');
            unilabGetWorkspace = lib.lookupFunction<UnilabGetWorkspaceNative, UnilabGetWorkspace>('unilab_get_workspace');
            unilabGetAutocomplete = lib.lookupFunction<UnilabGetAutocompleteNative, UnilabGetAutocomplete>('unilab_get_autocomplete');
            unilabListFiles = lib.lookupFunction<UnilabListFilesNative, UnilabListFiles>('unilab_list_files');
            unilabCreateFile = lib.lookupFunction<UnilabCreateFileNative, UnilabCreateFile>('unilab_create_file');
            unilabFreeString = lib.lookupFunction<UnilabFreeStringNative, UnilabFreeString>('unilab_free_string');
            unilabSetWorkspaceCallback = lib.lookupFunction<UnilabSetWorkspaceCallbackNative, UnilabSetWorkspaceCallback>('unilab_set_workspace_callback');

            final pathPtr = backendPath.toNativeUtf8();
            unilabInit(pathPtr);
            malloc.free(pathPtr);

            // Register callback
            final cbPtr = Pointer<NativeFunction<WorkspaceCallbackNative>>.fromAddress(callbackAddr);
            unilabSetWorkspaceCallback(cbPtr);
            
            replyPort?.send({'success': true});
            break;

          case 'create_session':
            final userPtr = (params['username'] as String).toNativeUtf8();
            final resPtr = unilabCreateSession(userPtr);
            malloc.free(userPtr);
            final res = jsonDecode(resPtr.toDartString());
            unilabFreeString(resPtr);
            replyPort?.send(res);
            break;

          case 'execute':
            final sidPtr = (params['sessionId'] as String).toNativeUtf8();
            final codePtr = (params['code'] as String).toNativeUtf8();
            final resPtr = unilabExecute(sidPtr, codePtr);
            malloc.free(sidPtr);
            malloc.free(codePtr);
            final res = jsonDecode(resPtr.toDartString());
            unilabFreeString(resPtr);
            replyPort?.send(res);
            break;

          case 'get_workspace':
            final sidPtr = (params['sessionId'] as String).toNativeUtf8();
            final resPtr = unilabGetWorkspace(sidPtr);
            malloc.free(sidPtr);
            final res = jsonDecode(resPtr.toDartString());
            unilabFreeString(resPtr);
            replyPort?.send(res);
            break;

          case 'get_autocomplete':
            final sidPtr = (params['sessionId'] as String).toNativeUtf8();
            final textPtr = (params['text'] as String).toNativeUtf8();
            final resPtr = unilabGetAutocomplete(sidPtr, textPtr);
            malloc.free(sidPtr);
            malloc.free(textPtr);
            final res = jsonDecode(resPtr.toDartString());
            unilabFreeString(resPtr);
            replyPort?.send(res);
            break;

          case 'list_files':
            final sidPtr = (params['sessionId'] as String).toNativeUtf8();
            final resPtr = unilabListFiles(sidPtr);
            malloc.free(sidPtr);
            final res = jsonDecode(resPtr.toDartString());
            unilabFreeString(resPtr);
            replyPort?.send(res);
            break;

          case 'create_file':
            final sidPtr = (params['sessionId'] as String).toNativeUtf8();
            final namePtr = (params['filename'] as String).toNativeUtf8();
            final contPtr = (params['content'] as String).toNativeUtf8();
            final resPtr = unilabCreateFile(sidPtr, namePtr, contPtr);
            malloc.free(sidPtr);
            malloc.free(namePtr);
            malloc.free(contPtr);
            final res = jsonDecode(resPtr.toDartString());
            unilabFreeString(resPtr);
            replyPort?.send(res);
            break;

          case 'shutdown':
            Isolate.exit();
        }
      } catch (e) {
        replyPort?.send({'error': e.toString()});
      }
    });
  }
}