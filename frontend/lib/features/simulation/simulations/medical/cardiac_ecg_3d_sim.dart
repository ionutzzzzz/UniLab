import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class CardiacECG3DSim extends SimulationModel {
  double heartRate = 72.0; // BPM
  String arrhythmiaType = 'Normal Sinus Rhythm';
  double noiseLevel = 0.05;
  double stElevation = 0.0;

  double cardiacPhase = 0.0; // 0.0 to 1.0 for each heartbeat
  final List<double> _ecgBuffer = [];
  final int maxBufferPoints = 400;

  CardiacECG3DSim()
      : super(
          id: 'medical_cardiac_ecg_3d',
          name: 'Cardiac Electrophysiology & 12-Lead ECG (3D)',
          description:
              'Simultaneous 3D anatomical heart electromechanical contraction and clinical 12-lead ECG monitor telemetry generating realistic P-Q-R-S-T complexes across cardiac arrhythmias.',
          category: SimCategory.medical,
          dimension: SimDimension.threeD,
          tags: ['Biomedical', '3D', 'Cardiology', 'ECG', 'Arrhythmia', 'Electrophysiology'],
          parameters: [
            SimParameter(
              id: 'heartRate',
              name: 'Heart Rate (BPM)',
              category: 'Vitals',
              unit: 'BPM',
              min: 35.0,
              max: 210.0,
              step: 5.0,
              defaultValue: 72.0,
            ),
            SimParameter(
              id: 'arrhythmiaType',
              name: 'Cardiac Rhythm',
              category: 'Electrophysiology',
              type: SimParameterType.dropdown,
              options: [
                'Normal Sinus Rhythm',
                'Ventricular Tachycardia (V-Tach)',
                'Atrial Fibrillation (A-Fib)',
                'Sinus Bradycardia (45 BPM)',
                'Premature Ventricular Contraction (PVC)',
              ],
              defaultValue: 'Normal Sinus Rhythm',
            ),
            SimParameter(
              id: 'stElevation',
              name: 'ST Segment Elevation (STEMI)',
              category: 'Pathology',
              min: 0.0,
              max: 0.8,
              step: 0.05,
              defaultValue: 0.0,
            ),
          ],
          presets: [
            SimPreset(
              id: 'normal_sinus',
              name: 'Normal Sinus Rhythm (72 BPM)',
              description: 'Healthy adult cardiac conduction with distinct P, QRS, and T waves.',
              parameters: {'heartRate': 72.0, 'arrhythmiaType': 'Normal Sinus Rhythm', 'stElevation': 0.0},
            ),
            SimPreset(
              id: 'vtach',
              name: 'Ventricular Tachycardia (160 BPM)',
              description: 'Dangerous wide-complex tachycardia without organized P waves.',
              parameters: {'heartRate': 160.0, 'arrhythmiaType': 'Ventricular Tachycardia (V-Tach)', 'stElevation': 0.0},
            ),
            SimPreset(
              id: 'stemi',
              name: 'Acute Myocardial Infarction (STEMI)',
              description: 'Severe ST-segment elevation indicating coronary artery occlusion.',
              parameters: {'heartRate': 85.0, 'arrhythmiaType': 'Normal Sinus Rhythm', 'stElevation': 0.5},
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
    cardiacPhase = 0.0;
    _ecgBuffer.clear();
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'heartRate') heartRate = (value as num).toDouble();
    if (paramId == 'arrhythmiaType') arrhythmiaType = value.toString();
    if (paramId == 'stElevation') stElevation = (value as num).toDouble();
  }

  @override
  void step(double dt) {
    final beatFrequency = heartRate / 60.0;
    cardiacPhase = (cardiacPhase + beatFrequency * dt) % 1.0;
    time += dt;
    stepIndex++;

    // Synthesize real-time P-Q-R-S-T voltage waveform
    final ecgVoltage = _synthesizeECG(cardiacPhase);
    _ecgBuffer.add(ecgVoltage);
    if (_ecgBuffer.length > maxBufferPoints) {
      _ecgBuffer.removeAt(0);
    }
  }

  double _synthesizeECG(double p) {
    if (arrhythmiaType.contains('V-Tach')) {
      // Wide QRS sinusoidal oscillation
      return 1.4 * math.sin(2.0 * math.pi * p) + 0.3 * math.sin(4.0 * math.pi * p);
    }

    if (arrhythmiaType.contains('A-Fib')) {
      // Baseline fibrillatory flutter with irregular QRS
      final flutter = 0.08 * math.sin(2.0 * math.pi * 7.0 * p);
      if (p > 0.35 && p < 0.42) return 1.5 + flutter; // QRS
      return flutter;
    }

    // Standard Normal Sinus P-Q-R-S-T synthesis:
    // P wave: atrial depolarization (0.12 - 0.20)
    final pWave = 0.22 * math.exp(-math.pow((p - 0.16) / 0.03, 2));

    // Q wave: septal depolarization (0.28)
    final qWave = -0.18 * math.exp(-math.pow((p - 0.28) / 0.015, 2));

    // R wave: ventricular depolarization peak (0.32)
    final rWave = 1.65 * math.exp(-math.pow((p - 0.32) / 0.02, 2));

    // S wave: late ventricular depolarization (0.36)
    final sWave = -0.35 * math.exp(-math.pow((p - 0.36) / 0.018, 2));

    // ST segment elevation + T wave ventricular repolarization (0.50 - 0.65)
    final stMod = (p > 0.38 && p < 0.52) ? stElevation : 0.0;
    final tWave = 0.38 * math.exp(-math.pow((p - 0.58) / 0.06, 2));

    final noise = (math.Random().nextDouble() - 0.5) * noiseLevel;

    return pWave + qWave + rWave + sWave + tWave + stMod + noise;
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {'phase': cardiacPhase, 'ecg': List<double>.from(_ecgBuffer)},
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    cardiacPhase = snapshot.state['phase'] as double;
    _ecgBuffer.clear();
    if (snapshot.state['ecg'] != null) {
      _ecgBuffer.addAll(snapshot.state['ecg'] as List<double>);
    }
  }

  @override
  Map<String, dynamic> getMetrics() {
    return {
      'Heart Rate (BPM)': heartRate,
      'RR Interval (ms)': (60.0 / heartRate) * 1000.0,
      'ST Segment Elevation': stElevation,
      'Contraction State': cardiacPhase > 0.28 && cardiacPhase < 0.45 ? 'SYSTOLE' : 'DIASTOLE',
    };
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    // 1. Draw 3D Pulsating Heart Anatomy Chambers in Upper Viewport (0% - 62% height)
    final isSystole = cardiacPhase > 0.28 && cardiacPhase < 0.45;
    final contraction = isSystole ? 0.82 : (1.0 + 0.05 * math.sin(cardiacPhase * 2 * math.pi));
    final heartViewportSize = Size(size.width, size.height * 0.62);

    _render3DHeartChambers(canvas, heartViewportSize, camera, contraction, isSystole, theme);

    // 2. Draw Clinical Medical Monitor ECG Grid & Strip (Bottom 38% of canvas)
    _renderECGStrip(canvas, size, theme);
  }

  void _render3DHeartChambers(Canvas canvas, Size size, SimCamera3D camera, double contraction, bool isSystole, SimTheme theme) {
    final heartCenter = const Vector3(0, 45, 0);

    // Left & Right Ventricles Stylized 3D Volume
    const segments = 20;
    final heartPaint = Paint()
      ..color = isSystole ? const Color(0xFFFF1744) : const Color(0xFFD50000)
      ..style = PaintingStyle.fill;

    // Glowing cardiac aura during systole peak
    if (isSystole) {
      final proj = camera.projectVector(heartCenter, size);
      if (proj != null) {
        final auraPaint = Paint()
          ..color = const Color(0xFFFF1744).withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22.0);
        canvas.drawCircle(proj.screen, 45.0, auraPaint);
      }
    }

    // 3D Chamber Contour Rings
    for (int ring = -3; ring <= 3; ring++) {
      final y = heartCenter.y + ring * 10.0 * contraction;
      final radius = math.max(10.0, (38.0 - (ring * ring) * 3.0) * contraction);

      final path = Path();
      bool first = true;
      for (int i = 0; i <= segments; i++) {
        final a = i * (2.0 * math.pi / segments);
        final x = radius * math.cos(a);
        final z = radius * math.sin(a);
        final p = camera.project(x, y, z, size);
        if (p != null) {
          if (first) {
            path.moveTo(p.screen.dx, p.screen.dy);
            first = false;
          } else {
            path.lineTo(p.screen.dx, p.screen.dy);
          }
        }
      }
      path.close();
      canvas.drawPath(path, heartPaint);
    }
  }

  void _renderECGStrip(Canvas canvas, Size size, SimTheme theme) {
    final stripTop = size.height * 0.65;
    final stripHeight = size.height - stripTop;

    // Monitor background
    final bgPaint = Paint()..color = const Color(0xFF0A1017);
    canvas.drawRect(Rect.fromLTWH(0, stripTop, size.width, stripHeight), bgPaint);

    // Clinical Grid lines (1mm and 5mm equivalents)
    final gridPaint = Paint()
      ..color = const Color(0xFF1E3A2F).withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 18.0) {
      canvas.drawLine(Offset(x, stripTop), Offset(x, size.height), gridPaint);
    }
    for (double y = stripTop; y < size.height; y += 18.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (_ecgBuffer.length < 2) return;

    // Glowing Neon Green ECG Trace
    final ecgPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final centerY = stripTop + stripHeight * 0.55;
    final stepX = size.width / maxBufferPoints;

    final path = Path();
    for (int i = 0; i < _ecgBuffer.length; i++) {
      final x = i * stepX;
      final y = centerY - _ecgBuffer[i] * 32.0;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, ecgPaint);

    // Heart Rate Digital Monitor Readout
    final tp = TextPainter(
      text: TextSpan(
        text: 'HR: ${heartRate.toInt()} BPM  |  $arrhythmiaType',
        style: const TextStyle(color: Color(0xFF00E676), fontSize: 13, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(16, stripTop + 10));
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab Cardiac Electrophysiology & ECG Generator
HR = $heartRate; % BPM
dt = 0.002;
t = 0:dt:2;

% Synthetic P-Q-R-S-T Multi-dipole function
ecg = 0.22*exp(-((mod(t*HR/60,1)-0.16)/0.03).^2) ...
    - 0.18*exp(-((mod(t*HR/60,1)-0.28)/0.015).^2) ...
    + 1.65*exp(-((mod(t*HR/60,1)-0.32)/0.02).^2) ...
    - 0.35*exp(-((mod(t*HR/60,1)-0.36)/0.018).^2) ...
    + 0.38*exp(-((mod(t*HR/60,1)-0.58)/0.06).^2);

figure('Name', 'Cardiology Clinical ECG Lead II');
plot(t, ecg, 'g', 'LineWidth', 1.5);
grid on; xlabel('Time (s)'); ylabel('Voltage (mV)');
title(['12-Lead ECG - ', '$arrhythmiaType']);
''';
  }
}
