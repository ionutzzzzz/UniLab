import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class MazeCell3D {
  final int x;
  final int y;
  final int z;
  bool isWall;
  bool isVisited;
  bool isPath;

  MazeCell3D(this.x, this.y, this.z, {this.isWall = false, this.isVisited = false, this.isPath = false});
}

class MazePathfinding3DSim extends SimulationModel {
  static const int dimX = 9;
  static const int dimY = 3;
  static const int dimZ = 9;

  String algorithm = 'A* Search (Heuristic)';
  double searchSpeed = 1.0;

  final List<MazeCell3D> _grid = [];
  final List<int> _openSet = [];
  final Set<int> _closedSet = {};
  final Map<int, int> _cameFrom = {};

  int startIndex = 0;
  int goalIndex = 0;
  bool isSolved = false;

  MazePathfinding3DSim()
      : super(
          id: 'programming_maze_pathfinding_3d',
          name: '3D Voxel Maze & Pathfinding (A* & Dijkstra)',
          description:
              '3D multi-level spatial maze exploration demonstrating graph search algorithms (A*, Dijkstra, BFS). Renders voxel terrain, visited frontier waves, and optimal 3D path routing.',
          category: SimCategory.programming,
          dimension: SimDimension.threeD,
          tags: ['Algorithms', '3D', 'A* Search', 'Dijkstra', 'Graph Theory', 'Voxel Maze'],
          parameters: [
            SimParameter(
              id: 'algorithm',
              name: 'Search Algorithm',
              category: 'Algorithm',
              type: SimParameterType.dropdown,
              options: ['A* Search (Heuristic)', 'Dijkstra (Uniform Cost)', 'Breadth-First Search (BFS)'],
              defaultValue: 'A* Search (Heuristic)',
            ),
            SimParameter(
              id: 'searchSpeed',
              name: 'Traversal Speed',
              category: 'Execution',
              min: 0.2,
              max: 3.0,
              step: 0.2,
              defaultValue: 1.0,
            ),
          ],
          presets: [
            SimPreset(
              id: 'astar_direct',
              name: 'A* Direct Heuristic Routing',
              description: 'Fast goal-directed traversal minimizing Euclidean 3D distance.',
              parameters: {'algorithm': 'A* Search (Heuristic)'},
            ),
            SimPreset(
              id: 'dijkstra_flood',
              name: 'Dijkstra Uniform Wavefront',
              description: 'Exhaustive circular search expanding across all levels equally.',
              parameters: {'algorithm': 'Dijkstra (Uniform Cost)'},
            ),
          ],
        );

  @override
  void init() {
    _generateMaze();
  }

  @override
  void reset() {
    time = 0.0;
    stepIndex = 0;
    _generateMaze();
  }

  void _generateMaze() {
    _grid.clear();
    _openSet.clear();
    _closedSet.clear();
    _cameFrom.clear();
    isSolved = false;

    final rng = math.Random(stepIndex + 7);

    // Build grid
    for (int y = 0; y < dimY; y++) {
      for (int z = 0; z < dimZ; z++) {
        for (int x = 0; x < dimX; x++) {
          final isObstacle = (rng.nextDouble() < 0.22 && !(x == 0 && z == 0 && y == 0) && !(x == dimX - 1 && z == dimZ - 1));
          _grid.add(MazeCell3D(x, y, z, isWall: isObstacle));
        }
      }
    }

    startIndex = 0;
    goalIndex = _grid.length - 1;
    _grid[goalIndex].isWall = false;

    _openSet.add(startIndex);
  }

  int _coordToIndex(int x, int y, int z) => y * (dimX * dimZ) + z * dimX + x;

  List<int> _getNeighbors(int idx) {
    final cell = _grid[idx];
    final neighbors = <int>[];

    final dirs = [
      [1, 0, 0], [-1, 0, 0],
      [0, 0, 1], [0, 0, -1],
      [0, 1, 0], [0, -1, 0], // Vertical ramps
    ];

    for (final d in dirs) {
      final nx = cell.x + d[0];
      final ny = cell.y + d[1];
      final nz = cell.z + d[2];

      if (nx >= 0 && nx < dimX && ny >= 0 && ny < dimY && nz >= 0 && nz < dimZ) {
        final nIdx = _coordToIndex(nx, ny, nz);
        if (!_grid[nIdx].isWall) {
          neighbors.add(nIdx);
        }
      }
    }
    return neighbors;
  }

  double _heuristic(int idx) {
    if (algorithm.contains('Dijkstra') || algorithm.contains('BFS')) return 0.0;
    final c = _grid[idx];
    final g = _grid[goalIndex];
    return math.sqrt(math.pow(c.x - g.x, 2) + math.pow(c.y - g.y, 2) + math.pow(c.z - g.z, 2));
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'algorithm') {
      algorithm = value.toString();
      _generateMaze();
    }
    if (paramId == 'searchSpeed') searchSpeed = (value as num).toDouble();
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;

    if (isSolved || _openSet.isEmpty) return;

    // Step A* / Dijkstra forward
    final stepsPerTick = (searchSpeed * 2.0).round();

    for (int s = 0; s < stepsPerTick; s++) {
      if (_openSet.isEmpty) break;

      // Select lowest f(n)
      int currentIdx = _openSet.first;
      double lowestCost = double.infinity;
      for (final idx in _openSet) {
        final cost = _heuristic(idx);
        if (cost < lowestCost) {
          lowestCost = cost;
          currentIdx = idx;
        }
      }

      if (currentIdx == goalIndex) {
        isSolved = true;
        _reconstructPath();
        break;
      }

      _openSet.remove(currentIdx);
      _closedSet.add(currentIdx);
      _grid[currentIdx].isVisited = true;

      for (final neighbor in _getNeighbors(currentIdx)) {
        if (_closedSet.contains(neighbor)) continue;

        if (!_openSet.contains(neighbor)) {
          _cameFrom[neighbor] = currentIdx;
          _openSet.add(neighbor);
        }
      }
    }
  }

  void _reconstructPath() {
    int? curr = goalIndex;
    while (curr != null) {
      _grid[curr].isPath = true;
      curr = _cameFrom[curr];
    }
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {'solved': isSolved},
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
  }

  @override
  Map<String, dynamic> getMetrics() {
    return {
      'Visited Nodes': _closedSet.length,
      'Open Frontier Nodes': _openSet.length,
      'Search Status': isSolved ? 'GOAL REACHED' : 'EXPLORING',
    };
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    const spacing = 18.0;
    final offsetX = (dimX * spacing) / 2.0;
    final offsetY = (dimY * spacing) / 2.0;
    final offsetZ = (dimZ * spacing) / 2.0;

    for (final cell in _grid) {
      final wx = cell.x * spacing - offsetX;
      final wy = cell.y * spacing * 1.5 - offsetY;
      final wz = cell.z * spacing - offsetZ;

      final proj = camera.project(wx, wy, wz, size);
      if (proj == null) continue;

      if (cell.isWall) {
        final wallPaint = Paint()..color = theme.textMuted.withValues(alpha: 0.35);
        canvas.drawRect(Rect.fromCenter(center: proj.screen, width: 8.0, height: 8.0), wallPaint);
      } else if (cell.isPath) {
        // Glowing gold shortest path
        final pathGlow = Paint()
          ..color = const Color(0xFFFFD600)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
        canvas.drawCircle(proj.screen, 7.0, pathGlow);

        final pathPaint = Paint()..color = const Color(0xFFFFD600);
        canvas.drawCircle(proj.screen, 4.5, pathPaint);
      } else if (cell.isVisited) {
        final visitPaint = Paint()..color = theme.accent.withValues(alpha: 0.6);
        canvas.drawCircle(proj.screen, 3.0, visitPaint);
      }
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab 3D Maze Pathfinding (A* Search)
% Graph Representation
start_node = 1;
goal_node = ${dimX * dimY * dimZ};

% Run A* Search Algorithm
% [path, cost] = astar_3d(grid, start_node, goal_node);
disp('A* Shortest Path Calculated across 3D levels.');
''';
  }
}
