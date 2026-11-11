import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';

class ChladniSandParticle {
  double x; // Normalized [-1.0, 1.0]
  double y; // Normalized [-1.0, 1.0]
  double vx;
  double vy;
  final Color color;
  final double radius;

  ChladniSandParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.radius,
  });

  ChladniSandParticle copy() {
    return ChladniSandParticle(
      x: x,
      y: y,
      vx: vx,
      vy: vy,
      color: color,
      radius: radius,
    );
  }
}

class ChladniCymaticsSim extends SimulationModel {
  int modeM = 3;
  int modeN = 2;
  double driveAmplitude = 1.8;
  double plateDamping = 0.85;
  int particleCount = 850;
  bool showNodalHeatmap = true;

  final List<ChladniSandParticle> _particles = [];

  ChladniCymaticsSim()
      : super(
          id: 'acoustics_chladni_cymatics',
          name: '2D Chladni Resonance & Cymatics (Acoustic Eigenmodes)',
          description:
              'Granular sand dynamics on a resonant plate driven by acoustic eigenmode frequencies, demonstrating nodal line self-organization w(x,y) = a·cos(mπx/L)cos(nπy/L) - b·cos(nπx/L)cos(mπy/L) = 0.',
          category: SimCategory.physics,
          dimension: SimDimension.twoD,
          tags: ['Acoustics', 'Cymatics', 'Chladni Plate', 'Eigenmodes', 'Vibrations', 'Biharmonic Equation', 'Self-Organization'],
          parameters: [
            SimParameter(
              id: 'modeM',
              name: 'Harmonic Mode (m)',
              category: 'Resonance',
              min: 1.0,
              max: 8.0,
              step: 1.0,
              defaultValue: 3.0,
            ),
            SimParameter(
              id: 'modeN',
              name: 'Harmonic Mode (n)',
              category: 'Resonance',
              min: 1.0,
              max: 8.0,
              step: 1.0,
              defaultValue: 2.0,
            ),
            SimParameter(
              id: 'driveAmplitude',
              name: 'Vibrational Drive Power',
              category: 'Excitation',
              min: 0.2,
              max: 4.0,
              step: 0.2,
              defaultValue: 1.8,
            ),
            SimParameter(
              id: 'plateDamping',
              name: 'Frictional Damping',
              category: 'Material',
              min: 0.5,
              max: 0.98,
              step: 0.02,
              defaultValue: 0.85,
            ),
            SimParameter(
              id: 'particleCount',
              name: 'Sand Grain Count',
              category: 'Simulation',
              min: 300.0,
              max: 1400.0,
              step: 100.0,
              defaultValue: 850.0,
            ),
            SimParameter(
              id: 'showNodalHeatmap',
              name: 'Modal Heatmap Overlay',
              category: 'Visuals',
              type: SimParameterType.toggle,
              defaultValue: true,
            ),
          ],
          presets: [
            SimPreset(
              id: 'classic_cross',
              name: 'Classic Cross & Rings (m=2, n=1)',
              description: 'Fundamental Chladni pattern with distinct intersecting nodal lines and peripheral arcs.',
              parameters: {'modeM': 2.0, 'modeN': 1.0, 'driveAmplitude': 1.8},
            ),
            SimPreset(
              id: 'ornate_star',
              name: 'Ornate Star Cymatics (m=5, n=3)',
              description: 'High-order symmetry producing interlocking geometric nodal rosettes.',
              parameters: {'modeM': 5.0, 'modeN': 3.0, 'driveAmplitude': 2.2},
            ),
            SimPreset(
              id: 'flower_matrix',
              name: 'Resonant Lattice Flower (m=6, n=5)',
              description: 'High frequency harmonic pattern creating intricate checkerboard cymatic mandalas.',
              parameters: {'modeM': 6.0, 'modeN': 5.0, 'driveAmplitude': 2.4},
            ),
            SimPreset(
              id: 'concentric_boxes',
              name: 'Concentric Diamond Rings (m=3, n=3)',
              description: 'Diagonal and central quadrant nodal boundaries forming geometric diamonds.',
              parameters: {'modeM': 3.0, 'modeN': 3.0, 'driveAmplitude': 1.5},
            ),
          ],
        );

  @override
  void init() {
    time = 0.0;
    stepIndex = 0;
    _initializeSand();
  }

  @override
  void reset() {
    time = 0.0;
    stepIndex = 0;
    _initializeSand();
  }

  void _initializeSand() {
    _particles.clear();
    final random = math.Random(101);
    final count = particleCount.clamp(200, 1600);

    for (int i = 0; i < count; i++) {
      final x = (random.nextDouble() * 2.0 - 1.0) * 0.95;
      final y = (random.nextDouble() * 2.0 - 1.0) * 0.95;

      // Natural silica grain shades (light amber, quartz white, dark gold)
      final grainChoice = random.nextDouble();
      Color grainColor;
      if (grainChoice > 0.6) {
        grainColor = const Color(0xFFFFF8E1); // Bright quartz sand
      } else if (grainChoice > 0.3) {
        grainColor = const Color(0xFFFFD54F); // Golden amber
      } else {
        grainColor = const Color(0xFFFFB300); // Deep silica
      }

      _particles.add(ChladniSandParticle(
        x: x,
        y: y,
        vx: 0.0,
        vy: 0.0,
        color: grainColor,
        radius: 1.2 + random.nextDouble() * 1.0,
      ));
    }
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'modeM') {
      modeM = (value as num).toInt();
    } else if (paramId == 'modeN') {
      modeN = (value as num).toInt();
    } else if (paramId == 'driveAmplitude') {
      driveAmplitude = (value as num).toDouble();
    } else if (paramId == 'plateDamping') {
      plateDamping = (value as num).toDouble();
    } else if (paramId == 'particleCount') {
      particleCount = (value as num).toInt();
      _initializeSand();
    } else if (paramId == 'showNodalHeatmap') {
      showNodalHeatmap = value as bool;
    }
  }

  // Chladni modal displacement w(x,y)
  double _evalW(double x, double y) {
    final term1 = math.cos(modeM * math.pi * x * 0.5) * math.cos(modeN * math.pi * y * 0.5);
    final term2 = math.cos(modeN * math.pi * x * 0.5) * math.cos(modeM * math.pi * y * 0.5);
    return term1 - term2;
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;

    final random = math.Random(stepIndex);
    const eps = 0.015;

    for (final p in _particles) {
      final w = _evalW(p.x, p.y);
      final absW = w.abs();

      // If particle is on an antinode (absW > 0), it is kicked along negative gradient -grad(|w|)
      if (absW > 0.02) {
        // Numerical gradient of |w|
        final wx = _evalW(p.x + eps, p.y).abs() - _evalW(p.x - eps, p.y).abs();
        final wy = _evalW(p.x, p.y + eps).abs() - _evalW(p.x, p.y - eps).abs();
        final gradX = wx / (2.0 * eps);
        final gradY = wy / (2.0 * eps);

        // Force towards nodal line + random thermal jitter when kicked into air
        final jitterX = (random.nextDouble() - 0.5) * 0.15;
        final jitterY = (random.nextDouble() - 0.5) * 0.15;

        final forceMagnitude = absW * driveAmplitude * 3.5;
        p.vx -= (gradX * forceMagnitude + jitterX) * dt * 4.0;
        p.vy -= (gradY * forceMagnitude + jitterY) * dt * 4.0;
      }

      // Apply friction damping
      p.vx *= plateDamping;
      p.vy *= plateDamping;

      p.x += p.vx * dt * 5.0;
      p.y += p.vy * dt * 5.0;

      // Keep within plate bounds [-0.96, 0.96]
      if (p.x < -0.96) {
        p.x = -0.96;
        p.vx = -p.vx * 0.5;
      } else if (p.x > 0.96) {
        p.x = 0.96;
        p.vx = -p.vx * 0.5;
      }
      if (p.y < -0.96) {
        p.y = -0.96;
        p.vy = -p.vy * 0.5;
      } else if (p.y > 0.96) {
        p.y = 0.96;
        p.vy = -p.vy * 0.5;
      }
    }
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {
        'particles': _particles.map((p) => p.copy()).toList(),
      },
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    final saved = snapshot.state['particles'] as List<ChladniSandParticle>;
    _particles.clear();
    for (final p in saved) {
      _particles.add(p.copy());
    }
  }

  @override
  Map<String, dynamic> getMetrics() {
    double totalKineticEnergy = 0.0;
    int settledGrains = 0;

    for (final p in _particles) {
      final speed = math.sqrt(p.vx * p.vx + p.vy * p.vy);
      totalKineticEnergy += speed * speed;
      if (speed < 0.02 && _evalW(p.x, p.y).abs() < 0.08) {
        settledGrains++;
      }
    }

    final modalFreq = (math.pow(modeM, 2) + math.pow(modeN, 2)) * 145.0; // Estimated Hz

    return {
      'Resonant Frequency (Hz)': modalFreq,
      'Modal Eigenvalue (m²+n²)': (modeM * modeM + modeN * modeN),
      'Settled Sand Ratio': '${((settledGrains / math.max(1, _particles.length)) * 100.0).toStringAsFixed(1)}%',
      'Plate Kinetic Energy': totalKineticEnergy * 100.0,
      'Nodal Alignment': settledGrains > _particles.length * 0.65 ? 'CRISP HARMONIC' : 'DYNAMIC MIGRATION',
    };
  }

  @override
  void render2D(Canvas canvas, Size size, SimTheme theme) {
    // Determine plate size dynamically from viewport dimensions
    final plateSide = math.min(size.width, size.height) * 0.82;
    final halfSide = plateSide * 0.5;
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final plateRect = Rect.fromCenter(center: center, width: plateSide, height: plateSide);

    // 1. Draw Resonant Steel Plate Surface
    final platePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.panelBackground,
          const Color(0xFF1E293B),
          theme.panelBackground,
        ],
      ).createShader(plateRect);

    final plateRRect = RRect.fromRectAndRadius(plateRect, const Radius.circular(8.0));
    canvas.drawRRect(plateRRect, platePaint);

    // Metallic Plate Border & Screws
    final borderPaint = Paint()
      ..color = theme.accent.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(plateRRect, borderPaint);

    // 2. Modal Heatmap Overlay (Optional)
    if (showNodalHeatmap) {
      _renderHeatmapOverlay(canvas, center, halfSide, theme);
    }

    // 3. Central Transducer Driver Exciter Node
    final exciterPaint = Paint()..color = theme.accent;
    canvas.drawCircle(center, 7.0, exciterPaint);
    canvas.drawCircle(center, 12.0, borderPaint);

    // 4. Render Sand Grain Particles
    for (final p in _particles) {
      final screenX = center.dx + p.x * halfSide;
      final screenY = center.dy + p.y * halfSide;

      final pPaint = Paint()..color = p.color;
      canvas.drawCircle(Offset(screenX, screenY), p.radius, pPaint);
    }
  }

  void _renderHeatmapOverlay(Canvas canvas, Offset center, double halfSide, SimTheme theme) {
    final nodalLinePaint = Paint()
      ..color = theme.accent.withValues(alpha: 0.12)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const grid = 36;

    for (int i = 0; i < grid; i++) {
      final normY = (i / grid) * 2.0 - 1.0;
      for (int j = 0; j < grid; j++) {
        final normX = (j / grid) * 2.0 - 1.0;
        final w = _evalW(normX, normY);

        // Near nodal line w ~ 0
        if (w.abs() < 0.08) {
          final px = center.dx + normX * halfSide;
          final py = center.dy + normY * halfSide;
          canvas.drawCircle(Offset(px, py), 1.6, nodalLinePaint);
        }
      }
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab 2D Chladni Resonant Plate Cymatics
m = $modeM;
n = $modeN;
L = 1.0; % Normalized plate length

% 2D Grid
[X, Y] = meshgrid(linspace(-L, L, 300), linspace(-L, L, 300));

% Chladni modal displacement function
W = cos(m * pi * X / 2) .* cos(n * pi * Y / 2) - cos(n * pi * X / 2) .* cos(m * pi * Y / 2);

figure('Name', 'Chladni Nodal Cymatic Pattern');
contour(X, Y, W, [0 0], 'k-', 'LineWidth', 2);
title(sprintf('Chladni Resonance Modal Pattern (m=%d, n=%d)', m, n));
xlabel('X'); ylabel('Y');
axis square; grid on;
''';
  }
}
