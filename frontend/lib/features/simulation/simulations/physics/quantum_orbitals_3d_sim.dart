import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class QuantumOrbitals3DSim extends SimulationModel {
  int n = 2; // Principal quantum number
  int l = 1; // Orbital angular momentum (0=s, 1=p, 2=d)
  int m = 0; // Magnetic quantum number
  double phaseSpeed = 1.0;
  double scale = 80.0;
  int sampleDensity = 1200;

  final List<Vector3> _points = [];
  final List<double> _densities = [];

  QuantumOrbitals3DSim()
      : super(
          id: 'physics_quantum_orbitals_3d',
          name: 'Quantum Electron Orbitals (3D Wavefunctions)',
          description:
              'Interactive 3D visualization of atomic hydrogen electron wavefunctions \$\\psi_{nlm}(r, \\theta, \\phi)\$ using spherical harmonics and radial Laguerre polynomials for s, p, and d orbitals.',
          category: SimCategory.physics,
          dimension: SimDimension.threeD,
          tags: ['Quantum Mechanics', '3D', 'Schrodinger', 'Atomic Orbitals', 'Hydrogen'],
          parameters: [
            SimParameter(
              id: 'orbitalType',
              name: 'Orbital Subshell',
              category: 'Quantum State',
              type: SimParameterType.dropdown,
              options: ['2p_z (Dumbbell)', '1s (Ground State)', '3d_z2 (Donut Ring)', '3d_xy (Cloverleaf)'],
              defaultValue: '2p_z (Dumbbell)',
            ),
            SimParameter(
              id: 'phaseSpeed',
              name: 'Quantum Phase Precession',
              category: 'Dynamics',
              min: 0.0,
              max: 3.0,
              step: 0.2,
              defaultValue: 1.0,
            ),
            SimParameter(
              id: 'sampleDensity',
              name: 'Probability Sample Cloud',
              category: 'Resolution',
              min: 400.0,
              max: 2000.0,
              step: 200.0,
              defaultValue: 1200.0,
            ),
          ],
          presets: [
            SimPreset(
              id: '2p_orbital',
              name: '2p_z Polar Dumbbell',
              description: 'Nodal plane at xy equator with positive/negative probability lobes.',
              parameters: {'orbitalType': '2p_z (Dumbbell)'},
            ),
            SimPreset(
              id: '3d_orbital',
              name: '3d_z2 Toroidal Ring',
              description: 'Complex cloverleaf lobes with a central toroidal ring.',
              parameters: {'orbitalType': '3d_z2 (Donut Ring)'},
            ),
            SimPreset(
              id: '1s_ground',
              name: '1s Spherically Symmetric',
              description: 'Exponential radial decay with spherical symmetry.',
              parameters: {'orbitalType': '1s (Ground State)'},
            ),
          ],
        );

  @override
  void init() {
    _generatePointDistribution();
  }

  @override
  void reset() {
    time = 0.0;
    stepIndex = 0;
    _generatePointDistribution();
  }

  void _generatePointDistribution() {
    _points.clear();
    _densities.clear();

    final rng = math.Random(42);
    final count = sampleDensity;

    for (int i = 0; i < count; i++) {
      // Rejection sampling for orbital probability distribution
      final theta = rng.nextDouble() * math.pi;
      final phi = rng.nextDouble() * 2.0 * math.pi;
      final r = math.pow(rng.nextDouble(), 0.5) * 2.4;

      // Hydrogen orbital angular wavefunction calculation
      double yVal = 0.0;
      if (l == 0) {
        // 1s
        yVal = 1.0 / (2.0 * math.sqrt(math.pi));
      } else if (l == 1) {
        // 2p_z: cos(theta)
        yVal = math.sqrt(3.0 / (4.0 * math.pi)) * math.cos(theta);
      } else if (l == 2 && m == 0) {
        // 3d_z2: 3*cos^2(theta) - 1
        yVal = math.sqrt(5.0 / (16.0 * math.pi)) * (3.0 * math.cos(theta) * math.cos(theta) - 1.0);
      } else {
        // 3d_xy: sin^2(theta)*sin(2phi)
        yVal = math.sqrt(15.0 / (16.0 * math.pi)) * math.sin(theta) * math.sin(theta) * math.sin(2.0 * phi);
      }

      // Radial decay
      final rVal = math.exp(-r);
      final prob = yVal * yVal * rVal * rVal;

      if (rng.nextDouble() < prob * 3.5) {
        final x = r * scale * math.sin(theta) * math.cos(phi);
        final y = r * scale * math.cos(theta);
        final z = r * scale * math.sin(theta) * math.sin(phi);
        _points.add(Vector3(x, y, z));
        _densities.add(yVal >= 0 ? 1.0 : -1.0);
      }
    }
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'orbitalType') {
      final s = value.toString();
      if (s.contains('1s')) {
        n = 1; l = 0; m = 0;
      } else if (s.contains('2p')) {
        n = 2; l = 1; m = 0;
      } else if (s.contains('3d_z2')) {
        n = 3; l = 2; m = 0;
      } else if (s.contains('3d_xy')) {
        n = 3; l = 2; m = 2;
      }
      _generatePointDistribution();
    }
    if (paramId == 'phaseSpeed') phaseSpeed = (value as num).toDouble();
    if (paramId == 'sampleDensity') {
      sampleDensity = (value as num).toInt();
      _generatePointDistribution();
    }
  }

  @override
  void step(double dt) {
    time += dt * phaseSpeed;
    stepIndex++;
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {'time': time},
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
  }

  @override
  Map<String, num> getMetrics() {
    return {
      'Quantum Number n': n,
      'Angular Momentum l': l,
      'Magnetic Number m': m,
      'Sampled Cloud Points': _points.length,
    };
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    // Nucleus
    final nucleusProj = camera.project(0, 0, 0, size);
    if (nucleusProj != null) {
      final nucPaint = Paint()..color = const Color(0xFFFFD600);
      canvas.drawCircle(nucleusProj.screen, 5.0, nucPaint);
    }

    // 3D Orbital Point Cloud with phase wave modulation
    final phaseCos = math.cos(time * 2.0);

    for (int i = 0; i < _points.length; i++) {
      final pt = _points[i];
      final proj = camera.projectVector(pt, size);
      if (proj == null) continue;

      final sign = _densities[i];
      // Positive phase lobe in cyan, negative phase lobe in magenta/gold
      final baseColor = sign > 0 ? theme.accent : const Color(0xFFE040FB);
      final alpha = (0.35 + 0.35 * (sign * phaseCos)).clamp(0.1, 0.85);

      final pPaint = Paint()
        ..color = baseColor.withValues(alpha: alpha)
        ..strokeWidth = 2.5;

      canvas.drawCircle(proj.screen, 1.8, pPaint);
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab 3D Quantum Electron Wavefunction (Hydrogen Atom)
n = $n; l = $l; m = $m;
[X, Y, Z] = meshgrid(linspace(-5, 5, 40));
[theta, phi, r] = cart2sph(X, Y, Z);
theta = pi/2 - theta; % Convert elevation to polar angle

% Hydrogen orbital calculation
R = exp(-r);
Y_lm = cos(theta);
Psi = R .* Y_lm;

figure('Name', 'Hydrogen Orbital 3D Isosurface');
isosurface(X, Y, Z, Psi.^2, 0.05);
colormap('parula'); axis equal; grid on; view(3);
title('Electron Probability Density |\\psi|^2');
''';
  }
}
