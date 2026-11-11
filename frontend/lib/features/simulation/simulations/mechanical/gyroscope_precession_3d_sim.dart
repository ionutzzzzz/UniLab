import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class GyroscopePrecession3DSim extends SimulationModel {
  double spinRate = 25.0; // Flywheel spin (rad/s)
  double torque = 8.0; // Gravitational tilt torque
  double damping = 0.005;

  double roll = 0.0;
  double pitch = 0.35;
  double yaw = 0.0;
  double precessionRate = 0.0;

  GyroscopePrecession3DSim()
      : super(
          id: 'mechanical_gyroscope_3d',
          name: 'Gyroscope & Gimbal Precession (3D Dynamics)',
          description:
              '3D rigid body rotational dynamics with 3-axis concentric gimbal rings. Demonstrates angular momentum conservation \$\\vec{L} = I \\vec{\\omega}\$, gyroscopic precession, nutation wobbles, and Euler gimbal lock.',
          category: SimCategory.mechanical,
          dimension: SimDimension.threeD,
          tags: ['Gyroscope', '3D', 'Angular Momentum', 'Precession', 'Euler Angles'],
          parameters: [
            SimParameter(
              id: 'spinRate',
              name: 'Flywheel Spin (rad/s)',
              category: 'Rotor',
              min: 5.0,
              max: 60.0,
              step: 5.0,
              defaultValue: 25.0,
            ),
            SimParameter(
              id: 'torque',
              name: 'Applied Tilt Torque',
              category: 'Dynamics',
              min: 0.0,
              max: 20.0,
              step: 1.0,
              defaultValue: 8.0,
            ),
            SimParameter(
              id: 'damping',
              name: 'Bearing Friction Damping',
              category: 'Friction',
              min: 0.0,
              max: 0.02,
              step: 0.001,
              defaultValue: 0.005,
            ),
          ],
          presets: [
            SimPreset(
              id: 'fast_precession',
              name: 'High-Speed Steady Precession',
              description: 'Fast flywheel spin maintaining stable horizontal gyroscopic precession.',
              parameters: {'spinRate': 40.0, 'torque': 8.0},
            ),
            SimPreset(
              id: 'nutation_wobble',
              name: 'Precession with Nutation Wobble',
              description: 'Visible oscillatory nutation perturbation superimposed on precession.',
              parameters: {'spinRate': 15.0, 'torque': 12.0},
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
    roll = 0.0;
    pitch = 0.35;
    yaw = 0.0;
    precessionRate = 0.0;
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'spinRate') spinRate = (value as num).toDouble();
    if (paramId == 'torque') torque = (value as num).toDouble();
    if (paramId == 'damping') damping = (value as num).toDouble();
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;

    // Gyroscopic precession angular velocity: Omega_p = Torque / (I * spinRate)
    final inertia = 0.4;
    precessionRate = torque / (inertia * spinRate + 1e-4);

    yaw += precessionRate * dt;
    roll += spinRate * dt;
    // Nutation oscillation
    pitch = 0.35 + 0.08 * math.sin(time * (spinRate * 0.4));
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {'yaw': yaw, 'pitch': pitch, 'roll': roll},
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    yaw = snapshot.state['yaw'] as double;
    pitch = snapshot.state['pitch'] as double;
    roll = snapshot.state['roll'] as double;
  }

  @override
  Map<String, num> getMetrics() {
    return {
      'Rotor Spin (rad/s)': spinRate,
      'Precession Rate (rad/s)': precessionRate,
      'Precession Period (s)': precessionRate > 0 ? (2.0 * math.pi / precessionRate) : 0,
      'Nutation Tilt (deg)': (pitch * 180.0 / math.pi),
    };
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    // 1. Base mount stand
    final baseBottom = camera.project(0, -60, 0, size);
    final baseTop = camera.project(0, 0, 0, size);
    if (baseBottom != null && baseTop != null) {
      final standPaint = Paint()
        ..color = theme.textMuted
        ..strokeWidth = 4.0;
      canvas.drawLine(baseBottom.screen, baseTop.screen, standPaint);
    }

    // 2. Outer Gimbal Ring (Yaw rotation)
    _render3DRing(canvas, size, camera, 60.0, yaw, 0, 0, theme.accent, 2.5);

    // 3. Middle Gimbal Ring (Pitch rotation)
    _render3DRing(canvas, size, camera, 48.0, yaw, pitch, 0, const Color(0xFF00E676), 2.0);

    // 4. Central Spinning Rotor Flywheel
    _renderSpinningRotor(canvas, size, camera, 36.0, yaw, pitch, roll, theme);
  }

  void _render3DRing(Canvas canvas, Size size, SimCamera3D camera, double radius, double yAngle, double pAngle, double rAngle, Color color, double strokeWidth) {
    const segments = 24;
    final ringPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool first = true;

    for (int i = 0; i <= segments; i++) {
      final angle = i * (2.0 * math.pi / segments);
      // Ring circle in XY plane, transformed by yaw and pitch
      var rx = radius * math.cos(angle);
      var ry = radius * math.sin(angle);
      var rz = 0.0;

      // Pitch rotation around X
      final ryP = ry * math.cos(pAngle) - rz * math.sin(pAngle);
      final rzP = ry * math.sin(pAngle) + rz * math.cos(pAngle);

      // Yaw rotation around Y
      final rxY = rx * math.cos(yAngle) + rzP * math.sin(yAngle);
      final rzY = -rx * math.sin(yAngle) + rzP * math.cos(yAngle);

      final pt = camera.project(rxY, ryP, rzY, size);
      if (pt != null) {
        if (first) {
          path.moveTo(pt.screen.dx, pt.screen.dy);
          first = false;
        } else {
          path.lineTo(pt.screen.dx, pt.screen.dy);
        }
      }
    }
    canvas.drawPath(path, ringPaint);
  }

  void _renderSpinningRotor(Canvas canvas, Size size, SimCamera3D camera, double radius, double yAngle, double pAngle, double rAngle, SimTheme theme) {
    // Rotor disc normal axis
    final axisDir = Vector3(
      math.sin(yAngle) * math.cos(pAngle),
      math.sin(pAngle),
      math.cos(yAngle) * math.cos(pAngle),
    );

    final shaftA = camera.projectVector(axisDir * 30.0, size);
    final shaftB = camera.projectVector(axisDir * -30.0, size);
    if (shaftA != null && shaftB != null) {
      final shaftPaint = Paint()
        ..color = theme.warning
        ..strokeWidth = 3.5;
      canvas.drawLine(shaftA.screen, shaftB.screen, shaftPaint);
    }

    // Heavy Rotor Disc
    _render3DRing(canvas, size, camera, radius, yAngle, pAngle, rAngle, theme.warning, 5.0);

    // Spokes
    for (int s = 0; s < 4; s++) {
      final spAngle = rAngle + s * (math.pi / 2.0);
      final spX = radius * math.cos(spAngle);
      final spY = radius * math.sin(spAngle);
      final spPoint = Vector3(
        spX * math.cos(yAngle),
        spY * math.cos(pAngle),
        -spX * math.sin(yAngle),
      );
      final spProj = camera.projectVector(spPoint, size);
      final centerProj = camera.project(0, 0, 0, size);
      if (spProj != null && centerProj != null) {
        final spPaint = Paint()
          ..color = theme.warning.withValues(alpha: 0.6)
          ..strokeWidth = 1.5;
        canvas.drawLine(centerProj.screen, spProj.screen, spPaint);
      }
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab 3D Gyroscope & Gimbal Precession Dynamics
spinRate = $spinRate; % rad/s
torque = $torque;     % N*m
inertia = 0.4;        % kg*m^2

% Steady state precession angular velocity
omega_p = torque / (inertia * spinRate);
disp(['Gyroscopic Precession Rate: ', num2str(omega_p), ' rad/s']);
disp(['Precession Period: ', num2str(2*pi/omega_p), ' s']);
''';
  }
}
