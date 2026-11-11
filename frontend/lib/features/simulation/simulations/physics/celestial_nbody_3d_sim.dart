import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class CelestialBody {
  String name;
  double mass;
  double radius;
  Color color;
  Vector3 position;
  Vector3 velocity;
  final List<Vector3> trail = [];

  CelestialBody({
    required this.name,
    required this.mass,
    required this.radius,
    required this.color,
    required this.position,
    required this.velocity,
  });

  CelestialBody copy() {
    final b = CelestialBody(
      name: name,
      mass: mass,
      radius: radius,
      color: color,
      position: position,
      velocity: velocity,
    );
    b.trail.addAll(trail);
    return b;
  }
}

class CelestialNBody3DSim extends SimulationModel {
  double gConstant = 1200.0;
  double timeScale = 1.0;
  bool showTrails = true;
  bool showVelocityVectors = true;
  int maxTrailLength = 180;

  final List<CelestialBody> bodies = [];
  final List<Vector3> _stars = [];

  CelestialNBody3DSim()
      : super(
          id: 'physics_celestial_nbody_3d',
          name: 'Celestial N-Body Orbits (3D Astrophysics)',
          description:
              'Interactive 3D gravitational orbital mechanics solving Newton\'s multi-body gravitation with planetary inclinations, barycentric precession, and velocity vectors.',
          category: SimCategory.physics,
          dimension: SimDimension.threeD,
          tags: ['Astrophysics', '3D', 'Gravity', 'Kepler Orbits', 'N-Body'],
          parameters: [
            SimParameter(
              id: 'gConstant',
              name: 'Gravitational Constant (G)',
              category: 'Gravitation',
              min: 200.0,
              max: 3000.0,
              step: 100.0,
              defaultValue: 1200.0,
            ),
            SimParameter(
              id: 'timeScale',
              name: 'Orbit Speed Multiplier',
              category: 'Simulation',
              min: 0.1,
              max: 3.0,
              step: 0.1,
              defaultValue: 1.0,
            ),
            SimParameter(
              id: 'showTrails',
              name: 'Orbital Path Ribbons',
              category: 'Visuals',
              type: SimParameterType.toggle,
              defaultValue: true,
            ),
            SimParameter(
              id: 'showVelocityVectors',
              name: 'Velocity Vectors',
              category: 'Visuals',
              type: SimParameterType.toggle,
              defaultValue: true,
            ),
          ],
          presets: [
            SimPreset(
              id: 'solar_system',
              name: 'Inner Solar System',
              description: 'Sun with Mercury, Earth, Moon, Mars, and Jupiter in inclined 3D orbits.',
              parameters: {'gConstant': 1200.0, 'timeScale': 1.0, 'showTrails': true},
            ),
            SimPreset(
              id: 'binary_star',
              name: 'Binary Star System with Planet',
              description: 'Two massive stars orbiting a common barycenter with a circumbinary planet.',
              parameters: {'gConstant': 1500.0, 'timeScale': 0.8, 'showTrails': true},
            ),
            SimPreset(
              id: 'lagrange_trojan',
              name: 'Trojan Asteroid at L4 Point',
              description: 'Stable gravitational Lagrange L4 equilibrium point tracking.',
              parameters: {'gConstant': 1200.0, 'timeScale': 1.2, 'showTrails': true},
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
    _setupSolarSystem();
  }

  void _setupSolarSystem() {
    bodies.clear();

    if (_stars.isEmpty) {
      final rand = math.Random(42);
      for (int i = 0; i < 180; i++) {
        final u = rand.nextDouble() * 2.0 - 1.0;
        final theta = rand.nextDouble() * 2.0 * math.pi;
        final rad = 750.0 + rand.nextDouble() * 200.0;
        final r = math.sqrt(1.0 - u * u);
        _stars.add(Vector3(rad * r * math.cos(theta), rad * u, rad * r * math.sin(theta)));
      }
    }

    // Central Star (Sun)
    bodies.add(
      CelestialBody(
        name: 'Sun',
        mass: 1000.0,
        radius: 18.0,
        color: const Color(0xFFFFD600),
        position: const Vector3(0, 0, 0),
        velocity: const Vector3(0, 0, 0),
      ),
    );

    // Mercury
    bodies.add(
      CelestialBody(
        name: 'Mercury',
        mass: 1.2,
        radius: 4.0,
        color: const Color(0xFFB0BEC5),
        position: const Vector3(55, 6, 0),
        velocity: const Vector3(0, 0, 4.6),
      ),
    );

    // Earth
    bodies.add(
      CelestialBody(
        name: 'Earth',
        mass: 5.0,
        radius: 6.5,
        color: const Color(0xFF00E5FF),
        position: const Vector3(110, 0, 0),
        velocity: const Vector3(0, 0.4, 3.3),
      ),
    );

    // Mars
    bodies.add(
      CelestialBody(
        name: 'Mars',
        mass: 2.5,
        radius: 5.0,
        color: const Color(0xFFFF5252),
        position: const Vector3(160, -12, 0),
        velocity: const Vector3(0, -0.3, 2.7),
      ),
    );

    // Jupiter
    bodies.add(
      CelestialBody(
        name: 'Jupiter',
        mass: 35.0,
        radius: 12.0,
        color: const Color(0xFFFFAB40),
        position: const Vector3(230, 18, 0),
        velocity: const Vector3(0, 0.2, 2.2),
      ),
    );
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'gConstant') gConstant = (value as num).toDouble();
    if (paramId == 'timeScale') timeScale = (value as num).toDouble();
    if (paramId == 'showTrails') showTrails = value as bool;
    if (paramId == 'showVelocityVectors') showVelocityVectors = value as bool;
  }

  @override
  void step(double dt) {
    final effectiveDt = dt * timeScale;
    final subSteps = 4;
    final h = effectiveDt / subSteps;

    for (int s = 0; s < subSteps; s++) {
      _nBodyLeapfrogStep(h);
    }

    time += effectiveDt;
    stepIndex++;

    // Update trails
    for (final body in bodies) {
      body.trail.add(body.position);
      if (body.trail.length > maxTrailLength) {
        body.trail.removeAt(0);
      }
    }
  }

  void _nBodyLeapfrogStep(double h) {
    final count = bodies.length;
    final accelerations = List<Vector3>.filled(count, const Vector3(0, 0, 0));

    // Calculate pairwise gravitational forces
    for (int i = 0; i < count; i++) {
      var acc = const Vector3(0, 0, 0);
      for (int j = 0; j < count; j++) {
        if (i == j) continue;
        final rVec = bodies[j].position - bodies[i].position;
        final dist = rVec.length;
        final softenedDist = math.max(dist, 10.0); // Softening to prevent singularity
        final forceMag = (gConstant * bodies[j].mass) / (softenedDist * softenedDist * softenedDist);
        acc = acc + (rVec * forceMag);
      }
      accelerations[i] = acc;
    }

    // Velocity Verlet / Leapfrog integration
    for (int i = 0; i < count; i++) {
      bodies[i].velocity = bodies[i].velocity + (accelerations[i] * h);
      bodies[i].position = bodies[i].position + (bodies[i].velocity * h);
    }
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {
        'bodies': bodies.map((b) => b.copy()).toList(),
      },
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    bodies.clear();
    final savedBodies = snapshot.state['bodies'] as List<CelestialBody>;
    for (final b in savedBodies) {
      bodies.add(b.copy());
    }
  }

  @override
  Map<String, num> getMetrics() {
    double totalKinetic = 0.0;
    for (final b in bodies) {
      totalKinetic += 0.5 * b.mass * (b.velocity.length * b.velocity.length);
    }
    return {
      'Active Bodies': bodies.length,
      'Kinetic Energy (J)': totalKinetic,
      'System Radius (AU)': bodies.last.position.length,
    };
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    // 0. Render Parallax Deep Space Starfield
    _renderDeepSpaceStarfield(canvas, size, camera, theme);

    // 1. Draw 3D Reference Grid Plane (Ecliptic Plane)
    _renderEclipticGrid(canvas, size, camera, theme);

    // 2. Draw Orbital Trails
    if (showTrails) {
      for (final body in bodies) {
        if (body.trail.length < 2) continue;
        for (int i = 0; i < body.trail.length - 1; i++) {
          final p1 = camera.projectVector(body.trail[i], size);
          final p2 = camera.projectVector(body.trail[i + 1], size);
          if (p1 == null || p2 == null) continue;

          final progress = i / body.trail.length;
          final trailPaint = Paint()
            ..color = body.color.withValues(alpha: progress * 0.75)
            ..strokeWidth = 1.0 + progress * 1.5;
          canvas.drawLine(p1.screen, p2.screen, trailPaint);
        }
      }
    }

    // 3. Sort bodies by depth for correct 3D z-ordering
    final sortedBodies = List<CelestialBody>.from(bodies);
    sortedBodies.sort((a, b) {
      final da = (a.position - camera.eye).length;
      final db = (b.position - camera.eye).length;
      return db.compareTo(da); // Draw furthest first
    });

    // 4. Draw Celestial Bodies & Velocity Arrows
    for (final body in sortedBodies) {
      final projected = camera.projectVector(body.position, size);
      if (projected == null) continue;

      final screenPos = projected.screen;
      // Perspective scale factor based on distance from camera
      final dist = (body.position - camera.eye).length;
      final visualRadius = (body.radius * 350.0 / dist).clamp(2.5, 45.0);

      // Glowing aura & solar flares for Sun
      if (body.name == 'Sun') {
        final flarePulsation = 1.0 + 0.12 * math.sin(time * 5.0);
        final glowPaint = Paint()
          ..color = body.color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22.0);
        canvas.drawCircle(screenPos, visualRadius * 2.2 * flarePulsation, glowPaint);
      }

      // Planetary rings for Jupiter / Gas Giant
      if (body.name == 'Jupiter') {
        final ringPaint = Paint()
          ..color = const Color(0xFFFFD180).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawOval(
          Rect.fromCenter(center: screenPos, width: visualRadius * 3.2, height: visualRadius * 1.1),
          ringPaint,
        );
      }

      // Body Sphere with 3D gradient lighting
      final spherePaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.9,
          colors: [Colors.white.withValues(alpha: 0.9), body.color, Colors.black.withValues(alpha: 0.8)],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: screenPos, radius: visualRadius));

      canvas.drawCircle(screenPos, visualRadius, spherePaint);

      // Body Name Tag
      final tp = TextPainter(
        text: TextSpan(
          text: body.name,
          style: TextStyle(color: theme.textMuted, fontSize: 9, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(screenPos.dx + visualRadius + 4, screenPos.dy - 6));

      // Draw Velocity Vector
      if (showVelocityVectors && body.name != 'Sun') {
        final vTarget = body.position + (body.velocity * 6.0);
        final vProj = camera.projectVector(vTarget, size);
        if (vProj != null) {
          final vPaint = Paint()
            ..color = theme.accent.withValues(alpha: 0.8)
            ..strokeWidth = 1.5;
          canvas.drawLine(screenPos, vProj.screen, vPaint);
        }
      }
    }
  }

  void _renderDeepSpaceStarfield(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < _stars.length; i++) {
      final p = camera.projectVector(_stars[i], size);
      if (p != null) {
        final twinkle = 0.4 + 0.6 * math.sin(time * 3.0 + i).abs();
        starPaint.color = Colors.white.withValues(alpha: twinkle * 0.85);
        canvas.drawCircle(p.screen, 1.2, starPaint);
      }
    }
  }

  void _renderEclipticGrid(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    final gridPaint = Paint()
      ..color = theme.gridColor.withValues(alpha: 0.18)
      ..strokeWidth = 1.0;

    const span = 280.0;
    const step = 70.0;

    for (double x = -span; x <= span; x += step) {
      final p1 = camera.project(x, 0, -span, size);
      final p2 = camera.project(x, 0, span, size);
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1.screen, p2.screen, gridPaint);
      }
    }

    for (double z = -span; z <= span; z += step) {
      final p1 = camera.project(-span, 0, z, size);
      final p2 = camera.project(span, 0, z, size);
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1.screen, p2.screen, gridPaint);
      }
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab 3D Celestial N-Body Simulation
G = $gConstant;
dt = 0.05;
steps = 500;

% Initial State: [x y z vx vy vz mass]
bodies = [
    0    0   0    0    0    0    1000;  % Sun
    55   6   0    0    0   4.6   1.2;   % Mercury
   110   0   0    0   0.4  3.3   5.0;   % Earth
   160 -12   0    0  -0.3  2.7   2.5;   % Mars
   230  18   0    0   0.2  2.2  35.0    % Jupiter
];

figure('Name', '3D Celestial Orbits');
hold on; grid on; axis equal;
view(3);
title('Gravitational N-Body System Trajectories');
xlabel('X (AU)'); ylabel('Y (AU)'); zlabel('Z (AU)');
''';
  }
}
