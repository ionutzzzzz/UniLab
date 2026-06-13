import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/editor_models.dart';
import 'dart:js_interop';

@JS('rust_run_code_session')
external JSString rustRunCodeSessionJS(JSString sessionId, JSString code);

@JS('rust_create_session')
external JSBoolean rustCreateSessionJS(JSString sessionId);

// Helper to check if JS functions are defined
@JS('Object.hasOwnProperty')
external bool _jsHasProperty(JSObject obj, JSString prop);

@JS('window')
external JSObject get _window;

class UniLabBridge {
  static UniLabBridge? _instance;
  static final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  String? _sessionId;
  bool _initialized = false;

  UniLabBridge._();

  static UniLabBridge get instance {
    _instance ??= UniLabBridge._();
    return _instance!;
  }

  static void resetInstance() {
    _instance = null;
  }

  String? get sessionId => _sessionId;
  bool get initialized => _initialized;
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  Future<void> initialize(String backendPath) async {
    if (_initialized) return;

    // Wait for Wasm module to be initialized and functions to be exposed in index.html
    int attempts = 0;
    while (attempts < 100) { // Timeout after ~10 seconds
      try {
        // We use a safe check to see if the function exists on window
        final hasFunc = _jsHasProperty(_window, 'rust_create_session'.toJS);
        if (hasFunc) {
          _initialized = true;
          debugPrint('[UniLabBridge] Web Wasm Bridge Initialized');
          return;
        }
      } catch (_) {}
      
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    throw Exception('UniLab Rust Engine (Wasm) failed to load within timeout.');
  }

  Future<String> createSession(String username) async {
    if (!_initialized) await initialize('');
    
    _sessionId = 'web-session-${DateTime.now().millisecondsSinceEpoch}';
    try {
      rustCreateSessionJS(_sessionId!.toJS);
    } catch (e) {
      debugPrint('[UniLabBridge] Wasm Error createSession: $e');
      throw Exception('Failed to create Rust session in Wasm: $e');
    }
    return _sessionId!;
  }

  Future<ExecutionResult> execute(String code, {String? filename, double timeout = 300.0}) async {
    if (_sessionId == null) throw StateError('Session not created');
    
    try {
      final jsRes = rustRunCodeSessionJS(_sessionId!.toJS, code.toJS);
      final jsonRes = jsRes.toDart;
      final data = jsonDecode(jsonRes);
      
      return ExecutionResult(
        success: data['success'] ?? false,
        stdout: data['output'] ?? '',
        stderr: data['error'] ?? '',
        variables: {}, // TODO: Extract variables
        plots: (data['plots'] as List? ?? []).map<PlotData>((p) => PlotData.fromJson(p as Map<String, dynamic>)).toList(),
        extra: {},
      );
    } catch (e) {
      return ExecutionResult(
        success: false,
        stdout: '',
        stderr: 'Wasm Error: $e',
        variables: {},
        plots: [],
        extra: {},
      );
    }
  }

  Future<Map<String, dynamic>> getWorkspace() async {
    return {};
  }

  Future<List<String>> getAutocomplete(String text, {String? fullLine}) async {
    return [];
  }

  Future<List<Map<String, dynamic>>> listFiles() async {
    return [];
  }

  Future<String> transpile(String code) async {
    return '# Transpilation not supported on web yet';
  }

  Future<void> sendSimEvent(Map<String, dynamic> event) async {
    debugPrint('[UniLabBridge] Web Sim Event: $event');
  }

  Future<void> createFile(String filename, String content) async {
    debugPrint('[UniLabBridge] Web Create File: $filename');
  }

  Future<Map<String, dynamic>> getInfo() async {
    return {
      'version': '0.1.0 (Wasm)',
      'name': 'UniLab Web Wasm',
      'status': 'active',
      'capabilities': ['execution']
    };
  }

  static Future<String> findBackendPath() async {
    return '/web-virtual-root';
  }
}
