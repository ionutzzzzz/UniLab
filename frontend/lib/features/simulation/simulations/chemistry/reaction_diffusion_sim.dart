import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';

class ReactionDiffusionSim extends SimulationModel {
  static const int gridW = 75;
  static const int gridH = 55;

  double du = 0.2097;
  double dv = 0.105;
  double feed = 0.0545; // F
  double kill = 0.062; // k

  List<double> _u = List.filled(gridW * gridH, 1.0);
  List<double> _v = List.filled(gridW * gridH, 0.0);
  List<double> _nextU = List.filled(gridW * gridH, 1.0);
  List<double> _nextV = List.filled(gridW * gridH, 0.0);

  ReactionDiffusionSim()
      : super(
          id: 'chemistry_reaction_diffusion',
          name: 'Reaction-Diffusion (Turing Morphogenesis)',
          description:
              'Nonlinear Gray-Scott reaction-diffusion partial differential equations simulating spontaneous biological morphogenesis, Belousov-Zhabotinsky spirals, spots, and labyrinthine Turing patterns.',
          category: SimCategory.chemistry,
          dimension: SimDimension.twoD,
          tags: ['Turing Pattern', 'Morphogenesis', 'Gray-Scott', 'PDE', 'Nonlinear Chemistry'],
          parameters: [
            SimParameter(
              id: 'feed',
              name: 'Feed Rate (F)',
              category: 'Reaction Kinetics',
              min: 0.01,
              max: 0.09,
              step: 0.002,
              defaultValue: 0.0545,
            ),
            SimParameter(
              id: 'kill',
              name: 'Kill Rate (k)',
              category: 'Reaction Kinetics',
              min: 0.045,
              max: 0.07,
              step: 0.001,
              defaultValue: 0.062,
            ),
            SimParameter(
              id: 'du',
              name: 'Diffusion Rate Du',
              category: 'Diffusion',
              min: 0.1,
              max: 0.3,
              step: 0.01,
              defaultValue: 0.2097,
            ),
            SimParameter(
              id: 'dv',
              name: 'Diffusion Rate Dv',
              category: 'Diffusion',
              min: 0.05,
              max: 0.18,
              step: 0.01,
              defaultValue: 0.105,
            ),
          ],
          presets: [
            SimPreset(
              id: 'turing_stripes',
              name: 'Zebra / Fingerprint Stripes',
              description: 'Stable labyrinthine stripes pattern.',
              parameters: {'feed': 0.035, 'kill': 0.065},
            ),
            SimPreset(
              id: 'leopard_spots',
              name: 'Leopard / Mitosis Spots',
              description: 'Self-replicating division spots and colonies.',
              parameters: {'feed': 0.0545, 'kill': 0.062},
            ),
            SimPreset(
              id: 'spirals_chaos',
              name: 'BZ Rotating Spirals',
              description: 'Dynamic rotating scroll waves and spiral waves.',
              parameters: {'feed': 0.018, 'kill': 0.051},
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
    _u = List.filled(gridW * gridH, 1.0);
    _v = List.filled(gridW * gridH, 0.0);
    _nextU = List.filled(gridW * gridH, 1.0);
    _nextV = List.filled(gridW * gridH, 0.0);

    // Seed initial perturbation cluster at center
    final cx = gridW ~/ 2;
    final cy = gridH ~/ 2;
    for (int y = cy - 6; y <= cy + 6; y++) {
      for (int x = cx - 6; x <= cx + 6; x++) {
        _v[y * gridW + x] = 1.0;
      }
    }
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'feed') feed = (value as num).toDouble();
    if (paramId == 'kill') kill = (value as num).toDouble();
    if (paramId == 'du') du = (value as num).toDouble();
    if (paramId == 'dv') dv = (value as num).toDouble();
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;

    const subSteps = 4;
    for (int s = 0; s < subSteps; s++) {
      _pdeStep();
    }
  }

  void _pdeStep() {
    for (int y = 1; y < gridH - 1; y++) {
      final row = y * gridW;
      for (int x = 1; x < gridW - 1; x++) {
        final idx = row + x;
        final u = _u[idx];
        final v = _v[idx];

        // 5-point discrete Laplacian operator
        final lapU = _u[idx + 1] + _u[idx - 1] + _u[idx + gridW] + _u[idx - gridW] - 4.0 * u;
        final lapV = _v[idx + 1] + _v[idx - 1] + _v[idx + gridW] + _v[idx - gridW] - 4.0 * v;

        final uvv = u * v * v;
        _nextU[idx] = (u + (du * lapU - uvv + feed * (1.0 - u))).clamp(0.0, 1.0);
        _nextV[idx] = (v + (dv * lapV + uvv - (feed + kill) * v)).clamp(0.0, 1.0);
      }
    }

    // Cycle arrays
    final tempU = _u;
    _u = _nextU;
    _nextU = tempU;

    final tempV = _v;
    _v = _nextV;
    _nextV = tempV;
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {'u': List<double>.from(_u), 'v': List<double>.from(_v)},
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    _u = List<double>.from(snapshot.state['u'] as List<double>);
    _v = List<double>.from(snapshot.state['v'] as List<double>);
  }

  @override
  Map<String, num> getMetrics() {
    double meanV = 0.0;
    for (int i = 0; i < _v.length; i++) {
      meanV += _v[i];
    }
    meanV /= _v.length;
    return {
      'Mean Chemical V': meanV,
      'Feed Rate (F)': feed,
      'Kill Rate (k)': kill,
    };
  }

  @override
  void render2D(Canvas canvas, Size size, SimTheme theme) {
    final cellW = size.width / gridW;
    final cellH = size.height / gridH;

    for (int y = 0; y < gridH; y++) {
      final row = y * gridW;
      for (int x = 0; x < gridW; x++) {
        final v = _v[row + x];
        if (v > 0.05) {
          final color = Color.lerp(theme.background, theme.accent, v.clamp(0.0, 1.0))!;
          final paint = Paint()..color = color;
          canvas.drawRect(Rect.fromLTWH(x * cellW, y * cellH, cellW + 0.5, cellH + 0.5), paint);
        }
      }
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab Gray-Scott Reaction Diffusion
N = $gridW; Du = $du; Dv = $dv; F = $feed; k = $kill;
U = ones(N); V = zeros(N);
V(N/2-5:N/2+5, N/2-5:N/2+5) = 1;

for step = 1:500
    uvv = U .* V .* V;
    U = U + Du*del2(U) - uvv + F*(1 - U);
    V = V + Dv*del2(V) + uvv - (F + k)*V;
end

figure('Name', 'Turing Pattern Morphogenesis');
imagesc(V); colormap('hot'); colorbar;
title('Gray-Scott Chemical Morphogenesis');
''';
  }
}
