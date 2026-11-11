import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class AccretionDiskParticle {
  double radius;
  double angle;
  double speed;
  double brightness;
  double temperature;
  final Color baseColor;

  AccretionDiskParticle({
    required this.radius,
    required this.angle,
    required this.speed,
    required this.brightness,
    required this.temperature,
    required this.baseColor,
  });

  AccretionDiskParticle copy() {
    return AccretionDiskParticle(
      radius: radius,
      angle: angle,
      speed: speed,
      brightness: brightness,
      temperature: temperature,
      baseColor: baseColor,
    );
  }
}

class BlackHoleLensing3DSim extends SimulationModel {
  double blackHoleMass = 4.15; // In 10^6 Solar Masses (Sagittarius A*)
  double diskSpin = 0.85; // Relativistic spin parameter a* (-1.0 to 1.0)
  double accretionRate = 0.05; // Eddington accretion rate fraction
  double lensingStrength = 1.0;
  bool showSpacetimeWell = true;
  bool showGeodesicRays = true;

  final List<AccretionDiskParticle> _diskParticles = [];
  final List<Vector3> _infallingStreams = [];
  final int particleCount = 420;

  BlackHoleLensing3DSim()
      : super(
          id: 'physics_black_hole_lensing_3d',
          name: '3D Relativistic Black Hole & Accretion Disk',
          description:
              'General Relativistic Schwarzschild/Kerr spacetime curvature modeling an event horizon, photon sphere (1.5 Rs), relativistic Doppler beaming accretion disk, and gravitational light bending.',
          category: SimCategory.physics,
          dimension: SimDimension.threeD,
          tags: ['Astrophysics', 'General Relativity', 'Black Hole', 'Gravitational Lensing', 'Accretion Disk', 'Spacetime'],
          parameters: [
            SimParameter(
              id: 'blackHoleMass',
              name: 'Mass (10⁶ M☉)',
              category: 'Spacetime',
              unit: 'M☉',
              min: 1.0,
              max: 20.0,
              step: 0.5,
              defaultValue: 4.15,
            ),
            SimParameter(
              id: 'diskSpin',
              name: 'Kerr Spin Parameter (a*)',
              category: 'Relativity',
              min: 0.0,
              max: 0.99,
              step: 0.05,
              defaultValue: 0.85,
            ),
            SimParameter(
              id: 'accretionRate',
              name: 'Accretion Rate (Mdot/Medd)',
              category: 'Accretion Disk',
              min: 0.01,
              max: 0.25,
              step: 0.01,
              defaultValue: 0.05,
            ),
            SimParameter(
              id: 'lensingStrength',
              name: 'Geodesic Lensing Intensity',
              category: 'Optics',
              min: 0.2,
              max: 2.0,
              step: 0.1,
              defaultValue: 1.0,
            ),
            SimParameter(
              id: 'showSpacetimeWell',
              name: 'Spacetime Curvature Funnel',
              category: 'Visuals',
              type: SimParameterType.toggle,
              defaultValue: true,
            ),
            SimParameter(
              id: 'showGeodesicRays',
              name: 'Photon Deflection Geodesics',
              category: 'Visuals',
              type: SimParameterType.toggle,
              defaultValue: true,
            ),
          ],
          presets: [
            SimPreset(
              id: 'sag_a',
              name: 'Sagittarius A* (Milky Way SMBH)',
              description: 'Supermassive black hole at the galactic center with quiet, low-rate accretion flow.',
              parameters: {
                'blackHoleMass': 4.15,
                'diskSpin': 0.70,
                'accretionRate': 0.03,
                'lensingStrength': 1.0,
              },
            ),
            SimPreset(
              id: 'gargantua',
              name: 'Gargantua (Extreme Supermassive)',
              description: 'Colossal Kerr black hole with rapid spin, bright radiant accretion ring, and towering lensing arches.',
              parameters: {
                'blackHoleMass': 18.0,
                'diskSpin': 0.98,
                'accretionRate': 0.12,
                'lensingStrength': 1.8,
              },
            ),
            SimPreset(
              id: 'microquasar',
              name: 'Cygnus X-1 (Stellar Microquasar)',
              description: 'Stellar-mass relativistic compact binary undergoing violent supercritical accretion.',
              parameters: {
                'blackHoleMass': 1.5,
                'diskSpin': 0.95,
                'accretionRate': 0.22,
                'lensingStrength': 1.2,
              },
            ),
          ],
        );

  @override
  void init() {
    time = 0.0;
    stepIndex = 0;
    _initializeDisk();
  }

  @override
  void reset() {
    time = 0.0;
    stepIndex = 0;
    _initializeDisk();
  }

  void _initializeDisk() {
    _diskParticles.clear();
    _infallingStreams.clear();
    final random = math.Random(137);

    // Schwarzschild radius Rs proportional to mass
    final rs = 16.0 + (blackHoleMass / 4.15) * 8.0;
    final rIsco = rs * (3.0 - diskSpin * 1.5); // ISCO shrinks with spin
    final rOuter = rs * 8.0;

    for (int i = 0; i < particleCount; i++) {
      final frac = random.nextDouble();
      // Density concentrates towards ISCO
      final radius = rIsco + (rOuter - rIsco) * math.pow(frac, 1.6);
      final angle = random.nextDouble() * 2 * math.pi;

      // Keplerian orbital speed v = sqrt(GM/r)
      final speed = math.sqrt(rs * 1200.0 / radius) * (1.0 + diskSpin * 0.3);

      // Temperature gradient: T proportional to r^(-3/4)
      final temp = 1.0 - (radius - rIsco) / (rOuter - rIsco);

      // Color based on temperature: hot inner = white/cyan/gold, cool outer = deep red/amber
      Color baseColor;
      if (temp > 0.7) {
        baseColor = const Color(0xFFE0F7FA);
      } else if (temp > 0.4) {
        baseColor = const Color(0xFFFFD54F);
      } else {
        baseColor = const Color(0xFFFF5722);
      }

      _diskParticles.add(AccretionDiskParticle(
        radius: radius,
        angle: angle,
        speed: speed,
        brightness: 0.6 + random.nextDouble() * 0.4,
        temperature: temp,
        baseColor: baseColor,
      ));
    }

    // Initialize infalling geodesic streamers
    for (int i = 0; i < 28; i++) {
      final a = random.nextDouble() * 2 * math.pi;
      final r = rs * 1.8 + random.nextDouble() * rs * 2.5;
      _infallingStreams.add(Vector3(r * math.cos(a), (random.nextDouble() - 0.5) * 12.0, r * math.sin(a)));
    }
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'blackHoleMass') {
      blackHoleMass = (value as num).toDouble();
      _initializeDisk();
    } else if (paramId == 'diskSpin') {
      diskSpin = (value as num).toDouble();
      _initializeDisk();
    } else if (paramId == 'accretionRate') {
      accretionRate = (value as num).toDouble();
    } else if (paramId == 'lensingStrength') {
      lensingStrength = (value as num).toDouble();
    } else if (paramId == 'showSpacetimeWell') {
      showSpacetimeWell = value as bool;
    } else if (paramId == 'showGeodesicRays') {
      showGeodesicRays = value as bool;
    }
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;

    final rs = 16.0 + (blackHoleMass / 4.15) * 8.0;
    final rIsco = rs * (3.0 - diskSpin * 1.5);

    // Orbit disk particles along Keplerian spirals with slight radial inflow
    for (final p in _diskParticles) {
      p.angle += (p.speed / p.radius) * dt * 0.6;
      // Inward radial drift from viscosity
      p.radius -= accretionRate * 4.0 * dt;
      if (p.radius < rIsco) {
        p.radius = rs * 7.5 + (p.radius % (rs * 0.5));
      }
    }

    // Infalling streams spiraling across the event horizon
    for (int i = 0; i < _infallingStreams.length; i++) {
      var s = _infallingStreams[i];
      final r = math.sqrt(s.x * s.x + s.z * s.z);
      final angle = math.atan2(s.z, s.x) + (140.0 / (r + 1.0)) * dt;
      final newR = r - (25.0 + 80.0 / (r - rs + 2.0)) * dt;

      if (newR <= rs * 1.05) {
        // Plunge past event horizon -> respawn outer stream
        final respawnA = (time * 1.2 + i * 0.4) % (2 * math.pi);
        _infallingStreams[i] = Vector3(
          rs * 3.5 * math.cos(respawnA),
          math.sin(time + i) * 8.0,
          rs * 3.5 * math.sin(respawnA),
        );
      } else {
        _infallingStreams[i] = Vector3(newR * math.cos(angle), s.y * 0.98, newR * math.sin(angle));
      }
    }
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {
        'particles': _diskParticles.map((p) => p.copy()).toList(),
      },
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    final saved = snapshot.state['particles'] as List<AccretionDiskParticle>;
    _diskParticles.clear();
    for (final p in saved) {
      _diskParticles.add(p.copy());
    }
  }

  @override
  Map<String, dynamic> getMetrics() {
    final rs = 16.0 + (blackHoleMass / 4.15) * 8.0;
    final rPhoton = rs * 1.5;
    final rIsco = rs * (3.0 - diskSpin * 1.5);
    final eddingtonLum = 1.26e38 * blackHoleMass; // Erg/s

    return {
      'Schwarzschild Radius Rs (km)': (rs * 2.95e5).toInt(),
      'Photon Sphere Radius (km)': (rPhoton * 2.95e5).toInt(),
      'ISCO Radius (km)': (rIsco * 2.95e5).toInt(),
      'Doppler Beaming Factor': 1.0 + diskSpin * 2.4,
      'Disk Luminosity (% Edd)': (accretionRate * 100.0),
      'Eddington Limit (erg/s)': eddingtonLum,
    };
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    final rs = 16.0 + (blackHoleMass / 4.15) * 8.0;
    final rPhoton = rs * 1.5;

    // 1. Spacetime Curvature Funnel ("Gravity Well")
    if (showSpacetimeWell) {
      _renderCurvatureFunnel(canvas, size, camera, theme, rs);
    }

    // 2. Gravitational Deflection Lensing Rings (Einstein Ring arch)
    if (showGeodesicRays) {
      _renderGravitationalLensingArches(canvas, size, camera, theme, rs, rPhoton);
    }

    // 3. Render Infalling Geodesic Streamers
    _renderInfallingStreams(canvas, size, camera, theme, rs);

    // 4. Render Accretion Disk Particles with Relativistic Doppler Beaming
    _renderAccretionDisk(canvas, size, camera, theme, rs);

    // 5. Draw Black Hole Event Horizon Shadow Sphere
    _renderEventHorizon(canvas, size, camera, theme, rs);
  }

  void _renderCurvatureFunnel(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme, double rs) {
    final gridPaint = Paint()
      ..color = theme.accent.withValues(alpha: 0.16)
      ..strokeWidth = 0.8;

    const rings = 8;
    const radialLines = 16;
    final maxR = rs * 8.5;

    for (int i = 1; i <= rings; i++) {
      final r = rs * 1.2 + (maxR - rs * 1.2) * (i / rings);
      // Flamm's paraboloid z = -2 * sqrt(rs * (r - rs))
      final depth = -math.sqrt(math.max(0.1, rs * (r - rs))) * 6.5;

      final pts = <Vector3>[];
      for (int j = 0; j <= 24; j++) {
        final a = j * (2 * math.pi / 24);
        pts.add(Vector3(r * math.cos(a), depth, r * math.sin(a)));
      }

      for (int j = 0; j < pts.length - 1; j++) {
        final p1 = camera.projectVector(pts[j], size);
        final p2 = camera.projectVector(pts[j + 1], size);
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1.screen, p2.screen, gridPaint);
        }
      }
    }

    // Radial spines
    for (int j = 0; j < radialLines; j++) {
      final a = j * (2 * math.pi / radialLines);
      Vector3? prevPt;
      for (int i = 1; i <= rings; i++) {
        final r = rs * 1.2 + (maxR - rs * 1.2) * (i / rings);
        final depth = -math.sqrt(math.max(0.1, rs * (r - rs))) * 6.5;
        final currPt = Vector3(r * math.cos(a), depth, r * math.sin(a));
        if (prevPt != null) {
          final p1 = camera.projectVector(prevPt, size);
          final p2 = camera.projectVector(currPt, size);
          if (p1 != null && p2 != null) {
            canvas.drawLine(p1.screen, p2.screen, gridPaint);
          }
        }
        prevPt = currPt;
      }
    }
  }

  void _renderGravitationalLensingArches(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme, double rs, double rPhoton) {
    // Einstein Ring surrounding the photon sphere
    final centerProj = camera.project(0, 0, 0, size);
    if (centerProj == null) return;

    final dist = camera.eye.length;
    final ringScreenRadius = (rPhoton * 1.35 * 400.0 / dist).clamp(15.0, 180.0);

    // Glowing Einstein Ring halo
    final ringGlowPaint = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.35 * lensingStrength.clamp(0.2, 1.5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawCircle(centerProj.screen, ringScreenRadius, ringGlowPaint);

    final ringCorePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7 * lensingStrength.clamp(0.2, 1.2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(centerProj.screen, ringScreenRadius, ringCorePaint);
  }

  void _renderInfallingStreams(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme, double rs) {
    final streamPaint = Paint()
      ..color = theme.accent.withValues(alpha: 0.7)
      ..strokeWidth = 1.6;

    for (final s in _infallingStreams) {
      final proj = camera.projectVector(s, size);
      if (proj != null) {
        canvas.drawCircle(proj.screen, 1.8, streamPaint);
      }
    }
  }

  void _renderAccretionDisk(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme, double rs) {
    // Sort particles along view ray
    final sorted = List<AccretionDiskParticle>.from(_diskParticles);
    sorted.sort((a, b) {
      final posA = Vector3(a.radius * math.cos(a.angle), 0, a.radius * math.sin(a.angle));
      final posB = Vector3(b.radius * math.cos(b.angle), 0, b.radius * math.sin(b.angle));
      final da = (posA - camera.eye).length;
      final db = (posB - camera.eye).length;
      return db.compareTo(da);
    });

    for (final p in sorted) {
      final pos = Vector3(p.radius * math.cos(p.angle), 0, p.radius * math.sin(p.angle));
      final proj = camera.projectVector(pos, size);
      if (proj == null) continue;

      final dist = (pos - camera.eye).length;
      final baseRad = (3.5 * 380.0 / dist).clamp(1.5, 9.0);

      // Relativistic Doppler Beaming calculation
      // Velocity vector in disk: tangential direction [-sin(angle), 0, cos(angle)]
      final velDir = Vector3(-math.sin(p.angle), 0, math.cos(p.angle));
      final toCamera = (camera.eye - pos).normalized();
      final dot = velDir.dot(toCamera); // > 0: approaching, < 0: receding

      // Relativistic Doppler factor delta ~ 1 / (1 - beta * dot)
      final beta = (p.speed * 0.003).clamp(0.1, 0.75);
      final dopplerFactor = (1.0 / (1.0 - beta * dot * diskSpin)).clamp(0.3, 3.2);

      Color renderColor;
      if (dot > 0.05) {
        // Approaching: Intense blue-shift / bright white-cyan boost
        renderColor = Color.lerp(p.baseColor, const Color(0xFF00E5FF), (dot * diskSpin).clamp(0.0, 1.0))!;
      } else if (dot < -0.05) {
        // Receding: Red-shift / dimmed ember dark orange
        renderColor = Color.lerp(p.baseColor, const Color(0xFFB71C1C), (-dot * diskSpin).clamp(0.0, 1.0))!;
      } else {
        renderColor = p.baseColor;
      }

      final alpha = (p.brightness * (dopplerFactor / 2.0)).clamp(0.2, 1.0);
      final rad = baseRad * (dopplerFactor * 0.75).clamp(0.6, 1.8);

      final pPaint = Paint()
        ..color = renderColor.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(proj.screen, rad, pPaint);
    }
  }

  void _renderEventHorizon(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme, double rs) {
    final proj = camera.project(0, 0, 0, size);
    if (proj == null) return;

    final dist = camera.eye.length;
    final screenRs = (rs * 400.0 / dist).clamp(10.0, 120.0);

    // Event Horizon Shadow (Pure Total Absorption Pitch Black)
    final shadowPaint = Paint()..color = const Color(0xFF000000);
    canvas.drawCircle(proj.screen, screenRs, shadowPaint);

    // Razor-sharp photon capture boundary border
    final borderPaint = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(proj.screen, screenRs, borderPaint);
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab General Relativistic Black Hole & Accretion Lensing
M = $blackHoleMass;  % 10^6 M_sun
a = $diskSpin;       % Spin parameter
rs = 2 * M;          % Schwarzschild radius in natural units
r_isco = rs * (3 - a * 1.5);

fprintf('Schwarzschild Horizon: Rs = %.2f GM/c^2\\n', rs);
fprintf('ISCO Radius: R_isco = %.2f GM/c^2\\n', r_isco);
fprintf('Accretion Rate: %.2f M_dot / M_edd\\n', $accretionRate);

figure('Name', 'Relativistic Accretion Disk & Ray Tracing');
title('Schwarzschild/Kerr Metric Geodesic Lensing');
xlabel('X (GM/c^2)'); ylabel('Y (GM/c^2)'); zlabel('Z (GM/c^2)');
grid on; axis equal; view(3);
''';
  }
}
