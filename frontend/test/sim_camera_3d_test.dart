import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unilab/features/simulation/models/sim_camera_3d.dart';

void main() {
  group('SimCamera3D & Vector3 Tests', () {
    test('Vector3 arithmetic and normalization', () {
      const v1 = Vector3(1, 2, 3);
      const v2 = Vector3(4, 5, 6);

      final vSum = v1 + v2;
      expect(vSum.x, 5.0);
      expect(vSum.y, 7.0);
      expect(vSum.z, 9.0);

      final vDiff = v2 - v1;
      expect(vDiff.x, 3.0);
      expect(vDiff.y, 3.0);
      expect(vDiff.z, 3.0);

      expect(v1.dot(v2), 1 * 4 + 2 * 5 + 3 * 6); // 32

      const vNorm = Vector3(3, 4, 0);
      expect(vNorm.length, 5.0);
      final unit = vNorm.normalized();
      expect(unit.length, closeTo(1.0, 1e-6));
      expect(unit.x, closeTo(0.6, 1e-6));
      expect(unit.y, closeTo(0.8, 1e-6));
    });

    test('Camera orbit rotation and clamp', () {
      final camera = SimCamera3D(yaw: 0.0, pitch: 0.0, distance: 100.0);
      camera.orbit(0.5, 0.3);
      expect(camera.yaw, 0.5);
      expect(camera.pitch, 0.3);

      // Pitch clamp test
      camera.orbit(0.0, 5.0);
      expect(camera.pitch, closeTo(1.45, 1e-4));
    });

    test('Camera zoom and distance clamp', () {
      final camera = SimCamera3D(distance: 200.0);
      camera.zoom(1.5);
      expect(camera.distance, 300.0);

      camera.zoom(0.001);
      expect(camera.distance, 20.0); // Min clamp
    });

    test('3D to 2D perspective projection', () {
      final camera = SimCamera3D(
        yaw: 0.0,
        pitch: 0.0,
        distance: 200.0,
        target: const Vector3(0, 0, 0),
      );

      const viewport = Size(800, 600);
      // Project origin (0, 0, 0)
      final projOrigin = camera.project(0, 0, 0, viewport);
      expect(projOrigin, isNotNull);
      // Origin should be centered in screen
      expect(projOrigin!.screen.dx, closeTo(400.0, 1.0));
      expect(projOrigin.screen.dy, closeTo(300.0, 1.0));
      expect(projOrigin.depth, greaterThan(0.0));
    });

    test('Directional lighting calculation', () {
      final camera = SimCamera3D();
      const normal = Vector3(0, 1, 0);
      const baseColor = Color(0xFFFFFFFF);

      final litColor = camera.calculateLighting(normal, baseColor);
      expect((litColor.a * 255).round(), 255);
      expect((litColor.r * 255).round(), greaterThan(50));
    });
  });
}
