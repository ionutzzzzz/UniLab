import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class CycloneVortexParticle {
  double radius;
  double angle;
  double height; // Vertical altitude in km
  double radialVelocity;
  double tangentialVelocity;
  double verticalVelocity;
  double size;
  double opacity;
  final int bandIndex;

  CycloneVortexParticle({
    required this.radius,
    required this.angle,
    required this.height,
    required this.radialVelocity,
    required this.tangentialVelocity,
    required this.verticalVelocity,
    required this.size,
    required this.opacity,
    required this.bandIndex,
  });

  CycloneVortexParticle copy() {
    return CycloneVortexParticle(
      radius: radius,
      angle: angle,
      height: height,
      radialVelocity: radialVelocity,
      tangentialVelocity: tangentialVelocity,
      verticalVelocity: verticalVelocity,
      size: size,
      opacity: opacity,
      bandIndex: bandIndex,
    );
  }
}

class CycloneHurricane3DSim extends SimulationModel {
  double centralPressure = 920.0; // hPa (Cat 5 ~ 920 hPa)
  double seaSurfaceTemp = 29.5; // °C
  double latitude = 22.0; // Degrees North (Coriolis parameter)
  double eyeDiameter = 35.0; // km
  double verticalShear = 5.0; // m/s
  bool showVelocityVectors = false;
  bool showRainbands = true;

  final List<CycloneVortexParticle> _particles = [];
  final int particleCount = 480;

  CycloneHurricane3DSim()
      : super(
          id: 'atmospheric_cyclone_hurricane_3d',
          name: '3D Atmospheric Hurricane & Cyclone Dynamics',
          description:
              'Fluid vorticity and tropical cyclone thermodynamics solving the Holland gradient wind field, Coriolis cyclogenesis, eye wall convective updrafts, and logarithmic spiral rainbands.',
          category: SimCategory.aerospace,
          dimension: SimDimension.threeD,
          tags: ['Meteorology', 'Cyclones', 'Hurricanes', 'Fluid Dynamics', 'Coriolis', 'Vorticity', 'Atmospheric'],
          parameters: [
            SimParameter(
              id: 'centralPressure',
              name: 'Central Pressure',
              category: 'Barometric',
              unit: 'hPa',
              min: 890.0,
              max: 1005.0,
              step: 5.0,
              defaultValue: 920.0,
            ),
            SimParameter(
              id: 'seaSurfaceTemp',
              name: 'Sea Surface Temp (SST)',
              category: 'Thermodynamics',
              unit: '°C',
              min: 24.0,
              max: 33.0,
              step: 0.5,
              defaultValue: 29.5,
            ),
            SimParameter(
              id: 'latitude',
              name: 'Latitude (Coriolis)',
              category: 'Geography',
              unit: '°N',
              min: 5.0,
              max: 45.0,
              step: 1.0,
              defaultValue: 22.0,
            ),
            SimParameter(
              id: 'eyeDiameter',
              name: 'Eye Diameter',
              category: 'Structure',
              unit: 'km',
              min: 15.0,
              max: 80.0,
              step: 5.0,
              defaultValue: 35.0,
            ),
            SimParameter(
              id: 'verticalShear',
              name: 'Tropospheric Wind Shear',
              category: 'Environment',
              unit: 'm/s',
              min: 0.0,
              max: 25.0,
              step: 1.0,
              defaultValue: 5.0,
            ),
          ],
          presets: [
            SimPreset(
              id: 'super_typhoon',
              name: 'Category 5 Super Typhoon',
              description: 'Intense 905 hPa central pressure, compact pinhole eye, and peak sustained winds > 280 km/h.',
              parameters: {
                'centralPressure': 905.0,
                'seaSurfaceTemp': 31.0,
                'latitude': 18.0,
                'eyeDiameter': 25.0,
                'verticalShear': 3.0,
              },
            ),
            SimPreset(
              id: 'major_hurricane',
              name: 'Category 3 Major Hurricane',
              description: 'Well-formed 950 hPa eyewall with wide spiral rainbands traversing warm tropical waters.',
              parameters: {
                'centralPressure': 950.0,
                'seaSurfaceTemp': 28.5,
                'latitude': 25.0,
                'eyeDiameter': 45.0,
                'verticalShear': 7.0,
              },
            ),
            SimPreset(
              id: 'tropical_storm',
              name: 'Developing Tropical Depression',
              description: 'Broad disorganized convective vortex with 995 hPa pressure and low tangential winds.',
              parameters: {
                'centralPressure': 995.0,
                'seaSurfaceTemp': 27.0,
                'latitude': 14.0,
                'eyeDiameter': 65.0,
                'verticalShear': 14.0,
              },
            ),
          ],
        );

  @override
  void init() {
    time = 0.0;
    stepIndex = 0;
    _initializeStormParticles();
  }

  @override
  void reset() {
    time = 0.0;
    stepIndex = 0;
    _initializeStormParticles();
  }

  void _initializeStormParticles() {
    _particles.clear();
    final random = math.Random(73);
    final rEye = eyeDiameter * 0.5 * 2.2;
    final rMax = 180.0;

    for (int i = 0; i < particleCount; i++) {
      final band = i % 4;
      // Logarithmic spiral angle and radius
      final u = random.nextDouble();
      final radius = rEye + (rMax - rEye) * math.pow(u, 1.4);
      final spiralAngle = band * (math.pi / 2.0) + math.log(radius / rEye + 1.0) * 3.2 + (random.nextDouble() - 0.5) * 0.6;
      final height = random.nextDouble() * 45.0; // Altitude up to tropopause

      _particles.add(CycloneVortexParticle(
        radius: radius,
        angle: spiralAngle,
        height: height,
        radialVelocity: -2.0,
        tangentialVelocity: 25.0,
        verticalVelocity: 1.0,
        size: 3.5 + random.nextDouble() * 5.0,
        opacity: 0.4 + random.nextDouble() * 0.5,
        bandIndex: band,
      ));
    }
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'centralPressure') {
      centralPressure = (value as num).toDouble();
    } else if (paramId == 'seaSurfaceTemp') {
      seaSurfaceTemp = (value as num).toDouble();
    } else if (paramId == 'latitude') {
      latitude = (value as num).toDouble();
    } else if (paramId == 'eyeDiameter') {
      eyeDiameter = (value as num).toDouble();
    } else if (paramId == 'verticalShear') {
      verticalShear = (value as num).toDouble();
    }
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;

    final rEye = eyeDiameter * 0.5 * 2.2;
    final rMax = 180.0;
    final deltaP = (1013.25 - centralPressure).clamp(10.0, 130.0);
    // Holland B parameter
    final hollandB = 1.0 + (deltaP / 100.0) * 0.8;

    for (final p in _particles) {
      // Tangential velocity profile (Holland gradient wind)
      final rRatio = rEye / math.max(0.1, p.radius);
      final term1 = hollandB * deltaP * 1.5 * math.pow(rRatio, hollandB) * math.exp(-math.pow(rRatio, hollandB));
      final vTangential = math.sqrt(math.max(4.0, term1)) * 3.6; // km/h scaled

      // Eyewall updraft: strongest near rEye
      final isNearEye = (p.radius - rEye).abs() < 15.0;
      final vUpdraft = isNearEye ? (8.0 + (deltaP / 15.0)) : 1.2;

      // Inflow at lower layers (height < 25), outflow at upper troposphere (height > 35)
      double vRadial;
      if (p.height < 25.0) {
        vRadial = -6.0 * (1.0 - p.radius / rMax); // Inflow towards eye
      } else {
        vRadial = 8.0 * (p.radius / rMax); // Upper outflow anticyclonic shield
      }

      // Advect particle
      p.angle += (vTangential / p.radius) * dt * 0.5;
      p.radius += vRadial * dt;
      p.height += vUpdraft * dt;

      // Recycling boundary conditions
      if (p.radius < rEye || p.radius > rMax || p.height > 50.0) {
        final rand = math.Random((time * 100 + p.radius).toInt() % 10000);
        p.radius = rEye + (rMax - rEye) * (0.6 + rand.nextDouble() * 0.4);
        p.height = rand.nextDouble() * 8.0;
        p.angle = (rand.nextDouble() * 2 * math.pi);
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
    final saved = snapshot.state['particles'] as List<CycloneVortexParticle>;
    _particles.clear();
    for (final p in saved) {
      _particles.add(p.copy());
    }
  }

  @override
  Map<String, dynamic> getMetrics() {
    final deltaP = (1013.25 - centralPressure).clamp(10.0, 130.0);
    // Peak wind estimation from Atkinson-Holliday empirical relationship
    final peakWindKnots = 6.7 * math.pow(deltaP, 0.644);
    final peakWindKmh = peakWindKnots * 1.852;

    String category;
    if (peakWindKnots >= 137) {
      category = 'Category 5 Super Typhoon';
    } else if (peakWindKnots >= 113) {
      category = 'Category 4 Major';
    } else if (peakWindKnots >= 96) {
      category = 'Category 3 Major';
    } else if (peakWindKnots >= 83) {
      category = 'Category 2 Hurricane';
    } else if (peakWindKnots >= 64) {
      category = 'Category 1 Hurricane';
    } else {
      category = 'Tropical Storm';
    }

    return {
      'Saffir-Simpson Class': category,
      'Peak Sustained Winds (km/h)': peakWindKmh,
      'Peak Wind (Knots)': peakWindKnots,
      'Central Deficit (hPa)': deltaP,
      'Eye Wall Vorticity (1/s)': (peakWindKnots * 0.514 / (eyeDiameter * 500)),
    };
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    final rEye = eyeDiameter * 0.5 * 2.2;

    // 1. Draw Ocean Surface Grid
    _renderOceanGrid(canvas, size, camera, theme);

    // 2. Eye Wall Perimeter Indicator
    _renderEyeRing(canvas, size, camera, theme, rEye);

    // 3. Volumetric Storm Cloud Particles sorted Back to Front
    final sorted = List<CycloneVortexParticle>.from(_particles);
    sorted.sort((a, b) {
      final posA = Vector3(a.radius * math.cos(a.angle), a.height, a.radius * math.sin(a.angle));
      final posB = Vector3(b.radius * math.cos(b.angle), b.height, b.radius * math.sin(b.angle));
      final da = (posA - camera.eye).length;
      final db = (posB - camera.eye).length;
      return db.compareTo(da);
    });

    for (final p in sorted) {
      final pos = Vector3(p.radius * math.cos(p.angle), p.height, p.radius * math.sin(p.angle));
      final proj = camera.projectVector(pos, size);
      if (proj == null) continue;

      final dist = (pos - camera.eye).length;
      final rad = (p.size * 360.0 / dist).clamp(2.5, 24.0);

      // Color mapping: Inner Eyewall high intensity (crimson/magenta) -> Outer Rainbands (cyan/teal/white)
      final eyeProximity = (1.0 - (p.radius - rEye) / 140.0).clamp(0.0, 1.0);

      Color cloudColor;
      if (eyeProximity > 0.75) {
        // Severe eyewall convection
        cloudColor = Color.lerp(const Color(0xFFFF1744), const Color(0xFFFFD600), (p.height / 45.0).clamp(0.0, 1.0))!;
      } else if (eyeProximity > 0.45) {
        // Active rainband
        cloudColor = Color.lerp(const Color(0xFF00E5FF), const Color(0xFF76FF03), eyeProximity)!;
      } else {
        // Outer cirrus shield
        cloudColor = Color.lerp(const Color(0xFF90CAF9), Colors.white, (p.height / 45.0).clamp(0.0, 1.0))!;
      }

      final cloudPaint = Paint()
        ..color = cloudColor.withValues(alpha: p.opacity * 0.75)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rad * 0.4);

      canvas.drawCircle(proj.screen, rad, cloudPaint);
    }
  }

  void _renderOceanGrid(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    final oceanPaint = Paint()
      ..color = const Color(0xFF0D47A1).withValues(alpha: 0.18)
      ..strokeWidth = 1.0;

    const span = 180.0;
    for (double x = -span; x <= span; x += 45.0) {
      final p1 = camera.project(x, 0, -span, size);
      final p2 = camera.project(x, 0, span, size);
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1.screen, p2.screen, oceanPaint);
      }
    }
    for (double z = -span; z <= span; z += 45.0) {
      final p1 = camera.project(-span, 0, z, size);
      final p2 = camera.project(span, 0, z, size);
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1.screen, p2.screen, oceanPaint);
      }
    }
  }

  void _renderEyeRing(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme, double rEye) {
    final eyePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const segs = 32;
    for (int i = 0; i < segs; i++) {
      final a1 = i * (2 * math.pi / segs);
      final a2 = (i + 1) * (2 * math.pi / segs);
      final p1 = camera.project(rEye * math.cos(a1), 0, rEye * math.sin(a1), size);
      final p2 = camera.project(rEye * math.cos(a2), 0, rEye * math.sin(a2), size);
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1.screen, p2.screen, eyePaint);
      }
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab 3D Hurricane Holland Gradient Wind & Vorticity
P_c = $centralPressure;  % Central pressure (hPa)
P_env = 1013.25;
deltaP = P_env - P_c;
R_max = $eyeDiameter / 2;
lat = $latitude;

% Holland B parameter
B = 1.0 + (deltaP / 100) * 0.8;
rho_air = 1.15;
f = 2 * 7.292e-5 * sind(lat);

r = linspace(1, 250, 500); % km
r_m = r * 1000;
R_max_m = R_max * 1000;

% Holland Gradient Wind Equation
V_tangential = sqrt((B / rho_air) * (R_max_m ./ r_m).^B .* (deltaP * 100) .* exp(-(R_max_m ./ r_m).^B) + (r_m .* f / 2).^2) - (r_m .* f / 2);

figure('Name', 'Tropical Cyclone Radial Wind Profile');
plot(r, V_tangential * 3.6, 'r-', 'LineWidth', 2);
title(sprintf('Radial Wind Field (Delta P = %.1f hPa)', deltaP));
xlabel('Radius from Eye (km)'); ylabel('Tangential Wind (km/h)');
grid on;
''';
  }
}
