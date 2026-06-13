import 'package:flutter_test/flutter_test.dart';
import 'package:unilab/bridge/unilab_bridge.dart';
import 'package:unilab/models/models.dart';
import 'dart:io';

void main() {
  // This test requires the native library to be built and accessible.
  // We use a skip if the library is not found.
  
  test('UniLab Bridge End-to-End Test', () async {
    print('--- UniLab Bridge Test ---');
    
    final bridge = UniLabBridge.instance;
    
    try {
      print('1. Initializing bridge...');
      await bridge.initialize();
      print('   Bridge initialized.');
      
      print('2. Creating session...');
      final sessionId = await bridge.createSession('test_user');
      print('   Session created: $sessionId');
      
      print('3. Executing code (basic math)...');
      final result1 = await bridge.execute('a = 10; b = 20; c = a + b; disp(c);');
      print('   Result success: ${result1.success}');
      print('   Stdout: ${result1.stdout.trim()}');
      
      expect(result1.success, true);
      expect(result1.stdout.trim(), contains('30'));
      expect(result1.variables.containsKey('c'), true);

      print('4. Executing code (plot)...');
      final result2 = await bridge.execute('x = linspace(0, 10, 100); y = sin(x); plot(x, y);');
      print('   Result success: ${result2.success}');
      print('   Number of plots: ${result2.plots.length}');
      
      expect(result2.success, true);
      expect(result2.plots.isNotEmpty, true);
      
      if (result2.plots.isNotEmpty) {
        final plot = result2.plots.first;
        print('   Plot title: ${plot.title}');
        expect(plot.imageDataUri, isNotNull);
        expect(plot.imageDataUri, startsWith('data:image/png;base64,'));
        print('   Plot image data (prefix): ${plot.imageDataUri?.substring(0, 50)}...');
      }

      print('5. Autocomplete test...');
      final suggestions = await bridge.getAutocomplete('lin');
      print('   Suggestions for "lin": $suggestions');
      expect(suggestions, contains('linspace'));

      print('6. Workspace test...');
      final workspace = await bridge.getWorkspace();
      print('   Workspace: ${workspace.keys}');
      expect(workspace.containsKey('c'), true);

      print('7. Transpilation test...');
      final pythonCode = await bridge.transpile('a = 10; b = 20; c = a + b;');
      print('   Transpiled Python code:\n$pythonCode');
      expect(pythonCode, contains('a = 10'));
      expect(pythonCode, contains('b = 20'));
      expect(pythonCode, contains('c = (unilab_call(a) + unilab_call(b))'));

      print('--- Bridge Test Completed Successfully ---');
    } catch (e, stack) {
      print('--- Bridge Test Failed ---');
      print('Error: $e');
      print('Stack: $stack');
      rethrow;
    }
  });
}
