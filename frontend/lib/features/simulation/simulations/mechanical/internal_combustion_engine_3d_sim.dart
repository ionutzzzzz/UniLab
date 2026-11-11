import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class InternalCombustionEngine3DSim extends SimulationModel {
  double rpm = 2400.0;
  double crankRadius = 32.0;
  double rodLength = 85.0;
  double bore = 50.0;
  double compressionRatio = 10.5;

  double crankAngle = 0.0; // Crankshaft angle in radians (0 to 4*pi for complete 4 strokes)

  InternalCombustionEngine3DSim()
      : super(
          id: 'mechanical_ic_engine_3d',
          name: '4-Stroke Engine & Piston (3D Kinematics)',
          description:
              '3D reciprocating slider-crank mechanism of an internal combustion engine with intake, compression, combustion expansion, and exhaust strokes, synchronized with the Otto cycle P-V diagram.',
          category: SimCategory.mechanical,
          dimension: SimDimension.threeD,
          tags: ['Thermodynamics', '3D', 'Engine', 'Slider-Crank', 'Otto Cycle'],
          parameters: [
            SimParameter(
              id: 'rpm',
              name: 'Engine Speed (RPM)',
              category: 'Operation',
              min: 600.0,
              max: 6000.0,
              step: 200.0,
              defaultValue: 2400.0,
            ),
            SimParameter(
              id: 'compressionRatio',
              name: 'Compression Ratio (rc)',
              category: 'Thermodynamics',
              min: 8.0,
              max: 14.0,
              step: 0.5,
              defaultValue: 10.5,
            ),
          ],
          presets: [
            SimPreset(
              id: 'idle',
              name: 'Idle Throttle (800 RPM)',
              description: 'Low speed steady state engine idling.',
              parameters: {'rpm': 800.0},
            ),
            SimPreset(
              id: 'highway_cruise',
              name: 'Highway Cruise (2800 RPM)',
              description: 'Optimal thermal efficiency cruising power band.',
              parameters: {'rpm': 2800.0},
            ),
            SimPreset(
              id: 'redline_rpm',
              name: 'Redline High-RPM (5500 RPM)',
              description: 'High inertial acceleration and valve dynamics.',
              parameters: {'rpm': 5500.0},
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
    crankAngle = 0.0;
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'rpm') rpm = (value as num).toDouble();
    if (paramId == 'compressionRatio') compressionRatio = (value as num).toDouble();
  }

  @override
  void step(double dt) {
    final omega = (rpm / 60.0) * 2.0 * math.pi;
    crankAngle = (crankAngle + omega * dt) % (4.0 * math.pi);
    time += dt;
    stepIndex++;
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {'crankAngle': crankAngle},
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    crankAngle = snapshot.state['crankAngle'] as double;
  }

  @override
  Map<String, dynamic> getMetrics() {
    final strokePhase = _getStrokePhase();
    return {
      'Engine RPM': rpm,
      'Crank Angle (deg)': (crankAngle * 180.0 / math.pi) % 720.0,
      'Active Stroke': strokePhase.name.toUpperCase(),
      'Thermal Efficiency (%)': (1.0 - 1.0 / math.pow(compressionRatio, 0.4)) * 100.0,
    };
  }

  _StrokeType _getStrokePhase() {
    final cycle = crankAngle % (4.0 * math.pi);
    if (cycle < math.pi) return _StrokeType.intake;
    if (cycle < 2.0 * math.pi) return _StrokeType.compression;
    if (cycle < 3.0 * math.pi) return _StrokeType.combustion;
    return _StrokeType.exhaust;
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    // Crank center is at world (0, -40, 0)
    final crankCenter = const Vector3(0, -40, 0);

    // Crank pin position
    final crankX = crankRadius * math.sin(crankAngle);
    final crankY = -40.0 + crankRadius * math.cos(crankAngle);
    final crankPin = Vector3(crankX, crankY, 0);

    // Piston wrist pin position: y_piston = y_crank_center + r*cos(theta) + sqrt(l^2 - r^2*sin^2(theta))
    final sinA = math.sin(crankAngle);
    final pistonY = -40.0 + crankRadius * math.cos(crankAngle) + math.sqrt(rodLength * rodLength - crankRadius * crankRadius * sinA * sinA);
    final pistonPin = Vector3(0, pistonY, 0);

    // 1. Draw 3D Cylinder Block Outline
    _renderCylinderBlock(canvas, size, camera, theme);

    // 2. Draw Combustion Chamber Flame if on Power Stroke
    final stroke = _getStrokePhase();
    if (stroke == _StrokeType.combustion) {
      _renderCombustionFlame(canvas, size, camera, pistonY, theme);
    }

    // 3. Draw 3D Piston Head
    _renderPiston(canvas, size, camera, pistonY, stroke, theme);

    // 4. Draw Connecting Rod
    _renderConnectingRod(canvas, size, camera, crankPin, pistonPin, theme);

    // 5. Draw Crankshaft Flywheel
    _renderCrankshaft(canvas, size, camera, crankCenter, crankPin, theme);
  }

  void _renderCylinderBlock(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    final blockPaint = Paint()
      ..color = theme.textMuted.withValues(alpha: 0.25)
      ..strokeWidth = 1.5;

    final halfBore = bore / 2.0;
    const topY = 115.0;
    const botY = -15.0;

    // Left wall
    final tl = camera.project(-halfBore, topY, 0, size);
    final bl = camera.project(-halfBore, botY, 0, size);
    // Right wall
    final tr = camera.project(halfBore, topY, 0, size);
    final br = camera.project(halfBore, botY, 0, size);

    if (tl != null && bl != null) canvas.drawLine(tl.screen, bl.screen, blockPaint);
    if (tr != null && br != null) canvas.drawLine(tr.screen, br.screen, blockPaint);
    if (tl != null && tr != null) canvas.drawLine(tl.screen, tr.screen, blockPaint);
  }

  void _renderPiston(Canvas canvas, Size size, SimCamera3D camera, double pistonY, _StrokeType stroke, SimTheme theme) {
    final pTop = camera.project(0, pistonY + 16, 0, size);
    final pBot = camera.project(0, pistonY - 16, 0, size);
    if (pTop == null || pBot == null) return;

    final halfBore = bore / 2.0;
    final ctl = camera.project(-halfBore + 2, pistonY + 16, 0, size);
    final ctr = camera.project(halfBore - 2, pistonY + 16, 0, size);
    final cbl = camera.project(-halfBore + 2, pistonY - 16, 0, size);
    final cbr = camera.project(halfBore - 2, pistonY - 16, 0, size);

    if (ctl != null && ctr != null && cbl != null && cbr != null) {
      final pistonColor = stroke == _StrokeType.combustion
          ? const Color(0xFFFF7043)
          : (stroke == _StrokeType.intake ? const Color(0xFF42A5F5) : theme.accent);

      final pPaint = Paint()
        ..color = pistonColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(ctl.screen.dx, ctl.screen.dy)
        ..lineTo(ctr.screen.dx, ctr.screen.dy)
        ..lineTo(cbr.screen.dx, cbr.screen.dy)
        ..lineTo(cbl.screen.dx, cbl.screen.dy)
        ..close();

      canvas.drawPath(path, pPaint);
    }
  }

  void _renderConnectingRod(Canvas canvas, Size size, SimCamera3D camera, Vector3 crankPin, Vector3 pistonPin, SimTheme theme) {
    final cp = camera.projectVector(crankPin, size);
    final pp = camera.projectVector(pistonPin, size);
    if (cp == null || pp == null) return;

    final rodPaint = Paint()
      ..color = theme.textPrimary
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(cp.screen, pp.screen, rodPaint);

    final jointPaint = Paint()..color = theme.warning;
    canvas.drawCircle(cp.screen, 4.5, jointPaint);
    canvas.drawCircle(pp.screen, 4.5, jointPaint);
  }

  void _renderCrankshaft(Canvas canvas, Size size, SimCamera3D camera, Vector3 center, Vector3 crankPin, SimTheme theme) {
    final cc = camera.projectVector(center, size);
    final cp = camera.projectVector(crankPin, size);
    if (cc == null || cp == null) return;

    final webPaint = Paint()
      ..color = theme.textMuted
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(cc.screen, cp.screen, webPaint);

    final centerPaint = Paint()..color = theme.accent;
    canvas.drawCircle(cc.screen, 7.0, centerPaint);
  }

  void _renderCombustionFlame(Canvas canvas, Size size, SimCamera3D camera, double pistonY, SimTheme theme) {
    final sparkPos = camera.project(0, 105.0, 0, size);
    if (sparkPos != null) {
      // Intense combustion fireball with pulsation
      final flameRadius = 24.0 + 8.0 * math.sin(time * 30.0);
      final flamePaint = Paint()
        ..color = const Color(0xFFFF3D00).withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16.0);
      canvas.drawCircle(sparkPos.screen, flameRadius, flamePaint);

      final corePaint = Paint()
        ..color = const Color(0xFFFFEA00)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawCircle(sparkPos.screen, flameRadius * 0.5, corePaint);

      // Micro combustion sparks
      final sparkPaint = Paint()..color = Colors.white;
      for (int i = 0; i < 8; i++) {
        final a = i * (math.pi / 4.0) + (time * 12.0);
        final r = 10.0 + 12.0 * ((time * 25.0 + i * 4.0) % 1.0);
        canvas.drawCircle(
          Offset(sparkPos.screen.dx + r * math.cos(a), sparkPos.screen.dy + r * math.sin(a)),
          1.5,
          sparkPaint,
        );
      }
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab 4-Stroke Engine Piston Kinematics
rpm = $rpm; r = $crankRadius; l = $rodLength;
theta = linspace(0, 4*pi, 720);

% Piston displacement x(theta)
x = r * cos(theta) + sqrt(l^2 - (r * sin(theta)).^2);
v = -r * sin(theta) .* (1 + (r * cos(theta)) ./ sqrt(l^2 - (r * sin(theta)).^2));

figure('Name', 'Piston Kinematics');
subplot(2,1,1); plot(theta*180/pi, x); grid on;
title('Piston Displacement (mm)');
subplot(2,1,2); plot(theta*180/pi, v); grid on;
title('Piston Velocity');
''';
  }
}

enum _StrokeType { intake, compression, combustion, exhaust }
