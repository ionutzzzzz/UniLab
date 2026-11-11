import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';

class RLCResonanceSim extends SimulationModel {
  double rVal = 20.0; // Ohms
  double lVal = 0.05; // Henry (50 mH)
  double cVal = 10.0e-6; // Farads (10 uF)
  double inputFreq = 225.0; // Hz
  String waveform = 'Sine Wave';

  double q = 0.0; // Charge
  double iCurrent = 0.0; // Current dq/dt

  final List<double> _vinBuffer = [];
  final List<double> _vcBuffer = [];
  final int maxBuffer = 300;

  RLCResonanceSim()
      : super(
          id: 'electrical_rlc_resonance',
          name: 'RLC Circuit & Resonance Oscilloscope',
          description:
              '2nd-order dynamic RLC resonant circuit with dual-channel oscilloscope telemetry showing input vs capacitor transient voltages, quality factor Q, and frequency resonance curves.',
          category: SimCategory.electrical,
          dimension: SimDimension.twoD,
          tags: ['Circuit', 'RLC', 'Resonance', 'Oscilloscope', 'Bode Plot', 'Electronics'],
          parameters: [
            SimParameter(
              id: 'inputFreq',
              name: 'Excitation Frequency (Hz)',
              category: 'Source',
              min: 50.0,
              max: 600.0,
              step: 10.0,
              defaultValue: 225.0,
            ),
            SimParameter(
              id: 'rVal',
              name: 'Resistance (R)',
              category: 'Components',
              unit: 'Ω',
              min: 2.0,
              max: 100.0,
              step: 2.0,
              defaultValue: 20.0,
            ),
            SimParameter(
              id: 'lVal',
              name: 'Inductance (L)',
              category: 'Components',
              unit: 'mH',
              min: 10.0,
              max: 200.0,
              step: 10.0,
              defaultValue: 50.0, // Stored in mH for UI, converted to H
            ),
            SimParameter(
              id: 'waveform',
              name: 'Input Waveform',
              category: 'Source',
              type: SimParameterType.dropdown,
              options: ['Sine Wave', 'Square Wave', 'Step Pulse'],
              defaultValue: 'Sine Wave',
            ),
          ],
          presets: [
            SimPreset(
              id: 'resonance_peak',
              name: 'Resonant Peak (f = f0)',
              description: 'Circuit excitation tuned exactly to natural frequency producing maximum voltage gain.',
              parameters: {'inputFreq': 225.0, 'rVal': 10.0},
            ),
            SimPreset(
              id: 'underdamped_ring',
              name: 'Underdamped Transient Ringing',
              description: 'Step pulse response exhibiting low-damping harmonic ring-down.',
              parameters: {'inputFreq': 100.0, 'rVal': 5.0, 'waveform': 'Square Wave'},
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
    q = 0.0;
    iCurrent = 0.0;
    _vinBuffer.clear();
    _vcBuffer.clear();
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'inputFreq') inputFreq = (value as num).toDouble();
    if (paramId == 'rVal') rVal = (value as num).toDouble();
    if (paramId == 'lVal') lVal = (value as num).toDouble() * 1e-3;
    if (paramId == 'waveform') waveform = value.toString();
  }

  @override
  void step(double dt) {
    final subSteps = 6;
    final h = dt / subSteps;

    for (int s = 0; s < subSteps; s++) {
      final tNow = time + s * h;
      double vin = 5.0 * math.sin(2.0 * math.pi * inputFreq * tNow);
      if (waveform.contains('Square')) {
        vin = vin >= 0 ? 5.0 : -5.0;
      }

      // d2q/dt2 = (Vin - R*i - q/C) / L
      final vc = q / cVal;
      final di = (vin - rVal * iCurrent - vc) / lVal;

      iCurrent += di * h;
      q += iCurrent * h;
    }

    time += dt;
    stepIndex++;

    double vinNow = 5.0 * math.sin(2.0 * math.pi * inputFreq * time);
    if (waveform.contains('Square')) vinNow = vinNow >= 0 ? 5.0 : -5.0;

    _vinBuffer.add(vinNow);
    _vcBuffer.add(q / cVal);

    if (_vinBuffer.length > maxBuffer) {
      _vinBuffer.removeAt(0);
      _vcBuffer.removeAt(0);
    }
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {'q': q, 'i': iCurrent},
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    q = snapshot.state['q'] as double;
    iCurrent = snapshot.state['i'] as double;
  }

  @override
  Map<String, num> getMetrics() {
    final f0 = 1.0 / (2.0 * math.pi * math.sqrt(lVal * cVal));
    final qFactor = (1.0 / rVal) * math.sqrt(lVal / cVal);
    final dampingRatio = (rVal / 2.0) * math.sqrt(cVal / lVal);

    return {
      'Resonant Frequency f0 (Hz)': f0,
      'Quality Factor (Q)': qFactor,
      'Damping Ratio (zeta)': dampingRatio,
      'Capacitor Voltage Vc (V)': q / cVal,
    };
  }

  @override
  void render2D(Canvas canvas, Size size, SimTheme theme) {
    final scopeTop = 20.0;
    final scopeHeight = size.height - 40.0;

    // 1. Oscilloscope CRT Screen Box
    final bgPaint = Paint()..color = const Color(0xFF0D181D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(20, scopeTop, size.width - 40, scopeHeight), const Radius.circular(8)),
      bgPaint,
    );

    // 2. Reticle Grid Lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1E3942).withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    final centerY = scopeTop + scopeHeight / 2.0;
    for (double x = 20; x < size.width - 20; x += 35) {
      canvas.drawLine(Offset(x, scopeTop), Offset(x, scopeTop + scopeHeight), gridPaint);
    }
    for (double y = scopeTop; y < scopeTop + scopeHeight; y += 30) {
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), gridPaint);
    }

    if (_vinBuffer.length < 2) return;

    // 3. Channel 1: Input Voltage (Cyan)
    final ch1Paint = Paint()
      ..color = theme.accent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final stepX = (size.width - 40) / maxBuffer;
    final p1 = Path();
    for (int i = 0; i < _vinBuffer.length; i++) {
      final x = 20 + i * stepX;
      final y = centerY - _vinBuffer[i] * 6.5;
      if (i == 0) {
        p1.moveTo(x, y);
      } else {
        p1.lineTo(x, y);
      }
    }
    canvas.drawPath(p1, ch1Paint);

    // 4. Channel 2: Capacitor Voltage (Yellow)
    final ch2Paint = Paint()
      ..color = const Color(0xFFFFD600)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final p2 = Path();
    for (int i = 0; i < _vcBuffer.length; i++) {
      final x = 20 + i * stepX;
      final y = centerY - _vcBuffer[i] * 6.5;
      if (i == 0) {
        p2.moveTo(x, y);
      } else {
        p2.lineTo(x, y);
      }
    }
    canvas.drawPath(p2, ch2Paint);

    // 5. Channel Legend
    final tp = TextPainter(
      text: const TextSpan(
        children: [
          TextSpan(text: 'CH1: Vin (Cyan)   ', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 11)),
          TextSpan(text: 'CH2: Vc (Yellow)', style: TextStyle(color: Color(0xFFFFD600), fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(35, scopeTop + 12));
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab RLC Circuit Frequency Response
R = $rVal; L = $lVal; C = $cVal;
f0 = 1 / (2*pi*sqrt(L*C));
disp(['Natural Frequency f0: ', num2str(f0), ' Hz']);

s = tf('s');
H = 1 / (L*C*s^2 + R*C*s + 1);

figure('Name', 'Bode Frequency Response');
bode(H); grid on;
title('RLC Circuit Second-Order Transfer Function');
''';
  }
}
