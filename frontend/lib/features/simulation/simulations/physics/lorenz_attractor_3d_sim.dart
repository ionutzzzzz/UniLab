import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class LorenzAttractor3DSim extends SimulationModel {
  double sigma = 10.0;
  double rho = 28.0;
  double beta = 8.0 / 3.0;
  double speed = 1.0;
  int maxHistory = 1200;

  double x = 0.1;
  double y = 0.0;
  double z = 0.0;

  final List<Vector3> _history = [];

  LorenzAttractor3DSim()
      : super(
          id: 'physics_lorenz_3d',
          name: 'Lorenz Strange Attractor (3D Chaos)',
          description:
              'Continuous 3D non-linear dynamic system modeling atmospheric convection. Demonstrates the butterfly effect, deterministic chaos, and fractal strange attractors.',
          category: SimCategory.physics,
          dimension: SimDimension.threeD,
          tags: ['Chaos', '3D', 'Attractor', 'Nonlinear', 'Atmosphere'],
          parameters: [
            SimParameter(
              id: 'sigma',
              name: 'Prandtl Number (σ)',
              category: 'Parameters',
              min: 1.0,
              max: 30.0,
              step: 0.5,
              defaultValue: 10.0,
            ),
            SimParameter(
              id: 'rho',
              name: 'Rayleigh Number (ρ)',
              category: 'Parameters',
              min: 0.0,
              max: 60.0,
              step: 1.0,
              defaultValue: 28.0,
            ),
            SimParameter(
              id: 'beta',
              name: 'Geometric Factor (β)',
              category: 'Parameters',
              min: 0.5,
              max: 10.0,
              step: 0.1,
              defaultValue: 2.667,
            ),
            SimParameter(
              id: 'speed',
              name: 'Evolution Rate',
              category: 'Simulation',
              min: 0.2,
              max: 3.0,
              step: 0.2,
              defaultValue: 1.0,
            ),
          ],
          presets: [
            SimPreset(
              id: 'classic_butterfly',
              name: 'Classic Lorenz Butterfly',
              description: 'Standard chaotic regime with two unstable focus loops.',
              parameters: {'sigma': 10.0, 'rho': 28.0, 'beta': 2.667},
            ),
            SimPreset(
              id: 'periodic_orbit',
              name: 'Stable Periodic Limit Cycle',
              description: 'Rayleigh parameter producing a periodic limit cycle.',
              parameters: {'sigma': 10.0, 'rho': 99.96, 'beta': 2.667},
            ),
            SimPreset(
              id: 'intermittent_chaos',
              name: 'Intermittent Turbulence',
              description: 'Alternating between laminar periods and chaotic bursts.',
              parameters: {'sigma': 10.0, 'rho': 166.0, 'beta': 2.667},
            ),
          ],
        );

  @override
  void init() {
    reset();
  }

  @override
  void reset() {
    time = 0.0;
    stepIndex = 0;
    x = 0.1;
    y = 0.0;
    z = 0.0;
    _history.clear();
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'sigma') sigma = (value as num).toDouble();
    if (paramId == 'rho') rho = (value as num).toDouble();
    if (paramId == 'beta') beta = (value as num).toDouble();
    if (paramId == 'speed') speed = (value as num).toDouble();
  }

  @override
  void step(double dt) {
    final subSteps = 6;
    final h = (dt * speed / subSteps).clamp(0.001, 0.03);

    for (int s = 0; s < subSteps; s++) {
      final dx = sigma * (y - x);
      final dy = x * (rho - z) - y;
      final dz = x * y - beta * z;

      x += dx * h;
      y += dy * h;
      z += dz * h;

      // Scale and center around z=25 for convenient 3D coordinate framing
      _history.add(Vector3(x * 3.5, (z - 25.0) * 3.5, y * 3.5));
      if (_history.length > maxHistory) {
        _history.removeAt(0);
      }
    }

    time += dt * speed;
    stepIndex++;
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {
        'x': x,
        'y': y,
        'z': z,
        'history': List<Vector3>.from(_history),
      },
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    x = snapshot.state['x'] as double;
    y = snapshot.state['y'] as double;
    z = snapshot.state['z'] as double;
    _history.clear();
    if (snapshot.state['history'] != null) {
      _history.addAll(snapshot.state['history'] as List<Vector3>);
    }
  }

  @override
  Map<String, num> getMetrics() {
    return {
      'State X': x,
      'State Y': y,
      'State Z': z,
      'Trajectory Nodes': _history.length,
      'Speed': speed,
    };
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    // Reference box
    _renderBoundingCube(canvas, size, camera, theme);

    if (_history.length < 2) return;

    // Draw multi-spectral 3D attractor ribbons
    for (int i = 0; i < _history.length - 1; i++) {
      final p1 = camera.projectVector(_history[i], size);
      final p2 = camera.projectVector(_history[i + 1], size);
      if (p1 == null || p2 == null) continue;

      final progress = i / _history.length;
      final color = _getAttractorColor(progress, theme);

      final ribbonPaint = Paint()
        ..color = color.withValues(alpha: 0.2 + progress * 0.8)
        ..strokeWidth = 1.0 + progress * 2.0;

      canvas.drawLine(p1.screen, p2.screen, ribbonPaint);
    }

    // Glowing head particle
    if (_history.isNotEmpty) {
      final head = camera.projectVector(_history.last, size);
      if (head != null) {
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
        canvas.drawCircle(head.screen, 6.0, glowPaint);

        final dotPaint = Paint()..color = theme.accent;
        canvas.drawCircle(head.screen, 4.0, dotPaint);
      }
    }
  }

  Color _getAttractorColor(double t, SimTheme theme) {
    // Gradient between cyan, violet, and gold
    if (t < 0.5) {
      return Color.lerp(theme.accent, const Color(0xFFE040FB), t * 2.0)!;
    } else {
      return Color.lerp(const Color(0xFFE040FB), const Color(0xFFFFD600), (t - 0.5) * 2.0)!;
    }
  }

  void _renderBoundingCube(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    final edgePaint = Paint()
      ..color = theme.gridColor.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    const s = 110.0;
    final corners = [
      Vector3(-s, -s, -s), Vector3(s, -s, -s), Vector3(s, s, -s), Vector3(-s, s, -s),
      Vector3(-s, -s, s), Vector3(s, -s, s), Vector3(s, s, s), Vector3(-s, s, s),
    ];

    final edges = [
      [0, 1], [1, 2], [2, 3], [3, 0],
      [4, 5], [5, 6], [6, 7], [7, 4],
      [0, 4], [1, 5], [2, 6], [3, 7],
    ];

    for (final edge in edges) {
      final p1 = camera.projectVector(corners[edge[0]], size);
      final p2 = camera.projectVector(corners[edge[1]], size);
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1.screen, p2.screen, edgePaint);
      }
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab 3D Lorenz Attractor
sigma = $sigma; rho = $rho; beta = $beta;

f = @(t, a) [
    sigma * (a(2) - a(1));
    a(1) * (rho - a(3)) - a(2);
    a(1) * a(2) - beta * a(3)
];

[t, a] = ode45(f, [0 50], [0.1; 0; 0]);

figure('Name', '3D Lorenz Strange Attractor');
plot3(a(:, 1), a(:, 2), a(:, 3), 'LineWidth', 1.2);
grid on; view(45, 30);
title('Lorenz Attractor Trajectory');
xlabel('X'); ylabel('Y'); zlabel('Z');
''';
  }
}
