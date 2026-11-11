import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class BlochSphereQubit3DSim extends SimulationModel {
  double theta = math.pi / 2.0; // Polar angle [0, pi]
  double phi = 0.0; // Azimuthal angle [0, 2*pi]
  double rabiFrequency = 1.5; // rad/s
  double decoherenceRate = 0.02; // T1/T2 damping rate
  String gateMode = 'Free Evolution';
  bool showTrajectory = true;
  double radius = 100.0; // Bloch sphere radius

  final List<Vector3> _historyTrail = [];
  final int maxTrailLength = 220;

  BlochSphereQubit3DSim()
      : super(
          id: 'quantum_bloch_sphere_qubit_3d',
          name: '3D Quantum Bloch Sphere (Qubit Dynamics)',
          description:
              'Geometric representation of a two-level quantum qubit system |ψ⟩ = cos(θ/2)|0⟩ + e^(iφ)sin(θ/2)|1⟩, demonstrating unitary Pauli/Hadamard gates, Rabi driving, and decoherence damping.',
          category: SimCategory.physics,
          dimension: SimDimension.threeD,
          tags: ['Quantum Computing', 'Qubit', 'Bloch Sphere', 'Rabi Oscillations', 'Hadamard', 'Density Matrix'],
          parameters: [
            SimParameter(
              id: 'theta',
              name: 'Polar Angle (θ)',
              category: 'State Vector',
              unit: 'rad',
              min: 0.0,
              max: math.pi,
              step: 0.05,
              defaultValue: math.pi / 2.0,
            ),
            SimParameter(
              id: 'phi',
              name: 'Phase Angle (φ)',
              category: 'State Vector',
              unit: 'rad',
              min: 0.0,
              max: 2 * math.pi,
              step: 0.1,
              defaultValue: 0.0,
            ),
            SimParameter(
              id: 'rabiFrequency',
              name: 'Rabi Drive (Ω)',
              category: 'Hamiltonian',
              unit: 'rad/s',
              min: 0.0,
              max: 6.0,
              step: 0.2,
              defaultValue: 1.5,
            ),
            SimParameter(
              id: 'decoherenceRate',
              name: 'Decoherence (T₂ Damping)',
              category: 'Noise',
              min: 0.0,
              max: 0.15,
              step: 0.01,
              defaultValue: 0.02,
            ),
            SimParameter(
              id: 'gateMode',
              name: 'Quantum Operation',
              category: 'Evolution',
              type: SimParameterType.dropdown,
              options: ['Free Evolution', 'Rabi Drive', 'Hadamard Precession', 'Pauli-Z Phase Flip'],
              defaultValue: 'Free Evolution',
            ),
            SimParameter(
              id: 'showTrajectory',
              name: 'State Trajectory Ribbon',
              category: 'Visuals',
              type: SimParameterType.toggle,
              defaultValue: true,
            ),
          ],
          presets: [
            SimPreset(
              id: 'superposition',
              name: 'Equal Superposition |+⟩',
              description: 'Coherent 50/50 superposition along positive X axis: (|0⟩ + |1⟩)/√2.',
              parameters: {
                'theta': math.pi / 2.0,
                'phi': 0.0,
                'gateMode': 'Free Evolution',
                'decoherenceRate': 0.0,
              },
            ),
            SimPreset(
              id: 'rabi_flip',
              name: 'Driven Rabi Oscillations',
              description: 'Resonant microwave pulse driving continuous periodic state cycling between |0⟩ and |1⟩.',
              parameters: {
                'theta': 0.0,
                'phi': 0.0,
                'rabiFrequency': 2.4,
                'gateMode': 'Rabi Drive',
                'decoherenceRate': 0.01,
              },
            ),
            SimPreset(
              id: 'decohering_qubit',
              name: 'T2 Phase Decoherence Damping',
              description: 'Environmental noise causing dephasing and contraction into a classical mixed state.',
              parameters: {
                'theta': math.pi / 2.0,
                'phi': 0.0,
                'decoherenceRate': 0.08,
                'gateMode': 'Free Evolution',
              },
            ),
            SimPreset(
              id: 'hadamard_rot',
              name: 'Hadamard Gate Transformation',
              description: 'Pi rotation about the (X+Z)/√2 axis converting basis state |0⟩ to |+⟩.',
              parameters: {
                'theta': 0.0,
                'phi': 0.0,
                'gateMode': 'Hadamard Precession',
                'decoherenceRate': 0.0,
              },
            ),
          ],
        );

  @override
  void init() {
    time = 0.0;
    stepIndex = 0;
    _historyTrail.clear();
  }

  @override
  void reset() {
    time = 0.0;
    stepIndex = 0;
    _historyTrail.clear();
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'theta') {
      theta = (value as num).toDouble();
    } else if (paramId == 'phi') {
      phi = (value as num).toDouble();
    } else if (paramId == 'rabiFrequency') {
      rabiFrequency = (value as num).toDouble();
    } else if (paramId == 'decoherenceRate') {
      decoherenceRate = (value as num).toDouble();
    } else if (paramId == 'gateMode') {
      gateMode = value.toString();
    } else if (paramId == 'showTrajectory') {
      showTrajectory = value as bool;
    }
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;

    switch (gateMode) {
      case 'Rabi Drive':
        theta = (theta + rabiFrequency * dt) % (2 * math.pi);
        break;
      case 'Hadamard Precession':
        phi += 1.8 * dt;
        theta = math.pi / 4.0 + (math.pi / 4.0) * math.sin(time * 2.0);
        break;
      case 'Pauli-Z Phase Flip':
        phi = (phi + 3.2 * dt) % (2 * math.pi);
        break;
      case 'Free Evolution':
      default:
        phi = (phi + 0.8 * dt) % (2 * math.pi);
        break;
    }

    // Decoherence damping: theta drifts towards North pole (|0> ground state)
    if (decoherenceRate > 0.001) {
      theta = theta * math.exp(-decoherenceRate * dt * 0.5);
    }

    // Record 3D state vector position: x = r*sin(th)*cos(ph), y = r*cos(th), z = r*sin(th)*sin(ph)
    final stateVec = Vector3(
      radius * math.sin(theta) * math.cos(phi),
      radius * math.cos(theta),
      radius * math.sin(theta) * math.sin(phi),
    );

    _historyTrail.add(stateVec);
    if (_historyTrail.length > maxTrailLength) {
      _historyTrail.removeAt(0);
    }
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {
        'theta': theta,
        'phi': phi,
        'trail': List<Vector3>.from(_historyTrail),
      },
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    theta = snapshot.state['theta'] as double;
    phi = snapshot.state['phi'] as double;
    _historyTrail.clear();
    _historyTrail.addAll(snapshot.state['trail'] as List<Vector3>);
  }

  @override
  Map<String, dynamic> getMetrics() {
    final p0 = math.pow(math.cos(theta / 2.0), 2).toDouble();
    final p1 = math.pow(math.sin(theta / 2.0), 2).toDouble();
    final coherence = 2.0 * math.cos(theta / 2.0) * math.sin(theta / 2.0);

    return {
      'P(|0⟩) Ground Prob': (p0 * 100.0),
      'P(|1⟩) Excited Prob': (p1 * 100.0),
      'Quantum Coherence |ρ₀₁|': coherence.clamp(0.0, 1.0),
      'Purity Tr(ρ²)': 1.0 - 2.0 * p0 * p1 * (1.0 - math.exp(-decoherenceRate * time)),
      'State': p0 > 0.95 ? '|0⟩ GROUND' : (p1 > 0.95 ? '|1⟩ EXCITED' : 'SUPERPOSITION'),
    };
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    // 1. Draw 3D Bloch Sphere Wireframe Cage
    _renderBlochWireframe(canvas, size, camera, theme);

    // 2. Draw Quantum Coordinate Axes (X, Y, Z) and Pole Labels
    _renderQuantumAxes(canvas, size, camera, theme);

    // 3. Draw State History Ribbon Trail
    if (showTrajectory && _historyTrail.length > 1) {
      _renderTrajectoryTrail(canvas, size, camera, theme);
    }

    // 4. Draw Qubit State Vector Arrow |ψ⟩
    _renderStateVector(canvas, size, camera, theme);
  }

  void _renderBlochWireframe(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    final spherePaint = Paint()
      ..color = theme.accent.withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const segments = 36;

    // Equator Circle (Y = 0)
    final equatorPts = <Vector3>[];
    for (int i = 0; i <= segments; i++) {
      final a = i * (2 * math.pi / segments);
      equatorPts.add(Vector3(radius * math.cos(a), 0, radius * math.sin(a)));
    }
    _drawPolyline(canvas, size, camera, equatorPts, spherePaint);

    // Prime Meridian (Z = 0)
    final meridianPts = <Vector3>[];
    for (int i = 0; i <= segments; i++) {
      final a = i * (2 * math.pi / segments);
      meridianPts.add(Vector3(radius * math.cos(a), radius * math.sin(a), 0));
    }
    _drawPolyline(canvas, size, camera, meridianPts, spherePaint);

    // Orthogonal Meridian (X = 0)
    final orthoPts = <Vector3>[];
    for (int i = 0; i <= segments; i++) {
      final a = i * (2 * math.pi / segments);
      orthoPts.add(Vector3(0, radius * math.cos(a), radius * math.sin(a)));
    }
    _drawPolyline(canvas, size, camera, orthoPts, spherePaint);

    // Glowing equator fill disk
    final centerProj = camera.project(0, 0, 0, size);
    if (centerProj != null) {
      final dist = camera.eye.length;
      final screenRad = (radius * 380.0 / dist).clamp(20.0, 240.0);
      final glowPaint = Paint()
        ..color = theme.accent.withValues(alpha: 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
      canvas.drawCircle(centerProj.screen, screenRad, glowPaint);
    }
  }

  void _renderQuantumAxes(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    const axisLen = 135.0;

    // +Z Axis (|0>) and -Z Axis (|1>) -> Mapped to 3D Y axis for upright orientation
    _drawAxisWithLabel(canvas, size, camera, Vector3(0, -axisLen, 0), Vector3(0, axisLen, 0), '|1⟩', '|0⟩', const Color(0xFF00E5FF));

    // +X Axis (|+>) and -X Axis (|->)
    _drawAxisWithLabel(canvas, size, camera, Vector3(-axisLen, 0, 0), Vector3(axisLen, 0, 0), '|-⟩', '|+⟩', const Color(0xFFFF5252));

    // +Y Axis (|i>) and -Y Axis (|-i>)
    _drawAxisWithLabel(canvas, size, camera, Vector3(0, 0, -axisLen), Vector3(0, 0, axisLen), '|-i⟩', '|i⟩', const Color(0xFFFFD600));
  }

  void _drawAxisWithLabel(Canvas canvas, Size size, SimCamera3D camera, Vector3 pNeg, Vector3 pPos, String negLabel, String posLabel, Color axisColor) {
    final p1 = camera.projectVector(pNeg, size);
    final p2 = camera.projectVector(pPos, size);
    if (p1 == null || p2 == null) return;

    final axisPaint = Paint()
      ..color = axisColor.withValues(alpha: 0.45)
      ..strokeWidth = 1.2;
    canvas.drawLine(p1.screen, p2.screen, axisPaint);

    // Positive pole label
    final tpPos = TextPainter(
      text: TextSpan(
        text: posLabel,
        style: TextStyle(color: axisColor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpPos.paint(canvas, Offset(p2.screen.dx + 4, p2.screen.dy - 6));

    // Negative pole label
    final tpNeg = TextPainter(
      text: TextSpan(
        text: negLabel,
        style: TextStyle(color: axisColor.withValues(alpha: 0.7), fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpNeg.paint(canvas, Offset(p1.screen.dx + 4, p1.screen.dy - 6));
  }

  void _renderTrajectoryTrail(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    for (int i = 0; i < _historyTrail.length - 1; i++) {
      final p1 = camera.projectVector(_historyTrail[i], size);
      final p2 = camera.projectVector(_historyTrail[i + 1], size);
      if (p1 != null && p2 != null) {
        final progress = i / _historyTrail.length;
        final trailPaint = Paint()
          ..color = theme.secondaryAccent.withValues(alpha: progress * 0.75)
          ..strokeWidth = 1.0 + progress * 2.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(p1.screen, p2.screen, trailPaint);
      }
    }
  }

  void _renderStateVector(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    final originProj = camera.project(0, 0, 0, size);
    final tip = Vector3(
      radius * math.sin(theta) * math.cos(phi),
      radius * math.cos(theta),
      radius * math.sin(theta) * math.sin(phi),
    );
    final tipProj = camera.projectVector(tip, size);
    if (originProj == null || tipProj == null) return;

    // Glowing state vector shaft
    final glowPaint = Paint()
      ..color = theme.accent.withValues(alpha: 0.35)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawLine(originProj.screen, tipProj.screen, glowPaint);

    final shaftPaint = Paint()
      ..color = theme.accent
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(originProj.screen, tipProj.screen, shaftPaint);

    // Glowing Vector Arrow Head Sphere
    final tipSpherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.8,
        colors: [Colors.white, theme.accent, const Color(0xFF004D40)],
      ).createShader(Rect.fromCircle(center: tipProj.screen, radius: 7.0));
    canvas.drawCircle(tipProj.screen, 7.0, tipSpherePaint);

    // State Label |ψ⟩
    final tp = TextPainter(
      text: TextSpan(
        text: '|ψ⟩',
        style: TextStyle(
          color: theme.accent,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: theme.accent, blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(tipProj.screen.dx + 8, tipProj.screen.dy - 12));
  }

  void _drawPolyline(Canvas canvas, Size size, SimCamera3D camera, List<Vector3> pts, Paint paint) {
    for (int i = 0; i < pts.length - 1; i++) {
      final p1 = camera.projectVector(pts[i], size);
      final p2 = camera.projectVector(pts[i + 1], size);
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1.screen, p2.screen, paint);
      }
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab Quantum Bloch Sphere Simulation
theta = $theta;
phi = $phi;
Omega = $rabiFrequency;

% State vector components
psi_0 = cos(theta / 2);
psi_1 = exp(1i * phi) * sin(theta / 2);
psi = [psi_0; psi_1];

% Density matrix rho = psi * psi'
rho = psi * psi';

fprintf('State Vector: |psi> = %.3f |0> + (%.3f + %.3fi) |1>\\n', ...
    real(psi_0), real(psi_1), imag(psi_1));
fprintf('Ground State Probability P(|0>): %.2f%%\\n', abs(psi_0)^2 * 100);
fprintf('Excited State Probability P(|1>): %.2f%%\\n', abs(psi_1)^2 * 100);

figure('Name', 'Quantum Bloch Sphere');
title('Qubit State Vector |psi>');
xlabel('X (Re[<sigma_x>])'); ylabel('Y (Re[<sigma_y>])'); zlabel('Z (Re[<sigma_z>])');
grid on; axis equal; view(3);
''';
  }
}
