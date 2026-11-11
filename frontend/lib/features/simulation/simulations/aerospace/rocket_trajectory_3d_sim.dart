import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class RocketTrajectory3DSim extends SimulationModel {
  double thrust = 7600.0; // kN
  double dryMass = 25.0; // Tons
  double fuelMass = 400.0; // Tons
  double isp = 310.0; // Specific impulse (s)
  double pitchOverAltitude = 2500.0; // m

  double altitude = 0.0;
  double velocityX = 0.0;
  double velocityY = 0.0;
  double downrange = 0.0;
  double pitchAngle = 0.0; // Radians from vertical
  bool isStageSeparated = false;
  bool isOrbitAchieved = false;

  final List<Vector3> _flightPath = [];

  RocketTrajectory3DSim()
      : super(
          id: 'aerospace_rocket_trajectory_3d',
          name: 'Orbital Rocket Launch & Staging (3D Aerospace)',
          description:
              '3D multi-stage orbital launch ascent solving Tsiolkovsky variable-mass rocket equations, gravity turns, Max-Q dynamic pressure, stage separation, and low Earth orbit (LEO) insertion.',
          category: SimCategory.aerospace,
          dimension: SimDimension.threeD,
          tags: ['Aerospace', '3D', 'Rocket', 'Tsiolkovsky', 'Orbit', 'Max-Q'],
          parameters: [
            SimParameter(
              id: 'thrust',
              name: 'Engine Thrust (kN)',
              category: 'Propulsion',
              min: 4000.0,
              max: 12000.0,
              step: 500.0,
              defaultValue: 7600.0,
            ),
            SimParameter(
              id: 'dryMass',
              name: 'Dry Mass (Tons)',
              category: 'Vehicle Mass',
              min: 15.0,
              max: 50.0,
              step: 5.0,
              defaultValue: 25.0,
            ),
            SimParameter(
              id: 'fuelMass',
              name: 'Propellant Mass (Tons)',
              category: 'Vehicle Mass',
              min: 200.0,
              max: 600.0,
              step: 25.0,
              defaultValue: 400.0,
            ),
            SimParameter(
              id: 'isp',
              name: 'Specific Impulse (Isp)',
              category: 'Propulsion',
              unit: 's',
              min: 250.0,
              max: 420.0,
              step: 10.0,
              defaultValue: 310.0,
            ),
          ],
          presets: [
            SimPreset(
              id: 'falcon_heavy',
              name: 'Heavy-Lift Orbital Insertion',
              description: 'Standard multi-stage mission achieving 200km parking orbit.',
              parameters: {'thrust': 9000.0, 'dryMass': 30.0, 'fuelMass': 480.0, 'isp': 320.0},
            ),
            SimPreset(
              id: 'suborbital',
              name: 'Suborbital Sounding Hop',
              description: 'Vertical ballistic trajectory peaking at Karman line edge of space.',
              parameters: {'thrust': 5500.0, 'dryMass': 20.0, 'fuelMass': 220.0, 'isp': 280.0},
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
    altitude = 0.0;
    downrange = 0.0;
    velocityX = 0.0;
    velocityY = 0.0;
    pitchAngle = 0.0;
    isStageSeparated = false;
    isOrbitAchieved = false;
    _flightPath.clear();
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'thrust') thrust = (value as num).toDouble();
    if (paramId == 'dryMass') dryMass = (value as num).toDouble();
    if (paramId == 'fuelMass') fuelMass = (value as num).toDouble();
    if (paramId == 'isp') isp = (value as num).toDouble();
  }

  @override
  void step(double dt) {
    final subSteps = 4;
    final h = dt / subSteps;

    for (int s = 0; s < subSteps; s++) {
      _rocketStep(h);
    }

    time += dt;
    stepIndex++;

    // Scale for 3D visualization
    final scale = 0.002;
    _flightPath.add(Vector3(downrange * scale, altitude * scale, 0));
    if (_flightPath.length > 350) {
      _flightPath.removeAt(0);
    }
  }

  void _rocketStep(double h) {
    final g0 = 9.80665;
    final totalMass = dryMass + fuelMass;

    // Mass burn rate mdot = Thrust / (Isp * g0)
    final mDot = (fuelMass > 0) ? (thrust / (isp * g0)) : 0.0;
    fuelMass = math.max(0.0, fuelMass - mDot * h);

    // Gravity turn pitch angle
    if (altitude > 1000.0) {
      pitchAngle = math.min(1.45, (altitude / 80000.0) * (math.pi / 2.0));
    }

    // Atmospheric density exponential lapse
    final rho = 1.225 * math.exp(-altitude / 8500.0);
    final currentSpeed = math.sqrt(velocityX * velocityX + velocityY * velocityY);
    final dragForce = 0.5 * rho * currentSpeed * currentSpeed * 0.3 * 10.0; // Cd * A

    // Net forces
    final effectiveThrust = (fuelMass > 0) ? thrust * 1000.0 : 0.0;
    final thrustX = effectiveThrust * math.sin(pitchAngle);
    final thrustY = effectiveThrust * math.cos(pitchAngle);

    final massKg = totalMass * 1000.0;
    final accX = (thrustX - dragForce * (velocityX / (currentSpeed + 1e-3))) / massKg;
    final accY = (thrustY - dragForce * (velocityY / (currentSpeed + 1e-3)) - massKg * g0) / massKg;

    velocityX += accX * h;
    velocityY += accY * h;

    downrange += velocityX * h;
    altitude = math.max(0.0, altitude + velocityY * h);

    if (fuelMass < 50.0 && !isStageSeparated) {
      isStageSeparated = true;
    }
    if (altitude > 150000.0 && velocityX > 7400.0) {
      isOrbitAchieved = true;
    }
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {
        'alt': altitude,
        'down': downrange,
        'vx': velocityX,
        'vy': velocityY,
        'fuel': fuelMass,
        'pitch': pitchAngle,
      },
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    altitude = snapshot.state['alt'] as double;
    downrange = snapshot.state['down'] as double;
    velocityX = snapshot.state['vx'] as double;
    velocityY = snapshot.state['vy'] as double;
    fuelMass = snapshot.state['fuel'] as double;
    pitchAngle = snapshot.state['pitch'] as double;
  }

  @override
  Map<String, num> getMetrics() {
    final speed = math.sqrt(velocityX * velocityX + velocityY * velocityY);
    final mach = speed / 340.0;
    final rho = 1.225 * math.exp(-altitude / 8500.0);
    final qMax = 0.5 * rho * speed * speed / 1000.0; // kPa

    return {
      'Altitude (km)': altitude / 1000.0,
      'Downrange (km)': downrange / 1000.0,
      'Speed (m/s)': speed,
      'Mach Number': mach,
      'Dynamic Pressure Q (kPa)': qMax,
      'Propellant Left (%)': (fuelMass / 400.0 * 100.0).clamp(0.0, 100.0),
    };
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    // 1. Earth Horizon Curve
    _renderEarthCurvature(canvas, size, camera, theme);

    // 2. Flight Trajectory Ribbon in 3D
    if (_flightPath.length > 1) {
      for (int i = 0; i < _flightPath.length - 1; i++) {
        final p1 = camera.projectVector(_flightPath[i], size);
        final p2 = camera.projectVector(_flightPath[i + 1], size);
        if (p1 == null || p2 == null) continue;

        final trailPaint = Paint()
          ..color = theme.accent.withValues(alpha: 0.75)
          ..strokeWidth = 2.0;
        canvas.drawLine(p1.screen, p2.screen, trailPaint);
      }
    }

    // 3. Rocket Body & Exhaust Supersonic Plume with Mach Shock Diamonds
    final scale = 0.002;
    final rocketPos = Vector3(downrange * scale, altitude * scale, 0);
    final rProj = camera.projectVector(rocketPos, size);

    if (rProj != null) {
      final pitchRad = pitchAngle;
      final noseDir = Offset(math.sin(pitchRad), -math.cos(pitchRad));
      final exhaustDir = -noseDir;

      // Exhaust plume with Mach Shock Diamonds when engine firing
      if (fuelMass > 0) {
        // Outer glowing plume expansion
        final plumeGlow = Paint()
          ..color = const Color(0xFFFF6D00).withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
        canvas.drawCircle(rProj.screen + exhaustDir * 12.0, 16.0, plumeGlow);

        final coreFlame = Paint()
          ..color = const Color(0xFFFFD600)
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(rProj.screen, rProj.screen + exhaustDir * 28.0, coreFlame);

        // Mach Shock Diamonds (periodic bright nodes along exhaust centerline)
        final diamondPaint = Paint()
          ..color = const Color(0xFF00E5FF)
          ..strokeWidth = 1.6;
        for (int d = 1; d <= 4; d++) {
          final centerD = rProj.screen + exhaustDir * (d * 6.5);
          final normPerp = Offset(-exhaustDir.dy, exhaustDir.dx);
          final pathD = Path()
            ..moveTo(centerD.dx - exhaustDir.dx * 2.5, centerD.dy - exhaustDir.dy * 2.5)
            ..lineTo(centerD.dx + normPerp.dx * 2.5, centerD.dy + normPerp.dy * 2.5)
            ..lineTo(centerD.dx + exhaustDir.dx * 2.5, centerD.dy + exhaustDir.dy * 2.5)
            ..lineTo(centerD.dx - normPerp.dx * 2.5, centerD.dy - normPerp.dy * 2.5)
            ..close();
          canvas.drawPath(pathD, diamondPaint);
        }
      }

      // Aerodynamic Rocket Body (Fuselage + Fairing + Fins)
      final bodyPaint = Paint()..color = Colors.white;
      final noseTip = rProj.screen + noseDir * 14.0;
      final tailCenter = rProj.screen - noseDir * 8.0;
      final perp = Offset(-noseDir.dy, noseDir.dx) * 3.5;

      final rocketPath = Path()
        ..moveTo(noseTip.dx, noseTip.dy)
        ..lineTo(rProj.screen.dx + perp.dx, rProj.screen.dy + perp.dy)
        ..lineTo(tailCenter.dx + perp.dx * 1.6, tailCenter.dy + perp.dy * 1.6)
        ..lineTo(tailCenter.dx - perp.dx * 1.6, tailCenter.dy - perp.dy * 1.6)
        ..lineTo(rProj.screen.dx - perp.dx, rProj.screen.dy - perp.dy)
        ..close();
      canvas.drawPath(rocketPath, bodyPaint);
    }
  }

  void _renderEarthCurvature(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    final earthPaint = Paint()
      ..color = const Color(0xFF005577).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const segments = 32;
    const r = 260.0;
    final path = Path();
    bool first = true;

    for (int i = 0; i <= segments; i++) {
      final a = -0.5 + i * (1.0 / segments);
      final x = r * math.sin(a);
      final y = -r + r * math.cos(a);
      final p = camera.project(x, y, 0, size);
      if (p != null) {
        if (first) {
          path.moveTo(p.screen.dx, p.screen.dy);
          first = false;
        } else {
          path.lineTo(p.screen.dx, p.screen.dy);
        }
      }
    }
    canvas.drawPath(path, earthPaint);
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab 3D Orbital Rocket Launch Trajectory
thrust = $thrust * 1000; % N
dry_mass = $dryMass * 1000; % kg
fuel_mass = $fuelMass * 1000; % kg
isp = $isp; g0 = 9.80665;

% Tsiolkovsky Ideal Delta-V
delta_v = isp * g0 * log((dry_mass + fuel_mass) / dry_mass);
disp(['Total Available Delta-V: ', num2str(delta_v / 1000), ' km/s']);
disp(['Required for Low Earth Orbit: ~9.4 km/s']);
''';
  }
}
