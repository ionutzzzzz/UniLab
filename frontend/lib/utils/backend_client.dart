import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class BackendClient {
  String baseUrl;
  String? sessionId;
  Duration connectionTimeout;

  BackendClient({
    this.baseUrl = 'http://localhost:8000',
    this.connectionTimeout = const Duration(seconds: 10),
  }) {
    baseUrl = _normalizeBaseUrl(baseUrl);
  }

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  void updateConfig({String? url, Duration? timeout}) {
    if (url != null && url.trim().isNotEmpty) {
      baseUrl = _normalizeBaseUrl(url);
    }
    if (timeout != null) {
      connectionTimeout = timeout;
    }
  }

  Future<bool> checkHealth() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/v1/health'))
        .timeout(connectionTimeout);
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<String> createSession({String username = 'gui_user'}) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/sessions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'engine': 'transpiler',
          }),
        )
        .timeout(connectionTimeout);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final sid = data['session_id']?.toString();
      if (sid == null || sid.isEmpty) {
        throw Exception('Backend returned empty session_id');
      }
      sessionId = sid;
      return sid;
    }
    throw Exception('Failed to create session (${response.statusCode}): ${response.body}');
  }

  Future<void> destroySession([String? id]) async {
    final targetId = id ?? sessionId;
    if (targetId == null) return;
    if (targetId == sessionId) sessionId = null;
    try {
      await http
          .delete(Uri.parse('$baseUrl/api/v1/sessions/$targetId'))
          .timeout(connectionTimeout);
    } catch (_) {}
  }

  Future<ExecutionResult> runCode(
    String code, {
    String? filename,
    double timeout = 300.0,
  }) async {
    if (sessionId == null) {
      await createSession();
    }

    final timeoutSecs = timeout.isFinite && timeout > 0 ? timeout.ceil() : 300;
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/sessions/$sessionId/execute'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'code': code,
            'timeout': timeout,
            if (filename != null) 'filename': filename,
          }),
        )
        .timeout(Duration(seconds: timeoutSecs + 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      return ExecutionResult.fromJson(
        decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded as Map),
      );
    }
    throw Exception('Failed to run code (${response.statusCode}): ${response.body}');
  }

  Future<Map<String, dynamic>> getWorkspace() async {
    if (sessionId == null) return {};
    final response = await http
        .get(Uri.parse('$baseUrl/api/v1/sessions/$sessionId/workspace'))
        .timeout(connectionTimeout);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['variables'] is Map) {
          return Map<String, dynamic>.from(decoded['variables'] as Map);
        }
        return decoded;
      }
    }
    return {};
  }

  Future<List<String>> getAutocomplete(String text, {String? fullLine}) async {
    if (sessionId == null) return [];
    final line = fullLine ?? text;
    var response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/sessions/$sessionId/autocomplete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text, 'line': line}),
        )
        .timeout(connectionTimeout);

    if (response.statusCode == 405) {
      final uri = Uri.parse('$baseUrl/api/v1/sessions/$sessionId/autocomplete')
          .replace(queryParameters: {'text': text, 'line': line});
      response = await http.get(uri).timeout(connectionTimeout);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['suggestions'] is List) {
        return (decoded['suggestions'] as List)
            .map((e) => e.toString())
            .toList();
      }
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  Future<void> sendSimEvent(Map<String, dynamic> event) async {
    if (sessionId == null) return;
    await http
        .post(
          Uri.parse('$baseUrl/api/v1/sessions/$sessionId/sim_event'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(event),
        )
        .timeout(connectionTimeout);
  }

  Future<List<Map<String, dynamic>>> listFiles() async {
    if (sessionId == null) return [];
    final response = await http
        .get(Uri.parse('$baseUrl/api/v1/sessions/$sessionId/files'))
        .timeout(connectionTimeout);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['files'] is List) {
        return List<Map<String, dynamic>>.from(decoded['files'] as List);
      }
    }
    return [];
  }

  Future<void> createFile(String filename, String content) async {
    if (sessionId == null) return;
    await http
        .post(
          Uri.parse('$baseUrl/api/v1/sessions/$sessionId/files'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'filename': filename, 'content': content}),
        )
        .timeout(connectionTimeout);
  }

  Future<String> transpile(String code) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/transpile'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'code': code}),
        )
        .timeout(connectionTimeout);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['python_code'] != null) {
        return decoded['python_code'].toString();
      }
    }
    throw Exception('Failed to transpile (${response.statusCode}): ${response.body}');
  }

  Future<List<Map<String, dynamic>>> listSamples() async {
    return [
      {'name': '01_quantum_mechanics.m', 'path': 'sample/01_quantum_mechanics.m'},
      {'name': '02_computational_chemistry.m', 'path': 'sample/02_computational_chemistry.m'},
      {'name': '03_orbital_mechanics.m', 'path': 'sample/03_orbital_mechanics.m'},
    ];
  }
}
