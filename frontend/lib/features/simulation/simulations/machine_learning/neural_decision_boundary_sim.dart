import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';

class MLDataPoint {
  final double x;
  final double y;
  final int label; // 0 or 1

  const MLDataPoint(this.x, this.y, this.label);
}

class NeuralDecisionBoundarySim extends SimulationModel {
  String datasetType = 'Two Spirals';
  double learningRate = 0.08;
  int hiddenNeurons = 8;
  double noise = 0.05;

  final List<MLDataPoint> _dataset = [];
  // 2-layer MLP weights: Input 2 -> Hidden -> Output 1
  late List<List<double>> _w1;
  late List<double> _b1;
  late List<double> _w2;
  double _b2 = 0.0;

  double currentLoss = 1.0;
  double currentAccuracy = 50.0;
  final List<double> _lossHistory = [];

  NeuralDecisionBoundarySim()
      : super(
          id: 'ml_neural_decision_boundary',
          name: 'Neural Network Decision Boundary (ML)',
          description:
              'Real-time Multilayer Perceptron (MLP) training with backpropagation, rendering continuous decision boundary contours on non-linear datasets (Two Spirals, Circles, XOR, Moons).',
          category: SimCategory.machineLearning,
          dimension: SimDimension.twoD,
          tags: ['Neural Networks', 'Deep Learning', 'Classification', 'Backprop', 'Decision Boundary'],
          parameters: [
            SimParameter(
              id: 'datasetType',
              name: 'Classification Dataset',
              category: 'Data',
              type: SimParameterType.dropdown,
              options: ['Two Spirals', 'Concentric Circles', 'XOR Nonlinear', 'Two Moons'],
              defaultValue: 'Two Spirals',
            ),
            SimParameter(
              id: 'learningRate',
              name: 'Learning Rate (η)',
              category: 'Training',
              min: 0.01,
              max: 0.3,
              step: 0.01,
              defaultValue: 0.08,
            ),
            SimParameter(
              id: 'hiddenNeurons',
              name: 'Hidden Layer Width',
              category: 'Architecture',
              min: 4.0,
              max: 16.0,
              step: 2.0,
              defaultValue: 8.0,
            ),
          ],
          presets: [
            SimPreset(
              id: 'spiral_challenge',
              name: 'Two Spirals Non-Linear Benchmark',
              description: 'Challenging interlocking spirals requiring high hidden capacity.',
              parameters: {'datasetType': 'Two Spirals', 'learningRate': 0.1, 'hiddenNeurons': 8.0},
            ),
            SimPreset(
              id: 'circles_quick',
              name: 'Concentric Circles Boundary',
              description: 'Radial non-linear classification boundary.',
              parameters: {'datasetType': 'Concentric Circles', 'learningRate': 0.12, 'hiddenNeurons': 6.0},
            ),
          ],
        );

  @override
  void init() {
    _initWeights();
    _generateDataset();
  }

  @override
  void reset() {
    time = 0.0;
    stepIndex = 0;
    _lossHistory.clear();
    _initWeights();
    _generateDataset();
  }

  void _initWeights() {
    final rng = math.Random(stepIndex + 42);
    _w1 = List.generate(hiddenNeurons, (_) => [rng.nextDouble() - 0.5, rng.nextDouble() - 0.5]);
    _b1 = List.generate(hiddenNeurons, (_) => rng.nextDouble() * 0.1 - 0.05);
    _w2 = List.generate(hiddenNeurons, (_) => rng.nextDouble() - 0.5);
    _b2 = 0.0;
  }

  void _generateDataset() {
    _dataset.clear();
    final rng = math.Random(101);
    const n = 60;

    if (datasetType.contains('Spirals')) {
      for (int i = 0; i < n; i++) {
        final r = i / n;
        final t1 = 1.75 * i / n * 2.0 * math.pi;
        _dataset.add(MLDataPoint(r * math.cos(t1) + (rng.nextDouble() - 0.5) * noise, r * math.sin(t1) + (rng.nextDouble() - 0.5) * noise, 0));

        final t2 = t1 + math.pi;
        _dataset.add(MLDataPoint(r * math.cos(t2) + (rng.nextDouble() - 0.5) * noise, r * math.sin(t2) + (rng.nextDouble() - 0.5) * noise, 1));
      }
    } else if (datasetType.contains('Circles')) {
      for (int i = 0; i < n; i++) {
        final a = rng.nextDouble() * 2.0 * math.pi;
        final r1 = 0.35 + rng.nextDouble() * 0.15;
        _dataset.add(MLDataPoint(r1 * math.cos(a), r1 * math.sin(a), 0));

        final r2 = 0.75 + rng.nextDouble() * 0.15;
        _dataset.add(MLDataPoint(r2 * math.cos(a), r2 * math.sin(a), 1));
      }
    } else {
      // XOR
      for (int i = 0; i < n * 2; i++) {
        final x = (rng.nextDouble() - 0.5) * 1.8;
        final y = (rng.nextDouble() - 0.5) * 1.8;
        final label = (x * y > 0) ? 1 : 0;
        _dataset.add(MLDataPoint(x, y, label));
      }
    }
  }

  double _sigmoid(double z) => 1.0 / (1.0 + math.exp(-z.clamp(-15.0, 15.0)));
  double _tanh(double z) {
    final e2z = math.exp((2.0 * z).clamp(-30.0, 30.0));
    return (e2z - 1.0) / (e2z + 1.0);
  }

  double _forward(double x, double y) {
    double sum = _b2;
    for (int h = 0; h < hiddenNeurons; h++) {
      final act = _tanh(_w1[h][0] * x + _w1[h][1] * y + _b1[h]);
      sum += _w2[h] * act;
    }
    return _sigmoid(sum);
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'datasetType') {
      datasetType = value.toString();
      _generateDataset();
      _initWeights();
    }
    if (paramId == 'learningRate') learningRate = (value as num).toDouble();
    if (paramId == 'hiddenNeurons') {
      hiddenNeurons = (value as num).toInt();
      _initWeights();
    }
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;

    // Mini-batch stochastic backpropagation training step
    double totalLoss = 0.0;
    int correct = 0;

    for (final pt in _dataset) {
      // Forward
      final hActs = List<double>.filled(hiddenNeurons, 0.0);
      double outSum = _b2;

      for (int h = 0; h < hiddenNeurons; h++) {
        final z1 = _w1[h][0] * pt.x + _w1[h][1] * pt.y + _b1[h];
        hActs[h] = _tanh(z1);
        outSum += _w2[h] * hActs[h];
      }
      final pred = _sigmoid(outSum);

      // Binary cross entropy loss
      final target = pt.label.toDouble();
      final err = pred - target;
      totalLoss += - (target * math.log(pred.clamp(1e-7, 1.0)) + (1.0 - target) * math.log((1.0 - pred).clamp(1e-7, 1.0)));

      if ((pred >= 0.5 ? 1 : 0) == pt.label) correct++;

      // Backprop output layer
      final dOut = err;
      _b2 -= learningRate * dOut * 0.1;

      // Backprop hidden layer
      for (int h = 0; h < hiddenNeurons; h++) {
        _w2[h] -= learningRate * dOut * hActs[h];
        final dHidden = dOut * _w2[h] * (1.0 - hActs[h] * hActs[h]);
        _w1[h][0] -= learningRate * dHidden * pt.x;
        _w1[h][1] -= learningRate * dHidden * pt.y;
        _b1[h] -= learningRate * dHidden;
      }
    }

    currentLoss = totalLoss / _dataset.length;
    currentAccuracy = (correct / _dataset.length) * 100.0;
    _lossHistory.add(currentLoss);
    if (_lossHistory.length > 200) _lossHistory.removeAt(0);
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {'loss': currentLoss, 'acc': currentAccuracy},
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    currentLoss = snapshot.state['loss'] as double;
    currentAccuracy = snapshot.state['acc'] as double;
  }

  @override
  Map<String, num> getMetrics() {
    return {
      'Training Loss': currentLoss,
      'Classification Accuracy (%)': currentAccuracy,
      'Dataset Points': _dataset.length,
      'Epochs Completed': stepIndex,
    };
  }

  @override
  void render2D(Canvas canvas, Size size, SimTheme theme) {
    const res = 28;
    final cellW = size.width / res;
    final cellH = size.height / res;

    // 1. Render 2D Continuous Decision Boundary Contour Plane
    for (int j = 0; j < res; j++) {
      final yNorm = ((j / res) - 0.5) * 2.2;
      for (int i = 0; i < res; i++) {
        final xNorm = ((i / res) - 0.5) * 2.2;
        final pred = _forward(xNorm, yNorm);

        // Class 0: Blue/Cyan, Class 1: Red/Orange
        final color = Color.lerp(
          theme.accent.withValues(alpha: 0.15),
          const Color(0xFFFF5252).withValues(alpha: 0.15),
          pred,
        )!;

        canvas.drawRect(Rect.fromLTWH(i * cellW, j * cellH, cellW + 0.5, cellH + 0.5), Paint()..color = color);
      }
    }

    // 2. Render Training Data Points
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;
    final scale = size.width * 0.42;

    for (final pt in _dataset) {
      final px = cx + pt.x * scale;
      final py = cy + pt.y * scale;

      final pColor = pt.label == 0 ? theme.accent : const Color(0xFFFF5252);
      final dotPaint = Paint()..color = pColor;
      canvas.drawCircle(Offset(px, py), 4.5, dotPaint);

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(Offset(px, py), 4.5, borderPaint);
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab Neural Network Classification
hidden_layers = [$hiddenNeurons];
net = patternnet(hidden_layers, 'trainscg');

% Train neural network on dataset
% [X, Y] = generate_spiral_dataset();
% net = train(net, X, Y);

figure('Name', 'Decision Boundary');
% plotconfusion(Y, net(X));
title('MLP Neural Decision Boundary');
''';
  }
}
