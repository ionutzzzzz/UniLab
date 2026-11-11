// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:unilab/bridge/unilab_bridge.dart';

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
    } catch (e) {
      if (e.toString().contains('Could not load library')) {
        print('   Skipping native bridge test: native binary libunilab_core.dylib is not compiled on host (built inside Docker).');
        return;
      }
      rethrow;
    }

    try {
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
        expect(plot.title, isNotEmpty);
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

      print('8. Control systems test (TeoriaSistemelor.m)...');
      final resControl = await bridge.execute('''
clear all; close all; clc;
Hdes = tf(1928.68,[0.1998,1,0])
clf , nichols(Hdes) , grid , hold on
Mdb = 5.28;
M = 10^(Mdb/20);
Ts = 0.01;
t = (pi+Ts):Ts:(2*pi);
X = -M^2/(M^2-1);
Y = 0;
R = abs(M/(M^2-1));
x = X+R*cos(t); y = Y+R*sin(t);
mag = 20*log10(sqrt(x.^2+y.^2));
ph = atan2(y,x);
plot(rad2deg(ph),mag,'r')
figure(2)
H = feedback(Hdes,1)
bode(H)
''', filename: 'TeoriaSistemelor.m');
      expect(resControl.success, true, reason: resControl.stderr);

      print('9. 3D plot with figure Color/Name and view(3) (Untitled.m)...');
      final res3d = await bridge.execute('''
num_steps = 50;
dx = randn(1, num_steps); dy = randn(1, num_steps); dz = randn(1, num_steps);
x = [0, cumsum(dx)]; y = [0, cumsum(dy)]; z = [0, cumsum(dz)];
figure('Name', '3D Random Walk', 'Color', 'w');
plot3(x, y, z, 'b-', 'LineWidth', 1.2);
hold on; grid on;
title('3D Random Walk Simulation');
xlabel('X-axis'); ylabel('Y-axis'); zlabel('Z-axis');
legend('Path', 'Location', 'best');
view(3);
hold off;
disp('Simulation complete!');
''', filename: 'Untitled.m');
      expect(res3d.success, true, reason: res3d.stderr);

      print('10. Signal pulses test (27_signal_pulses.m)...');
      final resPulses = await bridge.execute('''
clear all; close all; clc;
disp('UniLab Signal Pulses');
t = linspace(-5, 5, 500);
y_sinc = sinc_custom(t);
y_rect = rect_custom(t / 2.0);
y_step = unit_step_custom(t - 1.0);
y_dirac = dirac_delta(t);
figure;
subplot(3, 1, 1); plot(t, y_sinc, 'b-', 'LineWidth', 2); grid on;
subplot(3, 1, 2); plot(t, y_rect, 'r-', 'LineWidth', 2); grid on;
subplot(3, 1, 3); plot(t, y_step, 'g-', 'LineWidth', 2); grid on;
disp('Signal visualizations generated successfully.');
''', filename: '27_signal_pulses.m');
      expect(resPulses.success, true, reason: resPulses.stderr);

      print('11. Stop execution & immediate re-execution test...');
      final infiniteRunFuture = bridge.execute('''
k_loop = 0;
while true
  k_loop = k_loop + 1;
end
''');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await bridge.cancelExecution();
      final cancelledRes = await infiniteRunFuture;
      print('   Cancelled run stderr: ${cancelledRes.stderr}');
      expect(cancelledRes.success, false);

      final immediateNextRes = await bridge.execute('next_val = 777; disp(next_val);');
      print('   Immediate next script stdout: ${immediateNextRes.stdout.trim()}');
      expect(immediateNextRes.success, true, reason: immediateNextRes.stderr);
      expect(immediateNextRes.stdout.trim(), contains('777'));

      print('--- Bridge Test Completed Successfully ---');
    } catch (e, stack) {
      print('--- Bridge Test Failed ---');
      print('Error: $e');
      print('Stack: $stack');
      rethrow;
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
