import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class VolatilitySurface3DSim extends SimulationModel {
  double spotPrice = 100.0;
  double riskFreeRate = 0.045; // 4.5%
  double volOfVol = 0.35; // xi
  double skewSlope = -0.15; // Put/call skew

  VolatilitySurface3DSim()
      : super(
          id: 'finance_volatility_surface_3d',
          name: 'Implied Volatility Surface (3D Quantitative Finance)',
          description:
              '3D stochastic volatility surface \$\\sigma(K, T)\$ across Strike Price \$K\$ and Time-to-Maturity \$T\$ under Heston and Black-Scholes option pricing models, demonstrating volatility smiles and skews.',
          category: SimCategory.finance,
          dimension: SimDimension.threeD,
          tags: ['Finance', '3D', 'Black-Scholes', 'Heston', 'Options', 'Volatility Surface'],
          parameters: [
            SimParameter(
              id: 'volOfVol',
              name: 'Vol of Volatility (ξ)',
              category: 'Stochastic Model',
              min: 0.1,
              max: 0.8,
              step: 0.05,
              defaultValue: 0.35,
            ),
            SimParameter(
              id: 'skewSlope',
              name: 'Smile Skew Asymmetry',
              category: 'Market Pricing',
              min: -0.4,
              max: 0.1,
              step: 0.02,
              defaultValue: -0.15,
            ),
            SimParameter(
              id: 'riskFreeRate',
              name: 'Risk-Free Rate (r)',
              category: 'Market Pricing',
              unit: '%',
              min: 0.0,
              max: 0.1,
              step: 0.005,
              defaultValue: 0.045,
            ),
          ],
          presets: [
            SimPreset(
              id: 'equity_skew',
              name: 'Equity Index Volatility Skew',
              description: 'Pronounced out-of-the-money put skew reflecting market crash risk hedging.',
              parameters: {'skewSlope': -0.25, 'volOfVol': 0.45},
            ),
            SimPreset(
              id: 'fx_smile',
              name: 'FX Currency Symmetric Smile',
              description: 'Symmetric wing rise for both out-of-the-money calls and puts.',
              parameters: {'skewSlope': 0.0, 'volOfVol': 0.35},
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
  }

  double _evalImpliedVol(double moneyness, double t) {
    // Moneyness m = ln(K / S0)
    final baseVol = 0.20 + 0.05 * math.sqrt(t);
    final smile = 0.5 * volOfVol * (moneyness * moneyness) / (1.0 + t);
    final skew = skewSlope * moneyness / math.sqrt(t + 0.1);

    return (baseVol + smile + skew).clamp(0.08, 0.75);
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'volOfVol') volOfVol = (value as num).toDouble();
    if (paramId == 'skewSlope') skewSlope = (value as num).toDouble();
    if (paramId == 'riskFreeRate') riskFreeRate = (value as num).toDouble();
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(time: time, stepIndex: stepIndex, state: {}, metrics: getMetrics());
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
  }

  @override
  Map<String, num> getMetrics() {
    final atmVol = _evalImpliedVol(0.0, 0.5) * 100.0;
    return {
      'ATM 6M Volatility (%)': atmVol,
      'Vol of Vol (xi)': volOfVol,
      'Risk-Free Rate (%)': riskFreeRate * 100.0,
    };
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    const mSteps = 16;
    const tSteps = 14;

    const mMin = -0.4;
    const mMax = 0.4;
    const tMin = 0.1;
    const tMax = 2.0;

    final mStep = (mMax - mMin) / mSteps;
    final tStep = (tMax - tMin) / tSteps;

    // Draw 3D Implied Volatility Surface Mesh
    for (int i = 0; i < mSteps; i++) {
      final m1 = mMin + i * mStep;
      final m2 = m1 + mStep;

      for (int j = 0; j < tSteps; j++) {
        final t1 = tMin + j * tStep;
        final t2 = t1 + tStep;

        final v1 = _evalImpliedVol(m1, t1);
        final v2 = _evalImpliedVol(m2, t1);
        final v3 = _evalImpliedVol(m1, t2);

        final p1 = camera.project(m1 * 220.0, v1 * 180.0 - 50.0, (t1 - 1.0) * 100.0, size);
        final p2 = camera.project(m2 * 220.0, v2 * 180.0 - 50.0, (t1 - 1.0) * 100.0, size);
        final p3 = camera.project(m1 * 220.0, v3 * 180.0 - 50.0, (t2 - 1.0) * 100.0, size);

        final meshPaint = Paint()
          ..color = Color.lerp(theme.accent, const Color(0xFFFF5252), (v1 - 0.15) / 0.45)!.withValues(alpha: 0.35)
          ..strokeWidth = 1.0;

        if (p1 != null && p2 != null) canvas.drawLine(p1.screen, p2.screen, meshPaint);
        if (p1 != null && p3 != null) canvas.drawLine(p1.screen, p3.screen, meshPaint);
      }
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab 3D Implied Volatility Surface (Heston Model)
K = linspace(70, 130, 40);
T = linspace(0.1, 2.0, 30);
[k_grid, t_grid] = meshgrid(K, T);

% Volatility smile function
vol_surface = 0.20 + 0.35 * ((k_grid - 100)/100).^2 ./ (t_grid + 0.5);

figure('Name', '3D Volatility Surface');
surf(k_grid, t_grid, vol_surface);
colormap('jet'); grid on; view(-45, 30);
xlabel('Strike K (\$)'); ylabel('Expiry T (Years)'); zlabel('Implied Vol \\sigma');
''';
  }
}
