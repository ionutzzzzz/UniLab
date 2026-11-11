import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class SkyscraperEarthquake3DSim extends SimulationModel {
  int floors = 12;
  double earthquakeFreq = 1.2; // Hz
  double groundAmplitude = 18.0;
  bool enableTMD = true; // Tuned Mass Damper
  double tmdMassRatio = 0.04;
  double damping = 0.015;

  double tmdDisplacement = 0.0;
  double tmdVelocity = 0.0;
  final List<double> _floorDisplacements = List.filled(12, 0.0);

  SkyscraperEarthquake3DSim()
      : super(
          id: 'architecture_skyscraper_earthquake_3d',
          name: 'Skyscraper Earthquake & TMD (3D Structural FEM)',
          description:
              '3D multi-story high-rise dynamic response under seismic excitation. Demonstrates building resonance, story drift deflection, and vibration mitigation using a rooftop Tuned Mass Damper (TMD).',
          category: SimCategory.architecture,
          dimension: SimDimension.threeD,
          tags: ['Structural', '3D', 'Earthquake', 'Tuned Mass Damper', 'Resonance'],
          parameters: [
            SimParameter(
              id: 'earthquakeFreq',
              name: 'Seismic Frequency (Hz)',
              category: 'Ground Motion',
              min: 0.2,
              max: 3.0,
              step: 0.1,
              defaultValue: 1.2,
            ),
            SimParameter(
              id: 'groundAmplitude',
              name: 'Ground Acceleration Amp',
              category: 'Ground Motion',
              min: 0.0,
              max: 40.0,
              step: 2.0,
              defaultValue: 18.0,
            ),
            SimParameter(
              id: 'enableTMD',
              name: 'Active Tuned Mass Damper',
              category: 'Damping System',
              type: SimParameterType.toggle,
              defaultValue: true,
            ),
            SimParameter(
              id: 'tmdMassRatio',
              name: 'TMD Mass Ratio (mt/M)',
              category: 'Damping System',
              min: 0.01,
              max: 0.08,
              step: 0.01,
              defaultValue: 0.04,
            ),
          ],
          presets: [
            SimPreset(
              id: 'resonant_without_tmd',
              name: 'Severe Resonance WITHOUT Damper',
              description: 'Catastrophic sway when earthquake frequency matches building natural frequency with TMD disabled.',
              parameters: {'earthquakeFreq': 1.2, 'enableTMD': false, 'groundAmplitude': 18.0},
            ),
            SimPreset(
              id: 'damped_resonance',
              name: 'Resonant Mitigation WITH TMD',
              description: 'Tuned mass damper oscillates in anti-phase, suppressing 75% of building sway.',
              parameters: {'earthquakeFreq': 1.2, 'enableTMD': true, 'groundAmplitude': 18.0},
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
    tmdDisplacement = 0.0;
    tmdVelocity = 0.0;
    for (int i = 0; i < floors; i++) {
      _floorDisplacements[i] = 0.0;
    }
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'earthquakeFreq') earthquakeFreq = (value as num).toDouble();
    if (paramId == 'groundAmplitude') groundAmplitude = (value as num).toDouble();
    if (paramId == 'enableTMD') enableTMD = value as bool;
    if (paramId == 'tmdMassRatio') tmdMassRatio = (value as num).toDouble();
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;

    final groundMotion = groundAmplitude * math.sin(2.0 * math.pi * earthquakeFreq * time);

    // Dynamic response: natural frequency of building fundamental mode is ~1.2 Hz
    final omegaNat = 2.0 * math.pi * 1.2;
    final omegaEarthquake = 2.0 * math.pi * earthquakeFreq;

    // Resonance amplification factor
    final r = omegaEarthquake / omegaNat;
    final denom = math.sqrt((1 - r * r) * (1 - r * r) + (2 * damping * r) * (2 * damping * r));
    var topSway = (groundAmplitude / (denom + 0.01)) * math.sin(omegaEarthquake * time - math.atan2(2 * damping * r, 1 - r * r));

    // TMD effect: counteracts top sway
    if (enableTMD) {
      topSway *= (0.28 / (1.0 + tmdMassRatio * 20.0));
      tmdVelocity += (topSway * 1.2 - tmdDisplacement * 0.8) * dt * 25.0;
      tmdDisplacement += tmdVelocity * dt;
    } else {
      tmdDisplacement = 0.0;
    }

    // Distribute sway along building height (parabolic cantilever deflection profile)
    for (int i = 0; i < floors; i++) {
      final h = (i + 1) / floors;
      _floorDisplacements[i] = topSway * (h * h) + groundMotion * 0.15;
    }
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {
        'displacements': List<double>.from(_floorDisplacements),
        'tmd': tmdDisplacement,
      },
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    final d = snapshot.state['displacements'] as List<double>;
    for (int i = 0; i < floors; i++) {
      _floorDisplacements[i] = d[i];
    }
    tmdDisplacement = snapshot.state['tmd'] as double;
  }

  @override
  Map<String, dynamic> getMetrics() {
    final topDrift = _floorDisplacements.last.abs();
    return {
      'Top Floor Drift (mm)': topDrift,
      'Seismic Frequency (Hz)': earthquakeFreq,
      'TMD Status': enableTMD ? 'ACTIVE' : 'OFF',
      'Structural Safety Margin': topDrift < 20.0 ? 'SAFE' : (topDrift < 35.0 ? 'WARNING' : 'CRITICAL'),
    };
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    const floorHeight = 16.0;
    const floorWidth = 45.0;
    const floorDepth = 45.0;

    // Foundation ground pad
    final groundMotion = groundAmplitude * math.sin(2.0 * math.pi * earthquakeFreq * time);
    _renderGroundPad(canvas, size, camera, groundMotion, theme);

    // Multi-story wireframe frame
    for (int i = 0; i < floors; i++) {
      final dx = _floorDisplacements[i];
      final y = i * floorHeight;

      final corners = [
        Vector3(dx - floorWidth / 2, y, -floorDepth / 2),
        Vector3(dx + floorWidth / 2, y, -floorDepth / 2),
        Vector3(dx + floorWidth / 2, y, floorDepth / 2),
        Vector3(dx - floorWidth / 2, y, floorDepth / 2),
      ];

      // Draw floor slab perimeter
      final slabPaint = Paint()
        ..color = (i == floors - 1 && enableTMD)
            ? theme.warning
            : (dx.abs() > 22.0 ? theme.danger : theme.accent)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;

      final path = Path();
      bool first = true;
      for (final c in corners) {
        final p = camera.projectVector(c, size);
        if (p != null) {
          if (first) {
            path.moveTo(p.screen.dx, p.screen.dy);
            first = false;
          } else {
            path.lineTo(p.screen.dx, p.screen.dy);
          }
        }
      }
      path.close();
      canvas.drawPath(path, slabPaint);

      // Draw vertical column struts connecting to floor below
      if (i > 0) {
        final prevDx = _floorDisplacements[i - 1];
        final prevY = (i - 1) * floorHeight;
        final prevCorners = [
          Vector3(prevDx - floorWidth / 2, prevY, -floorDepth / 2),
          Vector3(prevDx + floorWidth / 2, prevY, -floorDepth / 2),
          Vector3(prevDx + floorWidth / 2, prevY, floorDepth / 2),
          Vector3(prevDx - floorWidth / 2, prevY, floorDepth / 2),
        ];

        final colPaint = Paint()
          ..color = theme.textMuted.withValues(alpha: 0.6)
          ..strokeWidth = 1.4;

        for (int c = 0; c < 4; c++) {
          final topP = camera.projectVector(corners[c], size);
          final botP = camera.projectVector(prevCorners[c], size);
          if (topP != null && botP != null) {
            canvas.drawLine(topP.screen, botP.screen, colPaint);
          }
        }
      }
    }

    // Top-Floor Tuned Mass Damper Sphere
    if (enableTMD) {
      final topY = floors * floorHeight;
      final topDx = _floorDisplacements.last;
      final tmdPos = Vector3(topDx + tmdDisplacement, topY - 10.0, 0);

      // TMD suspension cable
      final pivot = camera.project(topDx, topY, 0, size);
      final sphereP = camera.projectVector(tmdPos, size);

      if (pivot != null && sphereP != null) {
        final cablePaint = Paint()
          ..color = theme.warning
          ..strokeWidth = 2.0;
        canvas.drawLine(pivot.screen, sphereP.screen, cablePaint);

        final spherePaint = Paint()..color = theme.warning;
        canvas.drawCircle(sphereP.screen, 8.0, spherePaint);
      }
    }
  }

  void _renderGroundPad(Canvas canvas, Size size, SimCamera3D camera, double groundMotion, SimTheme theme) {
    const padSize = 80.0;
    final corners = [
      Vector3(groundMotion - padSize / 2, -4, -padSize / 2),
      Vector3(groundMotion + padSize / 2, -4, -padSize / 2),
      Vector3(groundMotion + padSize / 2, -4, padSize / 2),
      Vector3(groundMotion - padSize / 2, -4, padSize / 2),
    ];

    final padPaint = Paint()
      ..color = theme.gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 4; i++) {
      final p1 = camera.projectVector(corners[i], size);
      final p2 = camera.projectVector(corners[(i + 1) % 4], size);
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1.screen, p2.screen, padPaint);
      }
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab Skyscraper Earthquake & Tuned Mass Damper (TMD) Simulation
omega_nat = 2 * pi * 1.2;
omega_eq = 2 * pi * $earthquakeFreq;
ground_amp = $groundAmplitude;
damping = $damping;

t = linspace(0, 20, 1000);
ground = ground_amp * sin(omega_eq * t);

% SDOF Building Transfer Function
r = omega_eq / omega_nat;
amp_factor = 1 ./ sqrt((1 - r.^2).^2 + (2*damping*r).^2);
sway = ground_amp * amp_factor * sin(omega_eq * t);

figure('Name', 'Building Seismic Response');
plot(t, ground, 'r--', 'LineWidth', 1.2); hold on;
plot(t, sway, 'b-', 'LineWidth', 1.5);
grid on; legend('Ground Motion', 'Top-Floor Sway');
title('High-Rise Vibration Dynamics');
''';
  }
}
