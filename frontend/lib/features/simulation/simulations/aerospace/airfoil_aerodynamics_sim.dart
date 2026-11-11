import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';

class AirfoilStreamlineParticle {
  double x; // Normalized [0.0, 1.0]
  double y; // Normalized [0.0, 1.0]
  double vx;
  double vy;
  double speed;

  AirfoilStreamlineParticle(this.x, this.y, this.vx, this.vy, [this.speed = 1.0]);
}

class AirfoilAerodynamicsSim extends SimulationModel {
  double angleOfAttack = 6.0; // Degrees
  double airspeed = 45.0; // m/s
  double camber = 0.04;
  double thickness = 0.12;

  final List<AirfoilStreamlineParticle> _particles = [];
  final int maxParticles = 380;

  AirfoilAerodynamicsSim()
      : super(
          id: 'aerospace_airfoil_aerodynamics',
          name: 'Airfoil Aerodynamics & Wind Tunnel',
          description:
              'Wind tunnel potential flow streamlines over a NACA cambered airfoil, calculating dynamic pressure distributions, lift/drag polars, and flow separation stall.',
          category: SimCategory.aerospace,
          dimension: SimDimension.twoD,
          tags: ['Aerodynamics', 'Airfoil', 'Lift', 'Drag', 'Wind Tunnel', 'Stall'],
          parameters: [
            SimParameter(
              id: 'angleOfAttack',
              name: 'Angle of Attack (α)',
              category: 'Attitude',
              unit: '°',
              min: -8.0,
              max: 26.0,
              step: 1.0,
              defaultValue: 6.0,
            ),
            SimParameter(
              id: 'airspeed',
              name: 'Free Stream Velocity',
              category: 'Flow',
              unit: 'm/s',
              min: 15.0,
              max: 90.0,
              step: 5.0,
              defaultValue: 45.0,
            ),
            SimParameter(
              id: 'thickness',
              name: 'Profile Thickness (t/c)',
              category: 'Geometry',
              min: 0.06,
              max: 0.22,
              step: 0.02,
              defaultValue: 0.12,
            ),
          ],
          presets: [
            SimPreset(
              id: 'cruising_attitude',
              name: 'Optimal Cruise (α = 4°)',
              description: 'Maximum L/D aerodynamic efficiency ratio for steady high-altitude cruise.',
              parameters: {'angleOfAttack': 4.0, 'airspeed': 55.0},
            ),
            SimPreset(
              id: 'high_lift_takeoff',
              name: 'Takeoff Climb (α = 12°)',
              description: 'High lift coefficient state with accelerated upper surface suction flow.',
              parameters: {'angleOfAttack': 12.0, 'airspeed': 35.0},
            ),
            SimPreset(
              id: 'aerodynamic_stall',
              name: 'Boundary Layer Stall (α = 22°)',
              description: 'Flow separation over suction surface triggering severe stall buffeting and drag divergence.',
              parameters: {'angleOfAttack': 22.0, 'airspeed': 40.0},
            ),
          ],
        );

  @override
  void init() {
    time = 0.0;
    stepIndex = 0;
    _particles.clear();

    final rand = math.Random(137);
    for (int i = 0; i < maxParticles; i++) {
      _particles.add(
        AirfoilStreamlineParticle(
          rand.nextDouble(),
          0.05 + rand.nextDouble() * 0.90,
          0.3,
          0.0,
          1.0,
        ),
      );
    }
  }

  @override
  void reset() {
    init();
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'angleOfAttack') angleOfAttack = (value as num).toDouble();
    if (paramId == 'airspeed') airspeed = (value as num).toDouble();
    if (paramId == 'thickness') thickness = (value as num).toDouble();
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;

    final alphaRad = angleOfAttack * math.pi / 180.0;
    final isStalled = angleOfAttack > 15.0;

    // Airfoil normalized position
    const foilCenterX = 0.45;
    const foilCenterY = 0.50;
    const chord = 0.28;

    final baseSpeed = (airspeed / 50.0) * 0.38;

    for (final p in _particles) {
      var vx = baseSpeed;
      var vy = 0.0;

      final dx = p.x - foilCenterX;
      final dy = p.y - foilCenterY;
      final dist = math.sqrt(dx * dx + dy * dy);

      if (dist < chord * 1.2) {
        // Potential flow circulation (Kutta-Joukowski effect)
        final gamma = baseSpeed * 0.12 * math.sin(alphaRad + 0.08);
        final vortexVx = gamma * dy / (dist * dist + 0.02);
        final vortexVy = -gamma * dx / (dist * dist + 0.02);

        vx += vortexVx;
        vy += vortexVy;

        // Suction acceleration over upper surface (dy < 0)
        if (dy < 0 && dx.abs() < chord * 0.6) {
          vx *= (1.0 + math.sin(alphaRad).abs() * 0.85);
        }

        // Stall turbulent wake behind trailing edge (dx > 0)
        if (isStalled && dx > 0) {
          vy += math.sin(time * 16.0 + p.x * 25.0) * 0.22;
          vx *= 0.65; // Massive drag slowdown
        }
      }

      p.vx = vx;
      p.vy = vy;
      p.speed = math.sqrt(vx * vx + vy * vy);

      p.x += vx * dt;
      p.y += vy * dt;

      // Wrap back to left inlet
      if (p.x > 1.02) {
        p.x = -0.02;
        p.y = 0.04 + math.Random().nextDouble() * 0.92;
      }
    }
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {'aoa': angleOfAttack},
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    angleOfAttack = snapshot.state['aoa'] as double;
  }

  @override
  Map<String, dynamic> getMetrics() {
    final alphaRad = angleOfAttack * math.pi / 180.0;
    final isStalled = angleOfAttack > 15.0;

    final cl = isStalled ? (1.1 * math.cos(alphaRad)) : (2.0 * math.pi * (alphaRad + 0.04));
    final cd = 0.015 + (cl * cl) / (math.pi * 0.8 * 6.0) + (isStalled ? 0.22 : 0.0);
    final liftToDrag = (cd > 0) ? (cl / cd) : 0.0;

    return {
      'Lift Coefficient (CL)': cl,
      'Drag Coefficient (CD)': cd,
      'L/D Efficiency Ratio': liftToDrag,
      'Airflow Regime': isStalled ? 'SEPARATED STALL' : 'ATTACHED LAMINAR',
      'Dynamic Pressure (kPa)': 0.5 * 1.225 * airspeed * airspeed * 0.001,
    };
  }

  @override
  void render2D(Canvas canvas, Size size, SimTheme theme) {
    // 1. Wind Tunnel Top & Bottom Walls
    final tunnelPaint = Paint()
      ..color = theme.gridColor.withValues(alpha: 0.35)
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(0, 16), Offset(size.width, 16), tunnelPaint);
    canvas.drawLine(Offset(0, size.height - 16), Offset(size.width, size.height - 16), tunnelPaint);

    // 2. Streamline Flow Particle Trails with Velocity-Dependent Coloring
    for (final p in _particles) {
      final screenX = p.x * size.width;
      final screenY = p.y * size.height;

      // Color mapping: Speed -> High velocity over top is bright white-cyan; slow under belly is amber
      final speedFactor = (p.speed / 0.5).clamp(0.2, 1.2);
      Color trailColor;
      if (speedFactor > 0.9) {
        trailColor = Color.lerp(theme.accent, Colors.white, (speedFactor - 0.9) * 2.5)!;
      } else if (speedFactor < 0.6) {
        trailColor = Color.lerp(const Color(0xFFFFB300), theme.accent, speedFactor / 0.6)!;
      } else {
        trailColor = theme.accent;
      }

      final pPaint = Paint()
        ..color = trailColor.withValues(alpha: 0.75)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(screenX - 8.0, screenY), Offset(screenX, screenY), pPaint);
    }

    // 3. Cambered NACA Airfoil Geometry Centered Responsively
    _renderAirfoilProfile(canvas, size, theme);
  }

  void _renderAirfoilProfile(Canvas canvas, Size size, SimTheme theme) {
    final cx = size.width * 0.45;
    final cy = size.height * 0.50;
    final chord = math.min(size.width * 0.28, 280.0);
    final alphaRad = -angleOfAttack * math.pi / 180.0;

    final path = Path();
    const steps = 36;

    final upper = <Offset>[];
    final lower = <Offset>[];

    for (int i = 0; i <= steps; i++) {
      final xc = i / steps;
      final yt = 5 * thickness * (0.2969 * math.sqrt(xc) - 0.1260 * xc - 0.3516 * xc * xc + 0.2843 * xc * xc * xc - 0.1015 * xc * xc * xc * xc);
      final yc = camber * (2 * 0.4 * xc - xc * xc) / (0.4 * 0.4);

      final pxUpper = (xc - 0.5) * chord;
      final pyUpper = -(yc + yt) * chord;
      final pxLower = (xc - 0.5) * chord;
      final pyLower = -(yc - yt) * chord;

      // Rotate by angle of attack
      final rxU = pxUpper * math.cos(alphaRad) - pyUpper * math.sin(alphaRad);
      final ryU = pxUpper * math.sin(alphaRad) + pyUpper * math.cos(alphaRad);

      final rxL = pxLower * math.cos(alphaRad) - pyLower * math.sin(alphaRad);
      final ryL = pxLower * math.sin(alphaRad) + pyLower * math.cos(alphaRad);

      upper.add(Offset(cx + rxU, cy + ryU));
      lower.add(Offset(cx + rxL, cy + ryL));
    }

    path.moveTo(upper.first.dx, upper.first.dy);
    for (final pt in upper) {
      path.lineTo(pt.dx, pt.dy);
    }
    for (final pt in lower.reversed) {
      path.lineTo(pt.dx, pt.dy);
    }
    path.close();

    final isStalled = angleOfAttack > 15.0;

    // Wing cross section metallic skin
    final foilPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isStalled
            ? [const Color(0xFFFF5252), const Color(0xFFB71C1C)]
            : [Colors.white, const Color(0xFF90A4AE), const Color(0xFF37474F)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: chord * 0.6));

    canvas.drawPath(path, foilPaint);

    final borderPaint = Paint()
      ..color = isStalled ? const Color(0xFFFF1744) : theme.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(path, borderPaint);
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab Airfoil Aerodynamics & Wind Tunnel Analysis
alpha_deg = $angleOfAttack;
v_inf = $airspeed;
c = 0.3; % Chord (m)

alpha_rad = alpha_deg * pi / 180;
Cl = 2 * pi * (alpha_rad + 0.04);
Cd = 0.015 + (Cl.^2) / (pi * 0.8 * 6);

disp(['Angle of Attack: ', num2str(alpha_deg), ' deg']);
disp(['Lift Coefficient Cl: ', num2str(Cl)]);
disp(['Drag Coefficient Cd: ', num2str(Cd)]);
''';
  }
}
