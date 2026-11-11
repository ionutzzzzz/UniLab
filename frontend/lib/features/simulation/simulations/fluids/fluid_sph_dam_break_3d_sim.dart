import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class SPHFluidParticle {
  Vector3 position;
  Vector3 velocity;
  Vector3 force;
  double density;
  double pressure;

  SPHFluidParticle({
    required this.position,
    required this.velocity,
    Vector3? force,
    this.density = 1000.0,
    this.pressure = 0.0,
  }) : force = force ?? Vector3.zero;

  SPHFluidParticle copy() {
    return SPHFluidParticle(
      position: Vector3(position.x, position.y, position.z),
      velocity: Vector3(velocity.x, velocity.y, velocity.z),
      force: Vector3(force.x, force.y, force.z),
      density: density,
      pressure: pressure,
    );
  }
}

class FluidSPHDamBreak3DSim extends SimulationModel {
  int particleCount = 280;
  double restDensity = 1000.0;
  double stiffness = 200.0; // Gas constant k in Tait equation
  double viscosity = 3.5;
  double gravity = 9.81;
  double smoothingRadius = 28.0; // SPH kernel radius h

  // Boundary box dimensions
  final double boxX = 140.0;
  final double boxY = 160.0;
  final double boxZ = 70.0;

  final List<SPHFluidParticle> _particles = [];

  FluidSPHDamBreak3DSim()
      : super(
          id: 'fluids_sph_dam_break_3d',
          name: '3D SPH Fluid Dam Break (Navier-Stokes)',
          description:
              'Smoothed Particle Hydrodynamics (SPH) Lagrangian fluid solver modeling an instantaneous column collapse dam break, fluid-structure collisions, pressure gradients, and dynamic splash vorticity.',
          category: SimCategory.aerospace,
          dimension: SimDimension.threeD,
          tags: ['Fluid Dynamics', 'SPH', 'Navier-Stokes', '3D Fluids', 'Dam Break', 'Hydrodynamics'],
          parameters: [
            SimParameter(
              id: 'particleCount',
              name: 'Particle Count',
              category: 'Simulation',
              min: 100.0,
              max: 450.0,
              step: 50.0,
              defaultValue: 280.0,
            ),
            SimParameter(
              id: 'viscosity',
              name: 'Dynamic Viscosity (μ)',
              category: 'Fluid Properties',
              unit: 'Pa·s',
              min: 0.5,
              max: 12.0,
              step: 0.5,
              defaultValue: 3.5,
            ),
            SimParameter(
              id: 'gravity',
              name: 'Gravity (g)',
              category: 'Forces',
              unit: 'm/s²',
              min: 0.0,
              max: 25.0,
              step: 1.0,
              defaultValue: 9.81,
            ),
            SimParameter(
              id: 'restDensity',
              name: 'Rest Density (ρ₀)',
              category: 'Fluid Properties',
              unit: 'kg/m³',
              min: 600.0,
              max: 1500.0,
              step: 50.0,
              defaultValue: 1000.0,
            ),
            SimParameter(
              id: 'stiffness',
              name: 'Pressure Stiffness (k)',
              category: 'State Equation',
              min: 50.0,
              max: 600.0,
              step: 25.0,
              defaultValue: 200.0,
            ),
          ],
          presets: [
            SimPreset(
              id: 'water_surge',
              name: 'Violent Water Dam Break',
              description: 'Classic hydraulic dam break producing rapid floor surge and vertical wall impact wave.',
              parameters: {
                'particleCount': 300.0,
                'viscosity': 2.0,
                'gravity': 9.81,
                'stiffness': 240.0,
              },
            ),
            SimPreset(
              id: 'viscous_honey',
              name: 'Viscous Molten Slurry',
              description: 'High-viscosity laminar fluid creeping across floor with low turbulence.',
              parameters: {
                'particleCount': 250.0,
                'viscosity': 10.0,
                'gravity': 9.81,
                'stiffness': 120.0,
              },
            ),
            SimPreset(
              id: 'zero_g',
              name: 'Zero-G Surface Tension Blob',
              description: 'Weightless microgravity fluid coalescing into spherical cluster under internal pressure.',
              parameters: {
                'particleCount': 260.0,
                'viscosity': 4.0,
                'gravity': 0.0,
                'stiffness': 180.0,
              },
            ),
            SimPreset(
              id: 'hyper_gravity',
              name: 'Hyper-Gravity Splash',
              description: 'High-G environment (2.5g) triggering explosive kinetic splashing and wave rebounding.',
              parameters: {
                'particleCount': 320.0,
                'viscosity': 1.5,
                'gravity': 24.0,
                'stiffness': 350.0,
              },
            ),
          ],
        );

  @override
  void init() {
    time = 0.0;
    stepIndex = 0;
    _initializeDamBreakColumn();
  }

  @override
  void reset() {
    time = 0.0;
    stepIndex = 0;
    _initializeDamBreakColumn();
  }

  void _initializeDamBreakColumn() {
    _particles.clear();
    final count = particleCount.clamp(80, 450);

    // Initial water column at left side: x in [-boxX + 15, -boxX + 90], y in [10, 130], z in [-boxZ + 15, boxZ - 15]
    final random = math.Random(42);
    for (int i = 0; i < count; i++) {
      final x = -boxX + 15.0 + random.nextDouble() * 75.0;
      final y = 10.0 + random.nextDouble() * 110.0;
      final z = -boxZ + 15.0 + random.nextDouble() * (boxZ * 2 - 30.0);

      _particles.add(SPHFluidParticle(
        position: Vector3(x, y, z),
        velocity: Vector3(
          (random.nextDouble() - 0.5) * 2.0,
          -random.nextDouble() * 3.0,
          (random.nextDouble() - 0.5) * 2.0,
        ),
      ));
    }
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'particleCount') {
      particleCount = (value as num).toInt();
      _initializeDamBreakColumn();
    } else if (paramId == 'viscosity') {
      viscosity = (value as num).toDouble();
    } else if (paramId == 'gravity') {
      gravity = (value as num).toDouble();
    } else if (paramId == 'restDensity') {
      restDensity = (value as num).toDouble();
    } else if (paramId == 'stiffness') {
      stiffness = (value as num).toDouble();
    }
  }

  @override
  void step(double dt) {
    // SPH substepping for numerical stability
    const subSteps = 2;
    final subDt = (dt * 0.8 / subSteps).clamp(0.002, 0.02);

    for (int s = 0; s < subSteps; s++) {
      _computeSPHDensitiesAndPressures();
      _computeSPHForces();
      _integrateParticles(subDt);
      _handleBoundaryCollisions();
    }

    time += dt;
    stepIndex++;
  }

  void _computeSPHDensitiesAndPressures() {
    final h2 = smoothingRadius * smoothingRadius;
    final h9 = math.pow(smoothingRadius, 9);
    final poly6 = 315.0 / (64.0 * math.pi * h9);

    for (final pi in _particles) {
      double density = 0.0;
      for (final pj in _particles) {
        final diff = pi.position - pj.position;
        final r2 = diff.x * diff.x + diff.y * diff.y + diff.z * diff.z;
        if (r2 < h2) {
          final diffR2 = h2 - r2;
          density += poly6 * diffR2 * diffR2 * diffR2;
        }
      }
      pi.density = math.max(restDensity * 0.6, density * 10000.0);
      // Tait Equation of State: P = k * (rho - rho0)
      pi.pressure = stiffness * (pi.density - restDensity);
      if (pi.pressure < 0) pi.pressure = 0.0;
    }
  }

  void _computeSPHForces() {
    final h = smoothingRadius;
    final spiky = -45.0 / (math.pi * math.pow(h, 6));
    final viscLap = 45.0 / (math.pi * math.pow(h, 6));

    for (int i = 0; i < _particles.length; i++) {
      final pi = _particles[i];
      Vector3 fPressure = Vector3.zero;
      Vector3 fViscosity = Vector3.zero;

      for (int j = 0; j < _particles.length; j++) {
        if (i == j) continue;
        final pj = _particles[j];
        final diff = pi.position - pj.position;
        final r = diff.length;

        if (r > 0.001 && r < h) {
          final q = h - r;
          // Pressure gradient force
          final pTerm = (pi.pressure + pj.pressure) / (2.0 * pj.density);
          final gradW = diff * (spiky * q * q / r);
          fPressure = fPressure - (gradW * pTerm * 50.0);

          // Viscosity Laplacian force
          final vDiff = pj.velocity - pi.velocity;
          fViscosity = fViscosity + (vDiff * (viscosity / pj.density * viscLap * q * 10.0));
        }
      }

      // External forces: Gravity
      final fGravity = Vector3(0.0, -gravity * 60.0, 0.0);
      pi.force = fPressure + fViscosity + fGravity;
    }
  }

  void _integrateParticles(double dt) {
    for (final p in _particles) {
      // Leapfrog Euler integration with acceleration = Force / density
      final acc = p.force * (1.0 / p.density * 500.0);
      p.velocity = p.velocity + (acc * dt);
      p.position = p.position + (p.velocity * dt * 2.0);
    }
  }

  void _handleBoundaryCollisions() {
    const damping = 0.65;
    const boundaryRadius = 4.0;

    for (final p in _particles) {
      double px = p.position.x;
      double py = p.position.y;
      double pz = p.position.z;
      double vx = p.velocity.x;
      double vy = p.velocity.y;
      double vz = p.velocity.z;

      // Floor (y = 0)
      if (py < boundaryRadius) {
        py = boundaryRadius;
        vy = -vy * damping;
        vx *= 0.94; // Surface friction
        vz *= 0.94;
      }
      // Ceiling (y = boxY)
      if (py > boxY - boundaryRadius) {
        py = boxY - boundaryRadius;
        vy = -vy * damping;
      }
      // Left/Right Walls (x = +/- boxX)
      if (px < -boxX + boundaryRadius) {
        px = -boxX + boundaryRadius;
        vx = -vx * damping;
      } else if (px > boxX - boundaryRadius) {
        px = boxX - boundaryRadius;
        vx = -vx * damping;
      }
      // Front/Back Walls (z = +/- boxZ)
      if (pz < -boxZ + boundaryRadius) {
        pz = -boxZ + boundaryRadius;
        vz = -vz * damping;
      } else if (pz > boxZ - boundaryRadius) {
        pz = boxZ - boundaryRadius;
        vz = -vz * damping;
      }

      p.position = Vector3(px, py, pz);
      p.velocity = Vector3(vx, vy, vz);
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
  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    final saved = snapshot.state['particles'] as List<SPHFluidParticle>;
    _particles.clear();
    for (final p in saved) {
      _particles.add(p.copy());
    }
  }

  @override
  Map<String, dynamic> getMetrics() {
    double maxVel = 0.0;
    double avgDensity = 0.0;
    double maxPressure = 0.0;
    for (final p in _particles) {
      final v = p.velocity.length;
      if (v > maxVel) maxVel = v;
      if (p.pressure > maxPressure) maxPressure = p.pressure;
      avgDensity += p.density;
    }
    if (_particles.isNotEmpty) avgDensity /= _particles.length;

    return {
      'Active Particles': _particles.length,
      'Peak Wave Speed (m/s)': maxVel * 0.1,
      'Mean Density (kg/m³)': avgDensity,
      'Peak Pressure (kPa)': maxPressure * 0.01,
      'Fluid State': maxVel > 15.0 ? 'TURBULENT SURGE' : 'SETTLING LAMINAR',
    };
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    // 1. Draw Transparent Glass Tank Boundaries
    _renderGlassTank(canvas, size, camera, theme);

    // 2. Sort Particles along camera view direction (Back to Front) for translucent blending
    final sorted = List<SPHFluidParticle>.from(_particles);
    sorted.sort((a, b) {
      final da = (a.position - camera.eye).length;
      final db = (b.position - camera.eye).length;
      return db.compareTo(da);
    });

    // 3. Render Fluid Particles with Dynamic Hydrodynamic Shading
    for (final p in sorted) {
      final projected = camera.projectVector(p.position, size);
      if (projected == null) continue;

      final dist = (p.position - camera.eye).length;
      final speed = p.velocity.length;
      final rad = (7.5 * 380.0 / dist).clamp(2.5, 20.0);

      // Color mapping: Speed + Pressure -> Deep oceanic blue to frothy splash cyan/white
      final speedFactor = (speed / 30.0).clamp(0.0, 1.0);
      final Color fluidColor = Color.lerp(
        const Color(0xFF0D47A1), // Deep Ocean Blue
        const Color(0xFF00E5FF), // Rapid Splash Cyan
        speedFactor,
      )!;

      // Foam highlight for rapid splash
      final isFoam = speed > 22.0 || p.position.y > boxY * 0.7;

      final spherePaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.85,
          colors: [
            isFoam ? Colors.white : Colors.white.withValues(alpha: 0.85),
            fluidColor,
            const Color(0xFF011627).withValues(alpha: 0.9),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: projected.screen, radius: rad));

      canvas.drawCircle(projected.screen, rad, spherePaint);

      // Specular glint
      final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
      canvas.drawCircle(
        Offset(projected.screen.dx - rad * 0.3, projected.screen.dy - rad * 0.3),
        rad * 0.22,
        glintPaint,
      );
    }
  }

  void _renderGlassTank(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    // 3D Glass Reservoir wireframe & floor grid
    final framePaint = Paint()
      ..color = theme.accent.withValues(alpha: 0.3)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final corners = [
      Vector3(-boxX, 0, -boxZ),
      Vector3(boxX, 0, -boxZ),
      Vector3(boxX, 0, boxZ),
      Vector3(-boxX, 0, boxZ),
      Vector3(-boxX, boxY, -boxZ),
      Vector3(boxX, boxY, -boxZ),
      Vector3(boxX, boxY, boxZ),
      Vector3(-boxX, boxY, boxZ),
    ];

    final projectedCorners = corners.map((c) => camera.projectVector(c, size)).toList();

    // Floor lines
    for (int i = 0; i < 4; i++) {
      final next = (i + 1) % 4;
      if (projectedCorners[i] != null && projectedCorners[next] != null) {
        canvas.drawLine(projectedCorners[i]!.screen, projectedCorners[next]!.screen, framePaint);
      }
    }

    // Vertical pillar lines
    for (int i = 0; i < 4; i++) {
      if (projectedCorners[i] != null && projectedCorners[i + 4] != null) {
        canvas.drawLine(projectedCorners[i]!.screen, projectedCorners[i + 4]!.screen, framePaint);
      }
    }

    // Top rim lines
    for (int i = 4; i < 8; i++) {
      final next = 4 + (i - 3) % 4;
      if (projectedCorners[i] != null && projectedCorners[next] != null) {
        canvas.drawLine(projectedCorners[i]!.screen, projectedCorners[next]!.screen, framePaint);
      }
    }

    // Submerged floor grid pattern
    final floorGridPaint = Paint()
      ..color = theme.gridColor.withValues(alpha: 0.25)
      ..strokeWidth = 0.8;

    for (double x = -boxX + 20.0; x < boxX; x += 35.0) {
      final p1 = camera.project(x, 0, -boxZ, size);
      final p2 = camera.project(x, 0, boxZ, size);
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1.screen, p2.screen, floorGridPaint);
      }
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab SPH Fluid Dam Break (Navier-Stokes) Simulation
N = $particleCount;
rho0 = $restDensity;
mu = $viscosity;
g = $gravity;
dt = 0.005;
steps = 600;

fprintf('Simulating 3D SPH Dam Break with %d fluid particles...\\n', N);
fprintf('Rest Density = %.1f kg/m^3, Viscosity = %.2f Pa.s\\n', rho0, mu);

% Initialize particle state matrices
pos = zeros(N, 3);
vel = zeros(N, 3);
density = ones(N, 1) * rho0;
pressure = zeros(N, 1);

figure('Name', 'SPH Dam Break Velocity Profile');
title('Lagrangian SPH Fluid Dynamics');
xlabel('X (cm)'); ylabel('Y (cm)'); zlabel('Z (cm)');
grid on; view(3);
''';
  }
}
