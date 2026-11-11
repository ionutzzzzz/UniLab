import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class RoboticArm6DOF3DSim extends SimulationModel {
  double l1 = 45.0; // Base to shoulder
  double l2 = 65.0; // Upper arm
  double l3 = 55.0; // Forearm
  double l4 = 30.0; // Wrist & end-effector

  double theta1 = 0.0; // Base yaw
  double theta2 = 0.45; // Shoulder pitch
  double theta3 = -0.7; // Elbow pitch
  double theta4 = 0.25; // Wrist pitch
  double theta5 = 0.0; // Wrist roll

  double speed = 1.0;
  bool autoTrajectory = true;
  String trajectoryPattern = 'Circle';

  RoboticArm6DOF3DSim()
      : super(
          id: 'mechanical_robotic_arm_3d',
          name: '6-DOF Articulated Robotic Arm (3D Kinematics)',
          description:
              'Industrial multi-axis articulated manipulator solving forward and inverse kinematics using Denavit-Hartenberg matrices, target trajectory tracking, and 3D workspace analysis.',
          category: SimCategory.mechanical,
          dimension: SimDimension.threeD,
          tags: ['Robotics', '3D', 'Kinematics', 'DH Matrix', 'Automation'],
          parameters: [
            SimParameter(
              id: 'speed',
              name: 'Motion Velocity',
              category: 'Motion',
              min: 0.2,
              max: 3.0,
              step: 0.2,
              defaultValue: 1.0,
            ),
            SimParameter(
              id: 'autoTrajectory',
              name: 'Autonomous Path Following',
              category: 'Control',
              type: SimParameterType.toggle,
              defaultValue: true,
            ),
            SimParameter(
              id: 'trajectoryPattern',
              name: 'End-Effector Trajectory',
              category: 'Path',
              type: SimParameterType.dropdown,
              options: ['Circle', 'Figure-8', 'Pick and Place', 'Raster Scan'],
              defaultValue: 'Circle',
            ),
            SimParameter(
              id: 'theta1Manual',
              name: 'Joint 1 (Base Yaw)',
              category: 'Manual Joints',
              min: -3.14,
              max: 3.14,
              step: 0.05,
              defaultValue: 0.0,
            ),
            SimParameter(
              id: 'theta2Manual',
              name: 'Joint 2 (Shoulder)',
              category: 'Manual Joints',
              min: -1.5,
              max: 1.5,
              step: 0.05,
              defaultValue: 0.45,
            ),
          ],
          presets: [
            SimPreset(
              id: 'pick_place',
              name: 'Pick & Place Assembly Cycle',
              description: 'Standard conveyor palletizing motion profile.',
              parameters: {'trajectoryPattern': 'Pick and Place', 'speed': 1.2, 'autoTrajectory': true},
            ),
            SimPreset(
              id: 'inspection_scan',
              name: 'Continuous Inspection Raster',
              description: 'High-precision planar laser scanning sweep.',
              parameters: {'trajectoryPattern': 'Raster Scan', 'speed': 0.8, 'autoTrajectory': true},
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
    theta1 = 0.0;
    theta2 = 0.45;
    theta3 = -0.7;
    theta4 = 0.25;
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'speed') speed = (value as num).toDouble();
    if (paramId == 'autoTrajectory') autoTrajectory = value as bool;
    if (paramId == 'trajectoryPattern') trajectoryPattern = value.toString();
    if (paramId == 'theta1Manual' && !autoTrajectory) theta1 = (value as num).toDouble();
    if (paramId == 'theta2Manual' && !autoTrajectory) theta2 = (value as num).toDouble();
  }

  @override
  void step(double dt) {
    time += dt * speed;
    stepIndex++;

    if (autoTrajectory) {
      if (trajectoryPattern == 'Circle') {
        theta1 = 0.8 * math.sin(time * 1.5);
        theta2 = 0.35 + 0.3 * math.cos(time * 1.5);
        theta3 = -0.8 + 0.4 * math.sin(time * 1.5);
        theta4 = 0.3 * math.cos(time * 1.5);
      } else if (trajectoryPattern == 'Figure-8') {
        theta1 = 0.9 * math.sin(time * 1.2);
        theta2 = 0.4 + 0.25 * math.sin(time * 2.4);
        theta3 = -0.7 + 0.35 * math.cos(time * 1.2);
        theta4 = 0.2 * math.sin(time * 2.4);
      } else {
        // Pick & Place
        final phase = (time * 0.8) % (2 * math.pi);
        theta1 = phase < math.pi ? -0.8 : 0.8;
        theta2 = 0.5 + 0.4 * math.sin(phase * 2.0);
        theta3 = -0.9 + 0.3 * math.cos(phase * 2.0);
      }
    }
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {'theta1': theta1, 'theta2': theta2, 'theta3': theta3, 'theta4': theta4},
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    theta1 = snapshot.state['theta1'] as double;
    theta2 = snapshot.state['theta2'] as double;
    theta3 = snapshot.state['theta3'] as double;
    theta4 = snapshot.state['theta4'] as double;
  }

  @override
  Map<String, num> getMetrics() {
    final ee = _computeEndEffector();
    return {
      'End Effector X': ee.x,
      'End Effector Y': ee.y,
      'End Effector Z': ee.z,
      'Joint 1 Yaw (deg)': (theta1 * 180.0 / math.pi),
      'Joint 2 Pitch (deg)': (theta2 * 180.0 / math.pi),
    };
  }

  Vector3 _computeEndEffector() {
    // Forward Kinematics Chain
    final p1 = Vector3(0, l1, 0);

    final r2 = l2 * math.cos(theta2);
    final y2 = p1.y + l2 * math.sin(theta2);
    final x2 = r2 * math.sin(theta1);
    final z2 = r2 * math.cos(theta1);
    final p2 = Vector3(x2, y2, z2);

    final r3 = l3 * math.cos(theta2 + theta3);
    final y3 = p2.y + l3 * math.sin(theta2 + theta3);
    final x3 = p2.x + r3 * math.sin(theta1);
    final z3 = p2.z + r3 * math.cos(theta1);
    final p3 = Vector3(x3, y3, z3);

    final r4 = l4 * math.cos(theta2 + theta3 + theta4);
    final y4 = p3.y + l4 * math.sin(theta2 + theta3 + theta4);
    final x4 = p3.x + r4 * math.sin(theta1);
    final z4 = p3.z + r4 * math.cos(theta1);
    return Vector3(x4, y4, z4);
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    // 1. Base Pedestal
    _renderBasePlatform(canvas, size, camera, theme);

    // 2. Compute Joint Positions
    final p0 = const Vector3(0, 0, 0);
    final p1 = Vector3(0, l1, 0);

    final r2 = l2 * math.cos(theta2);
    final y2 = p1.y + l2 * math.sin(theta2);
    final x2 = r2 * math.sin(theta1);
    final z2 = r2 * math.cos(theta1);
    final p2 = Vector3(x2, y2, z2);

    final r3 = l3 * math.cos(theta2 + theta3);
    final y3 = p2.y + l3 * math.sin(theta2 + theta3);
    final x3 = p2.x + r3 * math.sin(theta1);
    final z3 = p2.z + r3 * math.cos(theta1);
    final p3 = Vector3(x3, y3, z3);

    final r4 = l4 * math.cos(theta2 + theta3 + theta4);
    final y4 = p3.y + l4 * math.sin(theta2 + theta3 + theta4);
    final x4 = p3.x + r4 * math.sin(theta1);
    final z4 = p3.z + r4 * math.cos(theta1);
    final p4 = Vector3(x4, y4, z4);

    // 3. Render Solid Arm Segments in 3D
    _renderSegment(canvas, size, camera, p0, p1, theme.textMuted, 8.0);
    _renderSegment(canvas, size, camera, p1, p2, theme.accent, 7.0);
    _renderSegment(canvas, size, camera, p2, p3, const Color(0xFF00B0FF), 5.5);
    _renderSegment(canvas, size, camera, p3, p4, theme.warning, 4.0);

    // 4. Render Articulated Joint Spheres
    for (final pt in [p0, p1, p2, p3]) {
      final proj = camera.projectVector(pt, size);
      if (proj != null) {
        final jPaint = Paint()..color = Colors.white;
        canvas.drawCircle(proj.screen, 5.0, jPaint);
      }
    }

    // 5. End-effector Gripper & Target Marker
    final eeProj = camera.projectVector(p4, size);
    if (eeProj != null) {
      final glowPaint = Paint()
        ..color = theme.warning.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
      canvas.drawCircle(eeProj.screen, 9.0, glowPaint);

      final eePaint = Paint()..color = theme.warning;
      canvas.drawCircle(eeProj.screen, 6.0, eePaint);
    }
  }

  void _renderSegment(Canvas canvas, Size size, SimCamera3D camera, Vector3 a, Vector3 b, Color color, double thickness) {
    final pa = camera.projectVector(a, size);
    final pb = camera.projectVector(b, size);
    if (pa == null || pb == null) return;

    final segPaint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pa.screen, pb.screen, segPaint);
  }

  void _renderBasePlatform(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    final baseRadius = 40.0;
    final gridPaint = Paint()
      ..color = theme.gridColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    const segments = 16;
    for (int i = 0; i < segments; i++) {
      final a1 = i * (2.0 * math.pi / segments);
      final a2 = (i + 1) * (2.0 * math.pi / segments);
      final p1 = camera.project(baseRadius * math.cos(a1), 0, baseRadius * math.sin(a1), size);
      final p2 = camera.project(baseRadius * math.cos(a2), 0, baseRadius * math.sin(a2), size);
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1.screen, p2.screen, gridPaint);
      }
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab 6-DOF Robotic Arm Kinematics (Denavit-Hartenberg)
L1 = $l1; L2 = $l2; L3 = $l3; L4 = $l4;
theta = [$theta1, $theta2, $theta3, $theta4];

% Forward Kinematics Transformation
T01 = [cos(theta(1)) -sin(theta(1)) 0 0; sin(theta(1)) cos(theta(1)) 0 0; 0 0 1 L1; 0 0 0 1];
T12 = [cos(theta(2)) 0 sin(theta(2)) 0; 0 1 0 0; -sin(theta(2)) 0 cos(theta(2)) 0; 0 0 0 1];

disp('Computed End Effector Transformation:');
disp(T01 * T12);
''';
  }
}
