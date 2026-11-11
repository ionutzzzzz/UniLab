import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';

class DoublePendulumSim extends SimulationModel {
  double l1 = 120.0;
  double l2 = 100.0;
  double m1 = 2.0;
  double m2 = 1.5;
  double g = 9.81;
  double damping = 0.002;
  int maxTrailLength = 300;

  double theta1 = math.pi / 2.0;
  double theta2 = math.pi / 2.0;
  double omega1 = 0.0;
  double omega2 = 0.0;

  final List<Offset> _trail = [];

  DoublePendulumSim()
      : super(
          id: 'physics_double_pendulum',
          name: 'Double Pendulum (Chaos & Dynamics)',
          description:
              'Coupled nonlinear differential equations exhibiting deterministic chaos, kinetic/potential energy conservation, and fractal phase portrait trajectories.',
          category: SimCategory.physics,
          dimension: SimDimension.twoD,
          tags: ['Chaos', 'Lagrangian', 'RK4', 'Phase Space', 'Energy'],
          parameters: [
            SimParameter(
              id: 'l1',
              name: 'Upper Length (L1)',
              category: 'Geometry',
              unit: 'px',
              min: 50.0,
              max: 200.0,
              step: 5.0,
              defaultValue: 120.0,
            ),
            SimParameter(
              id: 'l2',
              name: 'Lower Length (L2)',
              category: 'Geometry',
              unit: 'px',
              min: 50.0,
              max: 200.0,
              step: 5.0,
              defaultValue: 100.0,
            ),
            SimParameter(
              id: 'm1',
              name: 'Upper Mass (m1)',
              category: 'Masses',
              unit: 'kg',
              min: 0.5,
              max: 10.0,
              step: 0.5,
              defaultValue: 2.0,
            ),
            SimParameter(
              id: 'm2',
              name: 'Lower Mass (m2)',
              category: 'Masses',
              unit: 'kg',
              min: 0.5,
              max: 10.0,
              step: 0.5,
              defaultValue: 1.5,
            ),
            SimParameter(
              id: 'g',
              name: 'Gravity (g)',
              category: 'Environment',
              unit: 'm/s²',
              min: 0.0,
              max: 25.0,
              step: 0.5,
              defaultValue: 9.81,
            ),
            SimParameter(
              id: 'damping',
              name: 'Air Drag Damping',
              category: 'Environment',
              min: 0.0,
              max: 0.05,
              step: 0.001,
              defaultValue: 0.002,
            ),
          ],
          presets: [
            SimPreset(
              id: 'chaotic_flip',
              name: 'Chaotic High-Energy Flip',
              description: 'Initial angles near upright inversion producing high-energy chaotic tumbling.',
              parameters: {'l1': 120.0, 'l2': 100.0, 'm1': 2.0, 'm2': 1.5, 'g': 9.81, 'damping': 0.001},
            ),
            SimPreset(
              id: 'harmonic_small',
              name: 'Harmonic Small Angle Mode',
              description: 'Small perturbation near equilibrium showing coupled harmonic resonance.',
              parameters: {'l1': 130.0, 'l2': 110.0, 'm1': 3.0, 'm2': 1.0, 'g': 9.81, 'damping': 0.005},
            ),
            SimPreset(
              id: 'zero_gravity',
              name: 'Zero-G Orbital Gyration',
              description: 'Zero gravity rotation driven solely by centrifugal and Coriolis moments.',
              parameters: {'l1': 100.0, 'l2': 100.0, 'm1': 2.0, 'm2': 2.0, 'g': 0.0, 'damping': 0.0},
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
    theta1 = math.pi / 2.0;
    theta2 = math.pi / 2.0;
    omega1 = 0.0;
    omega2 = 0.0;
    _trail.clear();
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'l1') l1 = (value as num).toDouble();
    if (paramId == 'l2') l2 = (value as num).toDouble();
    if (paramId == 'm1') m1 = (value as num).toDouble();
    if (paramId == 'm2') m2 = (value as num).toDouble();
    if (paramId == 'g') g = (value as num).toDouble();
    if (paramId == 'damping') damping = (value as num).toDouble();
  }

  @override
  void step(double dt) {
    // Sub-stepping with 4th-order Runge-Kutta for numerical energy stability
    final subSteps = 4;
    final h = (dt / subSteps).clamp(0.0001, 0.05);

    for (int s = 0; s < subSteps; s++) {
      _rk4Step(h);
    }

    time += dt;
    stepIndex++;

    // Calculate end effector position for trajectory trail
    final x1 = l1 * math.sin(theta1);
    final y1 = l1 * math.cos(theta1);
    final x2 = x1 + l2 * math.sin(theta2);
    final y2 = y1 + l2 * math.cos(theta2);

    _trail.add(Offset(x2, y2));
    if (_trail.length > maxTrailLength) {
      _trail.removeAt(0);
    }
  }

  void _rk4Step(double h) {
    // Derivatives evaluation helper: [dtheta1/dt, dtheta2/dt, domega1/dt, domega2/dt]
    List<double> derivatives(double t1, double t2, double w1, double w2) {
      final delta = t1 - t2;
      final den1 = l1 * (2 * m1 + m2 - m2 * math.cos(2 * t1 - 2 * t2));
      final den2 = l2 * (2 * m1 + m2 - m2 * math.cos(2 * t1 - 2 * t2));

      final num1 = -g * (2 * m1 + m2) * math.sin(t1) -
          m2 * g * math.sin(t1 - 2 * t2) -
          2 * math.sin(delta) * m2 * (w2 * w2 * l2 + w1 * w1 * l1 * math.cos(delta));

      final num2 = 2 * math.sin(delta) *
          (w1 * w1 * l1 * (m1 + m2) +
              g * (m1 + m2) * math.cos(t1) +
              w2 * w2 * l2 * m2 * math.cos(delta));

      final alpha1 = (num1 / den1) - damping * w1;
      final alpha2 = (num2 / den2) - damping * w2;

      return [w1, w2, alpha1, alpha2];
    }

    final k1 = derivatives(theta1, theta2, omega1, omega2);
    final k2 = derivatives(
      theta1 + 0.5 * h * k1[0],
      theta2 + 0.5 * h * k1[1],
      omega1 + 0.5 * h * k1[2],
      omega2 + 0.5 * h * k1[3],
    );
    final k3 = derivatives(
      theta1 + 0.5 * h * k2[0],
      theta2 + 0.5 * h * k2[1],
      omega1 + 0.5 * h * k2[2],
      omega2 + 0.5 * h * k2[3],
    );
    final k4 = derivatives(
      theta1 + h * k3[0],
      theta2 + h * k3[1],
      omega1 + h * k3[2],
      omega2 + h * k3[3],
    );

    theta1 += (h / 6.0) * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]);
    theta2 += (h / 6.0) * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1]);
    omega1 += (h / 6.0) * (k1[2] + 2 * k2[2] + 2 * k3[2] + k4[2]);
    omega2 += (h / 6.0) * (k1[3] + 2 * k2[3] + 2 * k3[3] + k4[3]);
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {
        'theta1': theta1,
        'theta2': theta2,
        'omega1': omega1,
        'omega2': omega2,
        'trail': List<Offset>.from(_trail),
      },
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    theta1 = snapshot.state['theta1'] as double;
    theta2 = snapshot.state['theta2'] as double;
    omega1 = snapshot.state['omega1'] as double;
    omega2 = snapshot.state['omega2'] as double;
    _trail.clear();
    if (snapshot.state['trail'] != null) {
      _trail.addAll(snapshot.state['trail'] as List<Offset>);
    }
  }

  @override
  Map<String, num> getMetrics() {
    // Kinetic & potential energy
    final v1sq = (l1 * omega1) * (l1 * omega1);
    final v2sq = v1sq +
        (l2 * omega2) * (l2 * omega2) +
        2 * l1 * l2 * omega1 * omega2 * math.cos(theta1 - theta2);

    final ke = 0.5 * m1 * v1sq + 0.5 * m2 * v2sq;
    final pe = -(m1 + m2) * g * l1 * math.cos(theta1) - m2 * g * l2 * math.cos(theta2);
    final totalEnergy = ke + pe;

    return {
      'Kinetic Energy (J)': ke,
      'Potential Energy (J)': pe,
      'Total Mechanical Energy (J)': totalEnergy,
      'Omega 1 (rad/s)': omega1,
      'Omega 2 (rad/s)': omega2,
    };
  }

  @override
  void render2D(Canvas canvas, Size size, SimTheme theme) {
    final origin = Offset(size.width / 2.0, size.height * 0.36);
    // Responsive dynamic rod scaling proportional to viewport height
    final scaleL = (size.height * 0.22) / 120.0;
    final renderL1 = l1 * scaleL;
    final renderL2 = l2 * scaleL;

    // Coordinate transformations
    final p1 = Offset(origin.dx + renderL1 * math.sin(theta1), origin.dy + renderL1 * math.cos(theta1));
    final p2 = Offset(p1.dx + renderL2 * math.sin(theta2), p1.dy + renderL2 * math.cos(theta2));

    // Draw Grid & Axes
    final gridPaint = Paint()
      ..color = theme.gridColor
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(origin.dx, 0), Offset(origin.dx, size.height), gridPaint);
    canvas.drawLine(Offset(0, origin.dy), Offset(size.width, origin.dy), gridPaint);

    // Draw Glowing Trajectory Trail
    if (_trail.length > 1) {
      for (int i = 0; i < _trail.length - 1; i++) {
        final progress = i / _trail.length;
        final start = Offset(origin.dx + _trail[i].dx * scaleL, origin.dy + _trail[i].dy * scaleL);
        final end = Offset(origin.dx + _trail[i + 1].dx * scaleL, origin.dy + _trail[i + 1].dy * scaleL);

        final trailPaint = Paint()
          ..color = theme.accent.withValues(alpha: progress * 0.85)
          ..strokeWidth = 1.0 + progress * 2.2
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(start, end, trailPaint);
      }
    }

    // Upper Metallic Rod
    final rodPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white, const Color(0xFFB0BEC5), const Color(0xFF37474F)],
      ).createShader(Rect.fromPoints(origin, p1))
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(origin, p1, rodPaint);

    // Lower Metallic Rod
    final rod2Paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white, const Color(0xFFB0BEC5), const Color(0xFF37474F)],
      ).createShader(Rect.fromPoints(p1, p2))
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p2, rod2Paint);

    // Base pivot (brass bearing)
    final pivotPaint = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawCircle(origin, 7.0, pivotPaint);
    canvas.drawCircle(origin, 3.5, Paint()..color = const Color(0xFF263238));

    // Upper Bob (Metallic Brass Sphere)
    final r1 = (8.0 + m1 * 2.0).clamp(6.0, 28.0);
    final bob1Paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: [Colors.white, theme.accent, const Color(0xFF00363A)],
      ).createShader(Rect.fromCircle(center: p1, radius: r1));
    canvas.drawCircle(p1, r1, bob1Paint);

    // Lower Bob (Glow + Sphere)
    final r2 = (10.0 + m2 * 2.0).clamp(8.0, 32.0);
    final glowPaint = Paint()
      ..color = theme.accent.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawCircle(p2, r2 * 1.5, glowPaint);

    final bob2Paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: [Colors.white, const Color(0xFFFFB300), const Color(0xFFBF360C)],
      ).createShader(Rect.fromCircle(center: p2, radius: r2));
    canvas.drawCircle(p2, r2, bob2Paint);

    // Phase Space Portrait Inset (Top Right)
    _renderPhaseSpaceInset(canvas, size, theme);

    // Draw energy telemetry bar at bottom left
    _renderEnergyBar(canvas, size, theme);
  }

  void _renderPhaseSpaceInset(Canvas canvas, Size size, SimTheme theme) {
    const insetWidth = 120.0;
    const insetHeight = 90.0;
    final insetLeft = size.width - insetWidth - 16.0;
    const insetTop = 16.0;
    final insetRect = Rect.fromLTWH(insetLeft, insetTop, insetWidth, insetHeight);

    final bgPaint = Paint()..color = theme.panelBackground.withValues(alpha: 0.85);
    final borderPaint = Paint()
      ..color = theme.gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(RRect.fromRectAndRadius(insetRect, const Radius.circular(5)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(insetRect, const Radius.circular(5)), borderPaint);

    // Phase point (theta1, omega1)
    final cx = insetLeft + insetWidth * 0.5;
    final cy = insetTop + insetHeight * 0.5;
    final px = cx + (theta1 % (2 * math.pi) - math.pi) * (insetWidth * 0.14);
    final py = cy - (omega1.clamp(-12.0, 12.0)) * (insetHeight * 0.035);

    canvas.drawCircle(Offset(px, py), 3.0, Paint()..color = theme.accent);

    final tp = TextPainter(
      text: TextSpan(
        text: 'Phase (θ₁, ω₁)',
        style: TextStyle(color: theme.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(insetLeft + 6, insetTop + 4));
  }

  void _renderEnergyBar(Canvas canvas, Size size, SimTheme theme) {
    final metrics = getMetrics();
    final ke = metrics['Kinetic Energy (J)'] ?? 0.0;
    final pe = metrics['Potential Energy (J)'] ?? 0.0;

    final barLeft = 24.0;
    final barBottom = size.height - 24.0;
    final barWidth = 180.0;
    final barHeight = 12.0;

    final total = math.max(10.0, ke.abs() + pe.abs());
    final keFrac = (ke.abs() / total).clamp(0.0, 1.0);

    // Background
    final bgPaint = Paint()..color = theme.panelBackground;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barBottom - barHeight, barWidth, barHeight),
        const Radius.circular(4),
      ),
      bgPaint,
    );

    // KE Segment
    final kePaint = Paint()..color = theme.accent;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barBottom - barHeight, barWidth * keFrac, barHeight),
        const Radius.circular(4),
      ),
      kePaint,
    );

    // Label
    final tp = TextPainter(
      text: TextSpan(
        text: 'KE: ${(keFrac * 100).toStringAsFixed(0)}%  PE: ${((1 - keFrac) * 100).toStringAsFixed(0)}%',
        style: TextStyle(color: theme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(barLeft, barBottom - barHeight - 16));
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab Double Pendulum Simulation (Lagrangian RK4 Dynamics)
% Parameters
L1 = $l1; L2 = $l2; m1 = $m1; m2 = $m2; g = $g; damping = $damping;

tspan = [0 20];
y0 = [pi/2; pi/2; 0; 0]; % [theta1, theta2, omega1, omega2]

[t, y] = ode45(@(t, y) double_pendulum_ode(t, y, L1, L2, m1, m2, g, damping), tspan, y0);

figure('Name', 'Double Pendulum Trajectory');
x1 = L1 * sin(y(:, 1));
y1 = -L1 * cos(y(:, 1));
x2 = x1 + L2 * sin(y(:, 2));
y2 = y1 - L2 * cos(y(:, 2));

plot(x2, y2, 'LineWidth', 1.5);
grid on;
title('Double Pendulum Chaotic Tip Trajectory');
xlabel('X Position (px)'); ylabel('Y Position (px)');
''';
  }
}
