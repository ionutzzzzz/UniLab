import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class LossLandscape3DSim extends SimulationModel {
  String surfaceType = 'Rosenbrock Banana';
  String optimizer = 'Adam';
  double learningRate = 0.05;
  double momentumBeta = 0.9;

  // Optimizer point position in (x, y) plane
  double posX = -1.2;
  double posY = 1.0;
  double velX = 0.0;
  double velY = 0.0;
  // Adam moments
  double mX = 0.0, mY = 0.0;
  double vX = 0.0, vY = 0.0;

  final List<Vector3> _history = [];
  final int maxHistory = 350;

  LossLandscape3DSim()
      : super(
          id: 'ml_loss_landscape_3d',
          name: 'Optimization on 3D Loss Landscapes (ML)',
          description:
              'Interactive 3D optimization surface benchmark comparing SGD, Momentum, Adam, and RMSProp traversing non-convex loss terrains (Rosenbrock valley, Rastrigin craters, Saddle points).',
          category: SimCategory.machineLearning,
          dimension: SimDimension.threeD,
          tags: ['Machine Learning', '3D', 'Gradient Descent', 'Adam', 'Optimization', 'Loss Surface'],
          parameters: [
            SimParameter(
              id: 'surfaceType',
              name: 'Loss Terrain',
              category: 'Terrain',
              type: SimParameterType.dropdown,
              options: ['Rosenbrock Banana', 'Rastrigin Multi-Modal', 'Saddle Point Pass', 'Beale Function'],
              defaultValue: 'Rosenbrock Banana',
            ),
            SimParameter(
              id: 'optimizer',
              name: 'Optimizer Algorithm',
              category: 'Algorithm',
              type: SimParameterType.dropdown,
              options: ['Adam', 'SGD + Momentum', 'Vanilla SGD', 'RMSProp'],
              defaultValue: 'Adam',
            ),
            SimParameter(
              id: 'learningRate',
              name: 'Learning Rate (η)',
              category: 'Hyperparameters',
              min: 0.005,
              max: 0.25,
              step: 0.005,
              defaultValue: 0.05,
            ),
            SimParameter(
              id: 'momentumBeta',
              name: 'Momentum Beta (β)',
              category: 'Hyperparameters',
              min: 0.5,
              max: 0.99,
              step: 0.02,
              defaultValue: 0.9,
            ),
          ],
          presets: [
            SimPreset(
              id: 'rosenbrock_adam',
              name: 'Adam Navigating Rosenbrock Valley',
              description: 'Adaptive learning rate navigating parabolic curving ravine.',
              parameters: {'surfaceType': 'Rosenbrock Banana', 'optimizer': 'Adam', 'learningRate': 0.04},
            ),
            SimPreset(
              id: 'saddle_escape',
              name: 'Saddle Point Escape (Momentum)',
              description: 'Momentum breaking zero-gradient plateau along saddle axis.',
              parameters: {'surfaceType': 'Saddle Point Pass', 'optimizer': 'SGD + Momentum', 'learningRate': 0.08},
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
    posX = -1.2;
    posY = 1.0;
    velX = 0.0;
    velY = 0.0;
    mX = 0.0; mY = 0.0;
    vX = 0.0; vY = 0.0;
    _history.clear();
  }

  double _evalLoss(double x, double y) {
    if (surfaceType.contains('Rosenbrock')) {
      // (1-x)^2 + 100*(y - x^2)^2, scaled
      return 0.15 * (math.pow(1.0 - x, 2) + 12.0 * math.pow(y - x * x, 2));
    } else if (surfaceType.contains('Rastrigin')) {
      return 0.4 * (x * x + y * y - 2.5 * (math.cos(2 * math.pi * x) + math.cos(2 * math.pi * y)) + 5.0);
    } else if (surfaceType.contains('Saddle')) {
      return 0.6 * (x * x - y * y + 3.0);
    } else {
      // Beale
      return 0.2 * (math.pow(1.5 - x + x * y, 2) + math.pow(2.25 - x + x * y * y, 2));
    }
  }

  List<double> _evalGradient(double x, double y) {
    const eps = 1e-4;
    final f = _evalLoss(x, y);
    final gx = (_evalLoss(x + eps, y) - f) / eps;
    final gy = (_evalLoss(x, y + eps) - f) / eps;
    return [gx, gy];
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'surfaceType') {
      surfaceType = value.toString();
      reset();
    }
    if (paramId == 'optimizer') optimizer = value.toString();
    if (paramId == 'learningRate') learningRate = (value as num).toDouble();
    if (paramId == 'momentumBeta') momentumBeta = (value as num).toDouble();
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;

    final grad = _evalGradient(posX, posY);
    final gx = grad[0].clamp(-50.0, 50.0);
    final gy = grad[1].clamp(-50.0, 50.0);

    if (optimizer.contains('Adam')) {
      // Adam update
      const beta1 = 0.9;
      const beta2 = 0.999;
      const eps = 1e-8;

      mX = beta1 * mX + (1 - beta1) * gx;
      mY = beta1 * mY + (1 - beta1) * gy;

      vX = beta2 * vX + (1 - beta2) * (gx * gx);
      vY = beta2 * vY + (1 - beta2) * (gy * gy);

      final mHatX = mX / (1.0 - math.pow(beta1, stepIndex + 1));
      final mHatY = mY / (1.0 - math.pow(beta1, stepIndex + 1));
      final vHatX = vX / (1.0 - math.pow(beta2, stepIndex + 1));
      final vHatY = vY / (1.0 - math.pow(beta2, stepIndex + 1));

      posX -= (learningRate * mHatX) / (math.sqrt(vHatX) + eps);
      posY -= (learningRate * mHatY) / (math.sqrt(vHatY) + eps);
    } else if (optimizer.contains('Momentum')) {
      velX = momentumBeta * velX - learningRate * gx;
      velY = momentumBeta * velY - learningRate * gy;
      posX += velX;
      posY += velY;
    } else {
      // Vanilla SGD
      posX -= learningRate * gx;
      posY -= learningRate * gy;
    }

    // Keep within reasonable domain
    posX = posX.clamp(-2.5, 2.5);
    posY = posY.clamp(-2.5, 2.5);

    final lossZ = _evalLoss(posX, posY);
    _history.add(Vector3(posX * 50.0, lossZ * 20.0, posY * 50.0));
    if (_history.length > maxHistory) {
      _history.removeAt(0);
    }
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {'x': posX, 'y': posY, 'history': List<Vector3>.from(_history)},
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    posX = snapshot.state['x'] as double;
    posY = snapshot.state['y'] as double;
    _history.clear();
    if (snapshot.state['history'] != null) {
      _history.addAll(snapshot.state['history'] as List<Vector3>);
    }
  }

  @override
  Map<String, num> getMetrics() {
    final loss = _evalLoss(posX, posY);
    return {
      'Current Loss f(x, y)': loss,
      'Parameter X': posX,
      'Parameter Y': posY,
      'Optimizer Steps': stepIndex,
    };
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    // 1. Draw 3D Loss Wireframe Terrain Grid
    _renderTerrainWireframe(canvas, size, camera, theme);

    // 2. Draw Optimizer Ball Descent Trajectory
    if (_history.length > 1) {
      for (int i = 0; i < _history.length - 1; i++) {
        final p1 = camera.projectVector(_history[i], size);
        final p2 = camera.projectVector(_history[i + 1], size);
        if (p1 == null || p2 == null) continue;

        final trailPaint = Paint()
          ..color = const Color(0xFFFFD600)
          ..strokeWidth = 2.4;
        canvas.drawLine(p1.screen, p2.screen, trailPaint);
      }
    }

    // 3. Draw Optimizer Head Sphere
    if (_history.isNotEmpty) {
      final ballProj = camera.projectVector(_history.last, size);
      if (ballProj != null) {
        final glowPaint = Paint()
          ..color = theme.warning.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
        canvas.drawCircle(ballProj.screen, 10.0, glowPaint);

        final ballPaint = Paint()..color = theme.warning;
        canvas.drawCircle(ballProj.screen, 6.0, ballPaint);
      }
    }
  }

  void _renderTerrainWireframe(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    const gridRes = 18;
    const span = 2.2;
    const step = (span * 2) / gridRes;

    final gridPaint = Paint()
      ..color = theme.accent.withValues(alpha: 0.22)
      ..strokeWidth = 1.0;

    for (int i = 0; i < gridRes; i++) {
      final x = -span + i * step;
      for (int j = 0; j < gridRes; j++) {
        final y = -span + j * step;

        final z1 = _evalLoss(x, y);
        final z2 = _evalLoss(x + step, y);
        final z3 = _evalLoss(x, y + step);

        final p1 = camera.project(x * 50.0, z1 * 20.0, y * 50.0, size);
        final p2 = camera.project((x + step) * 50.0, z2 * 20.0, y * 50.0, size);
        final p3 = camera.project(x * 50.0, z3 * 20.0, (y + step) * 50.0, size);

        if (p1 != null && p2 != null) canvas.drawLine(p1.screen, p2.screen, gridPaint);
        if (p1 != null && p3 != null) canvas.drawLine(p1.screen, p3.screen, gridPaint);
      }
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab 3D Loss Optimization Landscape
[X, Y] = meshgrid(linspace(-2, 2, 60));
Z = (1 - X).^2 + 100 * (Y - X.^2).^2; % Rosenbrock function

figure('Name', '3D Optimization Loss Surface');
mesh(X, Y, log(Z + 1));
colormap('jet'); colorbar; grid on; view(-35, 40);
title('Rosenbrock Valley - Gradient Descent Terrain');
xlabel('Param X'); ylabel('Param Y'); zlabel('Log Loss');
''';
  }
}
