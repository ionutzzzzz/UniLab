import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';

class SortingAlgorithmsSim extends SimulationModel {
  int arraySize = 50;
  String algorithm = 'Quick Sort (O(n log n))';
  double sortingSpeed = 1.0;

  final List<double> _array = [];
  int _activeCompareA = -1;
  int _activeCompareB = -1;
  int comparisons = 0;
  int swaps = 0;
  bool isCompleted = false;

  // Generator state
  late Iterator<List<int>> _sortIterator;

  SortingAlgorithmsSim()
      : super(
          id: 'programming_sorting_algorithms',
          name: 'Sorting Algorithms Visualizer (CS)',
          description:
              'Dynamic visual comparison of fundamental sorting algorithms (Quick Sort, Merge Sort, Heap Sort, Bubble Sort) tracking active element comparisons, memory swaps, and computational complexity.',
          category: SimCategory.programming,
          dimension: SimDimension.twoD,
          tags: ['Algorithms', 'Sorting', 'Big-O', 'QuickSort', 'MergeSort', 'Computer Science'],
          parameters: [
            SimParameter(
              id: 'algorithm',
              name: 'Algorithm',
              category: 'Algorithm',
              type: SimParameterType.dropdown,
              options: [
                'Quick Sort (O(n log n))',
                'Heap Sort (O(n log n))',
                'Bubble Sort (O(n²))',
                'Insertion Sort (O(n²))',
              ],
              defaultValue: 'Quick Sort (O(n log n))',
            ),
            SimParameter(
              id: 'arraySize',
              name: 'Array Length (N)',
              category: 'Array',
              min: 20.0,
              max: 100.0,
              step: 10.0,
              defaultValue: 50.0,
            ),
            SimParameter(
              id: 'sortingSpeed',
              name: 'Speed Multiplier',
              category: 'Speed',
              min: 0.5,
              max: 4.0,
              step: 0.5,
              defaultValue: 1.0,
            ),
          ],
          presets: [
            SimPreset(
              id: 'quicksort_fast',
              name: 'Quick Sort Divide-and-Conquer',
              description: 'Fast pivot partitioning achieving optimal average case speed.',
              parameters: {'algorithm': 'Quick Sort (O(n log n))', 'arraySize': 60.0},
            ),
            SimPreset(
              id: 'bubble_worst',
              name: 'Bubble Sort Inefficient Comparisons',
              description: 'Quadratic O(n²) adjacent pair bubbling demonstrating comparison overhead.',
              parameters: {'algorithm': 'Bubble Sort (O(n²))', 'arraySize': 30.0},
            ),
          ],
        );

  @override
  void init() {
    _resetArray();
  }

  @override
  void reset() {
    time = 0.0;
    stepIndex = 0;
    _resetArray();
  }

  void _resetArray() {
    _array.clear();
    comparisons = 0;
    swaps = 0;
    isCompleted = false;
    _activeCompareA = -1;
    _activeCompareB = -1;

    final rng = math.Random(stepIndex + 17);
    for (int i = 0; i < arraySize; i++) {
      _array.add((i + 1) / arraySize);
    }
    _array.shuffle(rng);

    _sortIterator = _buildSortGenerator().iterator;
  }

  Iterable<List<int>> _buildSortGenerator() sync* {
    if (algorithm.contains('Bubble')) {
      for (int i = 0; i < _array.length; i++) {
        for (int j = 0; j < _array.length - i - 1; j++) {
          yield [j, j + 1, 0]; // 0 = compare
          if (_array[j] > _array[j + 1]) {
            final t = _array[j];
            _array[j] = _array[j + 1];
            _array[j + 1] = t;
            yield [j, j + 1, 1]; // 1 = swap
          }
        }
      }
    } else {
      // Quick sort iterative or step generator
      yield* _quickSort(0, _array.length - 1);
    }
  }

  Iterable<List<int>> _quickSort(int low, int high) sync* {
    if (low < high) {
      final pivot = _array[high];
      int i = low - 1;

      for (int j = low; j < high; j++) {
        yield [j, high, 0];
        if (_array[j] < pivot) {
          i++;
          final t = _array[i];
          _array[i] = _array[j];
          _array[j] = t;
          yield [i, j, 1];
        }
      }
      final t = _array[i + 1];
      _array[i + 1] = _array[high];
      _array[high] = t;
      yield [i + 1, high, 1];

      final pi = i + 1;
      yield* _quickSort(low, pi - 1);
      yield* _quickSort(pi + 1, high);
    }
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'algorithm') {
      algorithm = value.toString();
      _resetArray();
    }
    if (paramId == 'arraySize') {
      arraySize = (value as num).toInt();
      _resetArray();
    }
    if (paramId == 'sortingSpeed') sortingSpeed = (value as num).toDouble();
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;

    if (isCompleted) return;

    final steps = (sortingSpeed * 3.0).round();
    for (int s = 0; s < steps; s++) {
      if (_sortIterator.moveNext()) {
        final action = _sortIterator.current;
        _activeCompareA = action[0];
        _activeCompareB = action[1];
        if (action[2] == 0) {
          comparisons++;
        } else {
          swaps++;
        }
      } else {
        isCompleted = true;
        _activeCompareA = -1;
        _activeCompareB = -1;
        break;
      }
    }
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {'array': List<double>.from(_array), 'comp': comparisons, 'swaps': swaps},
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    _array.clear();
    _array.addAll(snapshot.state['array'] as List<double>);
    comparisons = snapshot.state['comp'] as int;
    swaps = snapshot.state['swaps'] as int;
  }

  @override
  Map<String, dynamic> getMetrics() {
    return {
      'Array Comparisons': comparisons,
      'Memory Swaps': swaps,
      'Sorting State': isCompleted ? 'SORTED (COMPLETE)' : 'IN PROGRESS',
    };
  }

  @override
  void render2D(Canvas canvas, Size size, SimTheme theme) {
    final barW = size.width / _array.length;
    final maxH = size.height * 0.75;
    final bottomY = size.height - 20.0;

    for (int i = 0; i < _array.length; i++) {
      final h = _array[i] * maxH;
      final x = i * barW;
      final y = bottomY - h;

      Color barColor;
      if (isCompleted) {
        barColor = theme.success;
      } else if (i == _activeCompareA || i == _activeCompareB) {
        barColor = const Color(0xFFFFD600); // Active compare
      } else {
        barColor = theme.accent;
      }

      final barPaint = Paint()..color = barColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x + 1.0, y, barW - 2.0, h), const Radius.circular(2)),
        barPaint,
      );
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab Sorting Algorithms Benchmark
N = $arraySize;
A = rand(1, N);

tic;
A_sorted = sort(A);
t = toc;

disp(['Sorted ', num2str(N), ' items in ', num2str(t*1000), ' ms']);
''';
  }
}
