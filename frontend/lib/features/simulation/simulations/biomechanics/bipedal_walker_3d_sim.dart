import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class BipedalWalker3DSim extends SimulationModel {
  double cadence = 110.0; // Steps per minute
  double stepLength = 65.0; // cm
  double kneeFlexionMax = 60.0; // Degrees
  double torsoLean = 5.0; // Degrees forward lean
  double groundIncline = 0.0; // Degrees
  bool showSkeletonJoints = true;
  bool showGRFVectors = true;

  double gaitPhase = 0.0; // 0.0 to 1.0 (Full gait cycle: 2 steps)
  double treadmillOffset = 0.0;

  BipedalWalker3DSim()
      : super(
          id: 'biomechanics_bipedal_walker_3d',
          name: '3D Biomechanical Bipedal Walker (Gait Dynamics)',
          description:
              'Kinematic and dynamic skeletal inverted pendulum model of anthropomorphic human bipedal locomotion, resolving multi-segment joint trajectories, Ground Reaction Forces (GRF), and arm counter-oscillation.',
          category: SimCategory.medical,
          dimension: SimDimension.threeD,
          tags: ['Biomechanics', 'Gait Analysis', 'Robotics', 'Kinematics', 'Bipedalism', 'Inverted Pendulum'],
          parameters: [
            SimParameter(
              id: 'cadence',
              name: 'Cadence (Steps/min)',
              category: 'Locomotion',
              unit: 'spm',
              min: 60.0,
              max: 180.0,
              step: 5.0,
              defaultValue: 110.0,
            ),
            SimParameter(
              id: 'stepLength',
              name: 'Step Length',
              category: 'Kinematics',
              unit: 'cm',
              min: 30.0,
              max: 95.0,
              step: 5.0,
              defaultValue: 65.0,
            ),
            SimParameter(
              id: 'kneeFlexionMax',
              name: 'Peak Knee Flexion',
              category: 'Joint Angles',
              unit: '°',
              min: 30.0,
              max: 90.0,
              step: 5.0,
              defaultValue: 60.0,
            ),
            SimParameter(
              id: 'torsoLean',
              name: 'Torso Forward Lean',
              category: 'Postural',
              unit: '°',
              min: -5.0,
              max: 20.0,
              step: 1.0,
              defaultValue: 5.0,
            ),
            SimParameter(
              id: 'groundIncline',
              name: 'Slope Incline',
              category: 'Terrain',
              unit: '°',
              min: -15.0,
              max: 15.0,
              step: 1.0,
              defaultValue: 0.0,
            ),
            SimParameter(
              id: 'showGRFVectors',
              name: 'Ground Reaction Force (GRF)',
              category: 'Visuals',
              type: SimParameterType.toggle,
              defaultValue: true,
            ),
          ],
          presets: [
            SimPreset(
              id: 'natural_stride',
              name: 'Natural Human Walking Gait',
              description: 'Comfortable steady-state locomotion at 110 steps/min with standard kinematic joint excursions.',
              parameters: {
                'cadence': 110.0,
                'stepLength': 65.0,
                'kneeFlexionMax': 60.0,
                'torsoLean': 5.0,
                'groundIncline': 0.0,
              },
            ),
            SimPreset(
              id: 'athletic_jog',
              name: 'Brisk Athletic Jog',
              description: 'High-cadence 160 spm gait with deep knee flexion and aggressive forward trunk propulsion.',
              parameters: {
                'cadence': 155.0,
                'stepLength': 82.0,
                'kneeFlexionMax': 80.0,
                'torsoLean': 12.0,
                'groundIncline': 0.0,
              },
            ),
            SimPreset(
              id: 'hill_climb',
              name: 'Steep Hill Incline Climbing',
              description: 'Ascending a 12-degree grade with high ground reaction forces and pronounced hip extension.',
              parameters: {
                'cadence': 95.0,
                'stepLength': 50.0,
                'kneeFlexionMax': 75.0,
                'torsoLean': 14.0,
                'groundIncline': 12.0,
              },
            ),
            SimPreset(
              id: 'elderly_shuffling',
              name: 'Cautious Reduced Stride',
              description: 'Low-cadence short-step gait with stiff knees minimizing dynamic ground impacts.',
              parameters: {
                'cadence': 75.0,
                'stepLength': 40.0,
                'kneeFlexionMax': 40.0,
                'torsoLean': 2.0,
                'groundIncline': 0.0,
              },
            ),
          ],
        );

  @override
  void init() {
    time = 0.0;
    stepIndex = 0;
    gaitPhase = 0.0;
    treadmillOffset = 0.0;
  }

  @override
  void reset() {
    time = 0.0;
    stepIndex = 0;
    gaitPhase = 0.0;
    treadmillOffset = 0.0;
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'cadence') {
      cadence = (value as num).toDouble();
    } else if (paramId == 'stepLength') {
      stepLength = (value as num).toDouble();
    } else if (paramId == 'kneeFlexionMax') {
      kneeFlexionMax = (value as num).toDouble();
    } else if (paramId == 'torsoLean') {
      torsoLean = (value as num).toDouble();
    } else if (paramId == 'groundIncline') {
      groundIncline = (value as num).toDouble();
    } else if (paramId == 'showGRFVectors') {
      showGRFVectors = value as bool;
    }
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;

    // Stride frequency in Hz = cadence / 120 (since 2 steps per full gait cycle)
    final gaitFreq = cadence / 120.0;
    gaitPhase = (gaitPhase + gaitFreq * dt) % 1.0;

    // Treadmill track moves backward relative to walking speed
    final walkingSpeed = (cadence / 60.0) * (stepLength / 100.0); // m/s
    treadmillOffset = (treadmillOffset + walkingSpeed * 100.0 * dt) % 60.0;
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {'phase': gaitPhase, 'treadmill': treadmillOffset},
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    gaitPhase = snapshot.state['phase'] as double;
    treadmillOffset = snapshot.state['treadmill'] as double;
  }

  @override
  Map<String, dynamic> getMetrics() {
    final walkingSpeed = (cadence / 60.0) * (stepLength / 100.0); // m/s
    final grfPeak = 70.0 * 9.81 * (1.0 + (cadence - 100.0) * 0.008); // Peak vertical ground reaction force (N)
    final stanceFoot = gaitPhase < 0.5 ? 'Right Foot' : 'Left Foot';

    return {
      'Gait Speed (km/h)': walkingSpeed * 3.6,
      'Peak GRF Load (N)': grfPeak,
      'Step Rate (Hz)': cadence / 60.0,
      'Stance Dominance': stanceFoot,
      'Metabolic Cost (W/kg)': 2.5 + 0.8 * math.pow(walkingSpeed, 2),
    };
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    // 1. Moving Ground Treadmill Platform with Incline
    _renderGroundPlatform(canvas, size, camera, theme);

    // 2. Compute 3D Human Skeletal Segments based on Inverted Pendulum Kinematics
    _renderSkeletonBiped(canvas, size, camera, theme);
  }

  void _renderGroundPlatform(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    final gridPaint = Paint()
      ..color = theme.gridColor.withValues(alpha: 0.22)
      ..strokeWidth = 1.0;

    const spanX = 90.0;
    const spanZ = 180.0;
    final inclineRad = groundIncline * math.pi / 180.0;

    // Longitudinal treadmill stripes moving backward
    for (double z = -spanZ; z <= spanZ; z += 30.0) {
      final shiftedZ = z - treadmillOffset;
      final y = -shiftedZ * math.sin(inclineRad);
      final p1 = camera.project(-spanX, y, shiftedZ, size);
      final p2 = camera.project(spanX, y, shiftedZ, size);
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1.screen, p2.screen, gridPaint);
      }
    }

    // Lateral rails
    for (double x = -spanX; x <= spanX; x += 45.0) {
      final y1 = spanZ * math.sin(inclineRad);
      final y2 = -spanZ * math.sin(inclineRad);
      final p1 = camera.project(x, y1, -spanZ, size);
      final p2 = camera.project(x, y2, spanZ, size);
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1.screen, p2.screen, gridPaint);
      }
    }
  }

  void _renderSkeletonBiped(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    // Anthropometric segment lengths (cm)
    const pelvisWidth = 24.0;
    const thighLen = 44.0;
    const shinLen = 42.0;
    const torsoLen = 48.0;
    const shoulderWidth = 36.0;
    const armLen = 30.0;
    const forearmLen = 28.0;
    const headRadius = 11.0;

    // Pelvis vertical bounce (inverted pendulum oscillation: 2 dips per cycle)
    final verticalBounce = 4.0 * math.sin(gaitPhase * 4.0 * math.pi);
    final pelvisHeight = 84.0 + verticalBounce;

    // Forward pelvic lean
    final leanRad = torsoLean * math.pi / 180.0;
    final pelvisCenter = Vector3(0, pelvisHeight, 0);

    // Pelvis left & right hip joints
    final hipLeft = Vector3(-pelvisWidth * 0.5, pelvisHeight, 0);
    final hipRight = Vector3(pelvisWidth * 0.5, pelvisHeight, 0);

    // Left leg gait angle (phase shifted by 0.5 cycle = 180 deg)
    final phiR = gaitPhase * 2.0 * math.pi;
    final phiL = phiR + math.pi;

    // Thigh angles
    final thighAmp = (stepLength / 95.0) * 0.55;
    final thighAngleR = math.sin(phiR) * thighAmp;
    final thighAngleL = math.sin(phiL) * thighAmp;

    // Knee flexion angles (knees only flex backward, angle >= 0)
    final maxKneeRad = (kneeFlexionMax * math.pi / 180.0);
    final kneeFlexR = (math.sin(phiR - 0.4) > 0 ? math.sin(phiR - 0.4) : 0.0) * maxKneeRad;
    final kneeFlexL = (math.sin(phiL - 0.4) > 0 ? math.sin(phiL - 0.4) : 0.0) * maxKneeRad;

    // Right Knee & Foot positions
    final kneeR = Vector3(
      hipRight.x,
      hipRight.y - thighLen * math.cos(thighAngleR),
      hipRight.z + thighLen * math.sin(thighAngleR),
    );
    final footR = Vector3(
      kneeR.x,
      kneeR.y - shinLen * math.cos(thighAngleR - kneeFlexR),
      kneeR.z + shinLen * math.sin(thighAngleR - kneeFlexR),
    );

    // Left Knee & Foot positions
    final kneeL = Vector3(
      hipLeft.x,
      hipLeft.y - thighLen * math.cos(thighAngleL),
      hipLeft.z + thighLen * math.sin(thighAngleL),
    );
    final footL = Vector3(
      kneeL.x,
      kneeL.y - shinLen * math.cos(thighAngleL - kneeFlexL),
      kneeL.z + shinLen * math.sin(thighAngleL - kneeFlexL),
    );

    // Spine & Neck & Head
    final shoulderCenter = Vector3(
      pelvisCenter.x,
      pelvisCenter.y + torsoLen * math.cos(leanRad),
      pelvisCenter.z + torsoLen * math.sin(leanRad),
    );
    final shoulderLeft = Vector3(shoulderCenter.x - shoulderWidth * 0.5, shoulderCenter.y, shoulderCenter.z);
    final shoulderRight = Vector3(shoulderCenter.x + shoulderWidth * 0.5, shoulderCenter.y, shoulderCenter.z);

    final headCenter = Vector3(
      shoulderCenter.x,
      shoulderCenter.y + headRadius + 6.0,
      shoulderCenter.z + 4.0,
    );

    // Arms swing in counter-phase to legs (Right arm swings with Left leg)
    final armAngleR = -math.sin(phiR) * 0.45;
    final armAngleL = -math.sin(phiL) * 0.45;

    final elbowR = Vector3(
      shoulderRight.x,
      shoulderRight.y - armLen * math.cos(armAngleR),
      shoulderRight.z + armLen * math.sin(armAngleR),
    );
    final handR = Vector3(
      elbowR.x,
      elbowR.y - forearmLen * math.cos(armAngleR + 0.3),
      elbowR.z + forearmLen * math.sin(armAngleR + 0.3),
    );

    final elbowL = Vector3(
      shoulderLeft.x,
      shoulderLeft.y - armLen * math.cos(armAngleL),
      shoulderLeft.z + armLen * math.sin(armAngleL),
    );
    final handL = Vector3(
      elbowL.x,
      elbowL.y - forearmLen * math.cos(armAngleL + 0.3),
      elbowL.z + forearmLen * math.sin(armAngleL + 0.3),
    );

    // 1. Draw Bones with metallic anatomical tubes
    final bonePaint = Paint()
      ..color = theme.textPrimary
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final leftBonePaint = Paint()
      ..color = theme.accent
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final rightBonePaint = Paint()
      ..color = theme.secondaryAccent
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Pelvis Bar
    _drawSegment(canvas, size, camera, hipLeft, hipRight, bonePaint);

    // Spine
    _drawSegment(canvas, size, camera, pelvisCenter, shoulderCenter, bonePaint);

    // Shoulder Bar
    _drawSegment(canvas, size, camera, shoulderLeft, shoulderRight, bonePaint);

    // Right Leg
    _drawSegment(canvas, size, camera, hipRight, kneeR, rightBonePaint);
    _drawSegment(canvas, size, camera, kneeR, footR, rightBonePaint);

    // Left Leg
    _drawSegment(canvas, size, camera, hipLeft, kneeL, leftBonePaint);
    _drawSegment(canvas, size, camera, kneeL, footL, leftBonePaint);

    // Right Arm
    _drawSegment(canvas, size, camera, shoulderRight, elbowR, bonePaint);
    _drawSegment(canvas, size, camera, elbowR, handR, bonePaint);

    // Left Arm
    _drawSegment(canvas, size, camera, shoulderLeft, elbowL, bonePaint);
    _drawSegment(canvas, size, camera, elbowL, handL, bonePaint);

    // 2. Draw Spherical Anatomical Joints
    final jointList = [
      hipLeft, hipRight, kneeL, kneeR, footL, footR,
      shoulderLeft, shoulderRight, elbowL, elbowR, handL, handR,
    ];

    for (final j in jointList) {
      final p = camera.projectVector(j, size);
      if (p != null) {
        final dist = (j - camera.eye).length;
        final jRad = (5.5 * 380.0 / dist).clamp(2.5, 10.0);
        final jointPaint = Paint()..color = theme.panelBackground;
        canvas.drawCircle(p.screen, jRad, jointPaint);
        final jointBorder = Paint()
          ..color = theme.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(p.screen, jRad, jointBorder);
      }
    }

    // 3. Draw Head Cranium Sphere
    final headProj = camera.projectVector(headCenter, size);
    if (headProj != null) {
      final dist = (headCenter - camera.eye).length;
      final hRad = (headRadius * 380.0 / dist).clamp(6.0, 26.0);
      final headPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.8,
          colors: [Colors.white, theme.accent, const Color(0xFF0F172A)],
        ).createShader(Rect.fromCircle(center: headProj.screen, radius: hRad));
      canvas.drawCircle(headProj.screen, hRad, headPaint);
    }

    // 4. Ground Reaction Force (GRF) Vector Arrow under stance foot
    if (showGRFVectors) {
      final stanceFootPos = footR.y < footL.y ? footR : footL;
      final grfMagnitude = 45.0 + 20.0 * math.sin(gaitPhase * 2 * math.pi).abs();
      final grfArrowTip = Vector3(stanceFootPos.x, stanceFootPos.y + grfMagnitude, stanceFootPos.z);

      final pOrigin = camera.projectVector(stanceFootPos, size);
      final pTip = camera.projectVector(grfArrowTip, size);
      if (pOrigin != null && pTip != null) {
        final grfPaint = Paint()
          ..color = const Color(0xFF00E676)
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(pOrigin.screen, pTip.screen, grfPaint);

        // Arrow head indicator
        canvas.drawCircle(pTip.screen, 4.0, Paint()..color = const Color(0xFF00E676));

        final tp = TextPainter(
          text: const TextSpan(
            text: 'GRF',
            style: TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(pTip.screen.dx + 4, pTip.screen.dy - 6));
      }
    }
  }

  void _drawSegment(Canvas canvas, Size size, SimCamera3D camera, Vector3 a, Vector3 b, Paint paint) {
    final pa = camera.projectVector(a, size);
    final pb = camera.projectVector(b, size);
    if (pa != null && pb != null) {
      canvas.drawLine(pa.screen, pb.screen, paint);
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab Biomechanical Bipedal Walker Gait Kinematics
cadence = $cadence;  % steps/min
stepLength = $stepLength; % cm
kneeMax = $kneeFlexionMax; % deg

strideFreq = cadence / 120;
speed = (cadence / 60) * (stepLength / 100);

fprintf('Walking Velocity: %.2f m/s (%.1f km/h)\\n', speed, speed * 3.6);
fprintf('Gait Stride Frequency: %.2f Hz\\n', strideFreq);

t = linspace(0, 2, 200);
theta_thigh = 0.5 * sin(2 * pi * strideFreq * t);
theta_knee = max(0, sin(2 * pi * strideFreq * t - 0.4)) * deg2rad(kneeMax);

figure('Name', 'Gait Joint Excursions');
subplot(2,1,1);
plot(t, rad2deg(theta_thigh), 'b', 'LineWidth', 1.5);
title('Sagittal Thigh & Knee Kinematics');
ylabel('Thigh Angle (deg)'); grid on;

subplot(2,1,2);
plot(t, rad2deg(theta_knee), 'r', 'LineWidth', 1.5);
ylabel('Knee Flexion (deg)'); xlabel('Time (s)'); grid on;
''';
  }
}
