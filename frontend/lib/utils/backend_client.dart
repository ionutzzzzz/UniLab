import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class BackendClient {
  final String baseUrl;
  String? sessionId;

  BackendClient({this.baseUrl = 'http://localhost:8000'});

  Future<void> createSession() async {
    final response = await http.post(Uri.parse('$baseUrl/sessions?username=gui_user'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      sessionId = data['session_id'];
    } else {
      throw Exception('Failed to create session');
    }
  }

  Future<ExecutionResult> runCode(String code) async {
    if (sessionId == null) await createSession();
    
    final response = await http.post(
      Uri.parse('$baseUrl/execute/$sessionId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code}),
    );

    if (response.statusCode == 200) {
      return ExecutionResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to run code: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> listSamples() async {
    // This is a placeholder. We need a backend endpoint for this or list locally.
    // For now, let's assume we can list the sample/ directory.
    return [
      {'name': '01_quantum_mechanics.m', 'path': 'sample/01_quantum_mechanics.m'},
      {'name': '02_computational_chemistry.m', 'path': 'sample/02_computational_chemistry.m'},
      {'name': '03_orbital_mechanics.m', 'path': 'sample/03_orbital_mechanics.m'},
    ];
  }
}
