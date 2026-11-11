import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';

class WaveOpticsSim extends SimulationModel {
  static const int gridW = 100;
  static const int gridH = 80;

  double waveSpeed = 0.45;
  double damping = 0.003;
  double frequency = 1.4;
  double slitDistance = 14.0;
  double slitWidth = 4.0;
  bool isDoubleSlit = true;

  List<double> _uCurrent = List.filled(gridW * gridH, 0.0);
  List<double> _uPrev = List.filled(gridW * gridH, 0.0);
  List<double> _uNext = List.filled(gridW * gridH, 0.0);
  List<bool> _barrier = List.filled(gridW * gridH, false);

  WaveOpticsSim()
      : super(
          id: 'physics_wave_optics',
          name: 'Wave Optics & Ripple Tank (Interference)',
          description:
              'Solves the 2D wave equation for optical wave propagation, Young\'s double-slit interference fringes, diffraction, and wave speed modulation.',
          category: SimCategory.physics,
          dimension: SimDimension.twoD,
          tags: ['Wave Equation', 'Diffraction', 'Young Double Slit', 'Interference', 'Optics'],
          parameters: [
            SimParameter(
              id: 'frequency',
              name: 'Source Frequency (Hz)',
              category: 'Wave Source',
              min: 0.5,
              max: 3.0,
              step: 0.1,
              defaultValue: 1.4,
            ),
            SimParameter(
              id: 'waveSpeed',
              name: 'Wave Phase Speed',
              category: 'Medium',
              min: 0.2,
              max: 0.5,
              step: 0.02,
              defaultValue: 0.45,
            ),
            SimParameter(
              id: 'slitDistance',
              name: 'Slit Separation (d)',
              category: 'Aperture',
              min: 6.0,
              max: 30.0,
              step: 2.0,
              defaultValue: 14.0,
            ),
            SimParameter(
              id: 'isDoubleSlit',
              name: 'Double Slit Barrier',
              category: 'Aperture',
              type: SimParameterType.toggle,
              defaultValue: true,
            ),
            SimParameter(
              id: 'damping',
              name: 'Boundary Absorption',
              category: 'Medium',
              min: 0.001,
              max: 0.02,
              step: 0.001,
              defaultValue: 0.003,
            ),
          ],
          presets: [
            SimPreset(
              id: 'young_double_slit',
              name: 'Young\'s Double Slit Interference',
              description: 'Classic dual-slit diffraction fringes demonstrating wave interference.',
              parameters: {'frequency': 1.4, 'slitDistance': 14.0, 'isDoubleSlit': true},
            ),
            SimPreset(
              id: 'single_slit',
              name: 'Single Slit Diffraction',
              description: 'Central diffraction maximum with secondary Airy-like fringes.',
              parameters: {'frequency': 1.4, 'slitDistance': 0.0, 'isDoubleSlit': false},
            ),
            SimPreset(
              id: 'high_frequency',
              name: 'Short Wavelength Ray Limit',
              description: 'High frequency wave exhibiting sharp geometric shadow boundaries.',
              parameters: {'frequency': 2.8, 'slitDistance': 20.0, 'isDoubleSlit': true},
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
    _uCurrent = List.filled(gridW * gridH, 0.0);
    _uPrev = List.filled(gridW * gridH, 0.0);
    _uNext = List.filled(gridW * gridH, 0.0);
    _rebuildBarrier();
  }

  void _rebuildBarrier() {
    _barrier = List.filled(gridW * gridH, false);
    final barrierX = 35;
    final centerY = gridH ~/ 2;

    for (int y = 0; y < gridH; y++) {
      _barrier[y * gridW + barrierX] = true;
    }

    if (isDoubleSlit) {
      final s1 = (centerY - slitDistance / 2.0).round();
      final s2 = (centerY + slitDistance / 2.0).round();
      final halfW = (slitWidth / 2.0).round();

      for (int dy = -halfW; dy <= halfW; dy++) {
        final y1 = s1 + dy;
        final y2 = s2 + dy;
        if (y1 >= 0 && y1 < gridH) _barrier[y1 * gridW + barrierX] = false;
        if (y2 >= 0 && y2 < gridH) _barrier[y2 * gridW + barrierX] = false;
      }
    } else {
      final halfW = (slitWidth / 2.0).round();
      for (int dy = -halfW; dy <= halfW; dy++) {
        final y = centerY + dy;
        if (y >= 0 && y < gridH) _barrier[y * gridW + barrierX] = false;
      }
    }
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'frequency') frequency = (value as num).toDouble();
    if (paramId == 'waveSpeed') waveSpeed = (value as num).toDouble();
    if (paramId == 'slitDistance') {
      slitDistance = (value as num).toDouble();
      _rebuildBarrier();
    }
    if (paramId == 'isDoubleSlit') {
      isDoubleSlit = value as bool;
      _rebuildBarrier();
    }
    if (paramId == 'damping') damping = (value as num).toDouble();
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;

    // Oscillating wave source on left boundary
    final sourceY = gridH ~/ 2;
    for (int y = sourceY - 20; y <= sourceY + 20; y++) {
      if (y >= 0 && y < gridH) {
        _uCurrent[y * gridW + 4] = math.sin(2.0 * math.pi * frequency * time);
      }
    }

    final c2 = waveSpeed * waveSpeed;

    // Finite difference wave equation update
    for (int y = 1; y < gridH - 1; y++) {
      final row = y * gridW;
      for (int x = 1; x < gridW - 1; x++) {
        final idx = row + x;
        if (_barrier[idx]) {
          _uNext[idx] = 0.0;
          continue;
        }

        final laplacian = _uCurrent[idx + 1] +
            _uCurrent[idx - 1] +
            _uCurrent[idx + gridW] +
            _uCurrent[idx - gridW] -
            4.0 * _uCurrent[idx];

        final unext = 2.0 * _uCurrent[idx] -
            _uPrev[idx] +
            c2 * laplacian -
            damping * (_uCurrent[idx] - _uPrev[idx]);

        _uNext[idx] = unext;
      }
    }

    // Boundary damping
    for (int y = 0; y < gridH; y++) {
      _uNext[y * gridW] *= 0.95;
      _uNext[y * gridW + gridW - 1] *= 0.95;
    }
    for (int x = 0; x < gridW; x++) {
      _uNext[x] *= 0.95;
      _uNext[(gridH - 1) * gridW + x] *= 0.95;
    }

    // Cycle buffers
    final temp = _uPrev;
    _uPrev = _uCurrent;
    _uCurrent = _uNext;
    _uNext = temp;
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {
        'current': List<double>.from(_uCurrent),
        'prev': List<double>.from(_uPrev),
      },
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    _uCurrent = List<double>.from(snapshot.state['current'] as List<double>);
    _uPrev = List<double>.from(snapshot.state['prev'] as List<double>);
    _rebuildBarrier();
  }

  @override
  Map<String, num> getMetrics() {
    double maxAmp = 0.0;
    for (int i = 0; i < _uCurrent.length; i++) {
      final amp = _uCurrent[i].abs();
      if (amp > maxAmp) maxAmp = amp;
    }
    return {
      'Peak Wave Amplitude': maxAmp,
      'Source Frequency (Hz)': frequency,
      'Phase Speed (c)': waveSpeed,
    };
  }

  @override
  void render2D(Canvas canvas, Size size, SimTheme theme) {
    final cellW = size.width / gridW;
    final cellH = size.height / gridH;

    // Render Wave Intensity Heatmap
    for (int y = 0; y < gridH; y++) {
      final row = y * gridW;
      for (int x = 0; x < gridW; x++) {
        final idx = row + x;

        if (_barrier[idx]) {
          final barrierPaint = Paint()..color = theme.textMuted.withValues(alpha: 0.9);
          canvas.drawRect(Rect.fromLTWH(x * cellW, y * cellH, cellW + 0.5, cellH + 0.5), barrierPaint);
          continue;
        }

        final u = _uCurrent[idx].clamp(-1.0, 1.0);
        if (u.abs() > 0.03) {
          final color = u > 0
              ? Color.lerp(theme.background, theme.accent, u)!
              : Color.lerp(theme.background, const Color(0xFFFF5252), -u)!;

          final wavePaint = Paint()..color = color;
          canvas.drawRect(Rect.fromLTWH(x * cellW, y * cellH, cellW + 0.5, cellH + 0.5), wavePaint);
        }
      }
    }

    // Right screen detector line
    final screenX = (gridW - 6) * cellW;
    final screenPaint = Paint()
      ..color = theme.warning.withValues(alpha: 0.6)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(screenX, 0), Offset(screenX, size.height), screenPaint);

    // Draw intensity curve at detector screen
    final path = Path();
    bool first = true;
    for (int y = 0; y < gridH; y++) {
      final val = _uCurrent[y * gridW + gridW - 7];
      final intensity = val * val * 45.0;
      final px = screenX + intensity;
      final py = y * cellH;
      if (first) {
        path.moveTo(px, py);
        first = false;
      } else {
        path.lineTo(px, py);
      }
    }
    final curvePaint = Paint()
      ..color = theme.warning
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, curvePaint);
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab 2D Wave Optics & Young Double-Slit Diffraction
Nx = $gridW; Ny = $gridH;
c = $waveSpeed; dt = 0.1;
u = zeros(Ny, Nx); u_prev = zeros(Ny, Nx);

% Run 2D Wave Equation Finite Difference
for step = 1:300
    % Source excitation
    u(Ny/2, 5) = sin(2*pi*$frequency * step * dt);
    
    lap = del2(u);
    u_next = 2*u - u_prev + (c*dt)^2 * lap;
    u_prev = u;
    u = u_next;
end

figure('Name', 'Wave Interference Intensity');
imagesc(u.^2); colormap('hot'); colorbar;
title('Optical Wave Interference Fringes');
''';
  }
}
