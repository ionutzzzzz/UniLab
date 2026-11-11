import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class AntennaPattern3DSim extends SimulationModel {
  String antennaType = 'Half-Wave Dipole (Donut)';
  double frequencyMhz = 2400.0; // 2.4 GHz
  double azimuthAngle = 0.0; // Steering
  double scale = 80.0;

  final List<Vector3> _meshVertices = [];
  final List<List<int>> _meshFaces = [];

  AntennaPattern3DSim()
      : super(
          id: 'electrical_antenna_pattern_3d',
          name: '3D Antenna Radiation Patterns (RF & Telecom)',
          description:
              '3D electromagnetic radiation far-field directivity patterns for RF antennas (half-wave dipole torus, Yagi-Uda directional beam, parabolic reflector dish) with beam steering.',
          category: SimCategory.electrical,
          dimension: SimDimension.threeD,
          tags: ['RF', '3D', 'Antenna', 'Electromagnetics', 'Telecom', 'Radiation Pattern'],
          parameters: [
            SimParameter(
              id: 'antennaType',
              name: 'Antenna Configuration',
              category: 'Antenna',
              type: SimParameterType.dropdown,
              options: [
                'Half-Wave Dipole (Donut)',
                'Yagi-Uda Directional Beam',
                'Parabolic Dish High-Gain',
                'Isotropic Radiator',
              ],
              defaultValue: 'Half-Wave Dipole (Donut)',
            ),
            SimParameter(
              id: 'frequencyMhz',
              name: 'Frequency (MHz)',
              category: 'RF Band',
              min: 400.0,
              max: 6000.0,
              step: 100.0,
              defaultValue: 2400.0,
            ),
            SimParameter(
              id: 'azimuthAngle',
              name: 'Beam Steering Azimuth',
              category: 'Steering',
              unit: '°',
              min: -90.0,
              max: 90.0,
              step: 5.0,
              defaultValue: 0.0,
            ),
          ],
          presets: [
            SimPreset(
              id: 'wifi_dipole',
              name: '2.4 GHz Wi-Fi Dipole Antenna',
              description: 'Omnidirectional toroidal radiation in horizontal plane with nulls at poles.',
              parameters: {'antennaType': 'Half-Wave Dipole (Donut)', 'frequencyMhz': 2400.0},
            ),
            SimPreset(
              id: 'radar_dish',
              name: 'High-Gain Directional Radar Dish',
              description: 'Narrow pencil beam with small side-lobes and high forward directivity.',
              parameters: {'antennaType': 'Parabolic Dish High-Gain', 'frequencyMhz': 5000.0},
            ),
          ],
        );

  @override
  void init() {
    _generateRadiationMesh();
  }

  @override
  void reset() {
    time = 0.0;
    stepIndex = 0;
    _generateRadiationMesh();
  }

  double _evalGain(double theta, double phi) {
    if (antennaType.contains('Dipole')) {
      // Half-wave dipole: cos(pi/2 * cos(theta)) / sin(theta)
      final sinT = math.sin(theta);
      if (sinT.abs() < 1e-4) return 0.0;
      final num = math.cos((math.pi / 2.0) * math.cos(theta));
      return (num / sinT).abs();
    } else if (antennaType.contains('Yagi') || antennaType.contains('Parabolic')) {
      // Highly directional main lobe in forward +Z direction
      final cosAngle = math.cos(theta) * math.cos(phi - azimuthAngle * math.pi / 180.0);
      final gain = math.pow(math.max(0.0, cosAngle), antennaType.contains('Parabolic') ? 6.0 : 3.0).toDouble();
      final sideLobe = 0.15 * math.sin(theta * 4.0).abs();
      return gain + sideLobe;
    } else {
      // Isotropic sphere
      return 0.8;
    }
  }

  void _generateRadiationMesh() {
    _meshVertices.clear();
    _meshFaces.clear();

    const uSteps = 20;
    const vSteps = 24;

    for (int i = 0; i <= uSteps; i++) {
      final theta = i * (math.pi / uSteps);
      for (int j = 0; j <= vSteps; j++) {
        final phi = j * (2.0 * math.pi / vSteps);
        final gain = _evalGain(theta, phi) * scale;

        final x = gain * math.sin(theta) * math.cos(phi);
        final y = gain * math.cos(theta);
        final z = gain * math.sin(theta) * math.sin(phi);

        _meshVertices.add(Vector3(x, y, z));
      }
    }
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'antennaType') {
      antennaType = value.toString();
      _generateRadiationMesh();
    }
    if (paramId == 'frequencyMhz') frequencyMhz = (value as num).toDouble();
    if (paramId == 'azimuthAngle') {
      azimuthAngle = (value as num).toDouble();
      _generateRadiationMesh();
    }
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(time: time, stepIndex: stepIndex, state: {}, metrics: getMetrics());
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
  }

  @override
  Map<String, num> getMetrics() {
    return {
      'Frequency (MHz)': frequencyMhz,
      'Wavelength (cm)': (3e8 / (frequencyMhz * 1e6)) * 100.0,
      'Peak Directivity Gain (dBi)': antennaType.contains('Parabolic') ? 24.5 : (antennaType.contains('Yagi') ? 14.2 : 2.15),
      'Beam Steering (deg)': azimuthAngle,
    };
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    // 1. Central Radiating Antenna Element (Metal Rod / Dish)
    final topP = camera.project(0, 35, 0, size);
    final botP = camera.project(0, -35, 0, size);
    if (topP != null && botP != null) {
      final elemPaint = Paint()
        ..color = theme.warning
        ..strokeWidth = 3.5;
      canvas.drawLine(topP.screen, botP.screen, elemPaint);
    }

    // 2. 3D Electromagnetic Gain Pattern Wireframe Lobe
    const vSteps = 24;
    final lobePaint = Paint()
      ..color = theme.accent.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    for (int i = 0; i < _meshVertices.length - vSteps - 1; i++) {
      final p1 = camera.projectVector(_meshVertices[i], size);
      final p2 = camera.projectVector(_meshVertices[i + 1], size);
      final p3 = camera.projectVector(_meshVertices[i + vSteps + 1], size);

      if (p1 != null && p2 != null) canvas.drawLine(p1.screen, p2.screen, lobePaint);
      if (p1 != null && p3 != null) canvas.drawLine(p1.screen, p3.screen, lobePaint);
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab 3D Antenna Far-Field Radiation Pattern
theta = linspace(0, pi, 100);
phi = linspace(0, 2*pi, 100);
[THETA, PHI] = meshgrid(theta, phi);

% Half-wave dipole directivity
U = (cos(pi/2 * cos(THETA)) ./ (sin(THETA) + 1e-6)).^2;

[X, Y, Z] = sph2cart(PHI, pi/2 - THETA, U);

figure('Name', '3D Antenna Far-Field Pattern');
surf(X, Y, Z, U);
colormap('jet'); axis equal; grid on; view(3);
title('Radiation Directivity |E(\\theta, \\phi)|');
''';
  }
}
