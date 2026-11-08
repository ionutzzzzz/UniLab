import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/editor_models.dart';
import '../utils/backend_client.dart';

@JS('rust_run_code_session')
external JSString rustRunCodeSessionJS(JSString sessionId, JSString code);

@JS('rust_create_session')
external JSBoolean rustCreateSessionJS(JSString sessionId);

class UniLabBridge {
  static UniLabBridge? _instance;
  static final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  late final BackendClient _client;
  String? _configuredKernelAddress;
  int _connectionTimeoutSecs = 10;

  String? _sessionId;
  bool _initialized = false;
  bool _useWasmFallback = false;

  UniLabBridge._() {
    _client = BackendClient(baseUrl: _resolveDefaultBaseUrl());
  }

  static String _resolveDefaultBaseUrl() {
    final base = Uri.base;
    if (base.scheme == 'http' || base.scheme == 'https') {
      // When served from the FastAPI/Docker host (e.g., port 8000 or reverse proxy),
      // prefer same-origin; when running from a random Flutter dev port, try localhost:8000.
      if (base.port == 8000 || base.port == 80 || base.port == 443) {
        return base.origin;
      }
    }
    return 'http://localhost:8000';
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

  void configure({String? kernelAddress, int? connectionTimeout}) {
    if (kernelAddress != null && kernelAddress.trim().isNotEmpty) {
      _configuredKernelAddress = kernelAddress.trim();
    }
    if (connectionTimeout != null && connectionTimeout > 0) {
      _connectionTimeoutSecs = connectionTimeout;
    }
    _client.updateConfig(
      url: _configuredKernelAddress,
      timeout: Duration(seconds: _connectionTimeoutSecs),
    );
  }

  bool _hasWasmExports() {
    try {
      return globalContext.has('rust_create_session') &&
          globalContext.has('rust_run_code_session');
    } catch (_) {
      return false;
    }
  }

  Future<void> initialize([String? backendPath]) async {
    if (_initialized) return;

    // Candidate HTTP API origins in priority order
    final candidates = <String>[
      if (_configuredKernelAddress != null &&
          _configuredKernelAddress!.isNotEmpty)
        _configuredKernelAddress!,
      if (Uri.base.scheme == 'http' || Uri.base.scheme == 'https')
        Uri.base.origin,
      'http://localhost:8000',
    ];

    for (final origin in candidates.toSet()) {
      try {
        _client.updateConfig(
          url: origin,
          timeout: Duration(seconds: _connectionTimeoutSecs),
        );
        if (await _client.checkHealth()) {
          _useWasmFallback = false;
          _initialized = true;
          debugPrint('[UniLabBridge] Web HTTP Bridge connected to $origin');
          return;
        }
      } catch (_) {}
    }

    // Optional Wasm fallback when embedded in standalone Wasm page
    if (_hasWasmExports()) {
      _useWasmFallback = true;
      _initialized = true;
      debugPrint('[UniLabBridge] Web Wasm Bridge Initialized');
      return;
    }

    throw Exception(
      'Could not connect to UniLab Web Backend (${_client.baseUrl}/api/v1/health).',
    );
  }

  Future<void> dispose() async {
    final sid = _sessionId;
    _sessionId = null;
    _initialized = false;
    if (!_useWasmFallback && sid != null) {
      await _client.destroySession(sid);
    }
  }

  Future<String> createSession(String username) async {
    if (!_initialized) await initialize();

    if (_useWasmFallback) {
      _sessionId = 'web-session-${DateTime.now().millisecondsSinceEpoch}';
      try {
        rustCreateSessionJS(_sessionId!.toJS);
      } catch (e) {
        throw Exception('Failed to create Rust session in Wasm: $e');
      }
      return _sessionId!;
    }

    _sessionId = await _client.createSession(username: username);
    return _sessionId!;
  }

  Future<ExecutionResult> execute(
    String code, {
    String? filename,
    double timeout = 300.0,
  }) async {
    if (_sessionId == null) throw StateError('Session not created');

    if (_useWasmFallback) {
      try {
        final jsRes = rustRunCodeSessionJS(_sessionId!.toJS, code.toJS);
        final data = jsonDecode(jsRes.toDart) as Map<String, dynamic>;
        return ExecutionResult(
          success: data['success'] == true,
          stdout: data['output']?.toString() ?? data['stdout']?.toString() ?? '',
          stderr: data['error']?.toString() ?? data['stderr']?.toString() ?? '',
          variables: (data['variables'] is Map)
              ? Map<String, dynamic>.from(data['variables'] as Map)
              : {},
          plots: (data['plots'] as List? ?? const [])
              .whereType<Map>()
              .map<PlotData>(
                (p) => PlotData.fromJson(Map<String, dynamic>.from(p)),
              )
              .toList(),
          extra: const {},
        );
      } catch (e) {
        return ExecutionResult(
          success: false,
          stdout: '',
          stderr: 'Wasm Error: $e',
          variables: const {},
          plots: const [],
          extra: const {},
        );
      }
    }

    final result = await _client.runCode(
      code,
      filename: filename,
      timeout: timeout,
    );
    if (result.variables.isNotEmpty) {
      _eventController.add({
        'type': 'event',
        'event': 'workspace_updated',
        'session_id': _sessionId,
        'variables': result.variables,
      });
    }
    return result;
  }

  Future<Map<String, dynamic>> getWorkspace() async {
    if (_sessionId == null || _useWasmFallback) return {};
    return _client.getWorkspace();
  }

  Future<List<String>> getAutocomplete(String text, {String? fullLine}) async {
    if (_sessionId == null || _useWasmFallback) return [];
    return _client.getAutocomplete(text, fullLine: fullLine);
  }

  Future<List<Map<String, dynamic>>> listFiles() async {
    if (_sessionId == null || _useWasmFallback) return [];
    return _client.listFiles();
  }

  Future<String> transpile(String code) async {
    if (_useWasmFallback) {
      return '# Transpilation requires HTTP backend connection';
    }
    return _client.transpile(code);
  }

  Future<void> sendSimEvent(Map<String, dynamic> event) async {
    if (_sessionId == null || _useWasmFallback) return;
    await _client.sendSimEvent(event);
  }

  Future<void> cancelExecution() async {
    await sendSimEvent({'type': 'STOP'});
  }

  Future<void> createFile(String filename, String content) async {
    if (_sessionId == null || _useWasmFallback) return;
    await _client.createFile(filename, content);
  }

  Future<Map<String, dynamic>> getInfo() async {
    return {
      'version': _useWasmFallback ? '0.1.0 (Wasm)' : '0.1.0 (Web HTTP)',
      'name': _useWasmFallback ? 'UniLab Web Wasm' : 'UniLab Web Client',
      'status': _initialized ? 'active' : 'uninitialized',
      'capabilities': _useWasmFallback
          ? ['execution']
          : ['execution', 'workspace', 'autocomplete', 'sim_event'],
    };
  }

  static Future<String> findBackendPath() async {
    return '/web-virtual-root';
  }

  static Future<String> findSamplesPath() async {
    return 'assets/samples';
  }
}
