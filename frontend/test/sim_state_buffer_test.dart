import 'package:flutter_test/flutter_test.dart';
import 'package:unilab/features/simulation/models/sim_definition.dart';
import 'package:unilab/features/simulation/models/sim_state_buffer.dart';

void main() {
  group('SimulationStateBuffer Time Travel Tests', () {
    test('Buffer capacity and snapshot addition', () {
      final buffer = SimulationStateBuffer(maxCapacity: 50);
      expect(buffer.isEmpty, isTrue);

      for (int i = 0; i < 60; i++) {
        buffer.addSnapshot(
          SimSnapshot(
            time: i * 0.1,
            stepIndex: i,
            state: {'val': i},
            metrics: {'m': i},
          ),
        );
      }

      // Should be capped at 50
      expect(buffer.count, 50);
      expect(buffer.snapshots.first.stepIndex, 10);
      expect(buffer.snapshots.last.stepIndex, 59);
      expect(buffer.currentTime, closeTo(5.9, 1e-4));
    });

    test('Time travel seeking and binary search lookup', () {
      final buffer = SimulationStateBuffer(maxCapacity: 100);

      for (int i = 0; i < 20; i++) {
        buffer.addSnapshot(
          SimSnapshot(
            time: i * 0.5,
            stepIndex: i,
            state: {'pos': i * 10.0},
            metrics: {},
          ),
        );
      }

      // Seek to t = 4.2s (closest should be t = 4.0s, index 8)
      final snapshot = buffer.seekToTime(4.2);
      expect(snapshot, isNotNull);
      expect(snapshot!.time, 4.0);
      expect(snapshot.stepIndex, 8);
      expect(buffer.isScrubbing, isTrue);
    });

    test('Step backward and step forward', () {
      final buffer = SimulationStateBuffer();

      for (int i = 0; i < 10; i++) {
        buffer.addSnapshot(
          SimSnapshot(
            time: i * 0.1,
            stepIndex: i,
            state: {'i': i},
            metrics: {},
          ),
        );
      }

      // Step back
      final back1 = buffer.stepBackward();
      expect(back1, isNotNull);
      expect(back1!.stepIndex, 8);

      final back2 = buffer.stepBackward();
      expect(back2!.stepIndex, 7);

      // Step forward
      final fwd = buffer.stepForward();
      expect(fwd!.stepIndex, 8);
    });

    test('Speed multiplier updates', () {
      final buffer = SimulationStateBuffer();
      expect(buffer.speedMultiplier, 1.0);

      buffer.speedMultiplier = 2.5;
      expect(buffer.speedMultiplier, 2.5);

      // Negative multiplier ignored
      buffer.speedMultiplier = -1.0;
      expect(buffer.speedMultiplier, 2.5);
    });
  });
}
