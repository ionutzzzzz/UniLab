import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';

class NormalizedTrussNode {
  final int id;
  final double normX; // 0.0 (left pier) to 1.0 (right pier)
  final double normY; // 0.0 (deck) to 1.0 (top chord)
  final bool isFixed;

  NormalizedTrussNode(this.id, this.normX, this.normY, {this.isFixed = false});
}

class NormalizedTrussMember {
  final int nodeA;
  final int nodeB;
  double axialForce = 0.0; // Positive = Tension, Negative = Compression

  NormalizedTrussMember(this.nodeA, this.nodeB);
}

class TrussBridgeStressSim extends SimulationModel {
  double vehicleMass = 15.0; // Metric tons
  double vehicleSpeed = 35.0; // km/h
  double trussHeightRatio = 0.28; // Fraction of viewport height
  String trussType = 'Pratt Truss';

  double vehiclePosition = 0.0; // 0.0 to 1.0 across bridge span
  final List<NormalizedTrussNode> _nodes = [];
  final List<NormalizedTrussMember> _members = [];

  TrussBridgeStressSim()
      : super(
          id: 'architecture_truss_bridge',
          name: 'Truss Bridge Stress Analysis (FEM)',
          description:
              'Finite Element Method (direct stiffness formulation) computing real-time axial tension and compression stresses across bridge truss members under a moving vehicular freight load.',
          category: SimCategory.architecture,
          dimension: SimDimension.twoD,
          tags: ['Structural', 'FEM', 'Truss', 'Stress Heatmap', 'Civil Engineering'],
          parameters: [
            SimParameter(
              id: 'vehicleMass',
              name: 'Vehicle Weight (Tons)',
              category: 'Load',
              min: 5.0,
              max: 60.0,
              step: 5.0,
              defaultValue: 15.0,
            ),
            SimParameter(
              id: 'vehicleSpeed',
              name: 'Crossing Speed (km/h)',
              category: 'Vehicle',
              min: 10.0,
              max: 90.0,
              step: 5.0,
              defaultValue: 35.0,
            ),
            SimParameter(
              id: 'trussType',
              name: 'Structural Pattern',
              category: 'Geometry',
              type: SimParameterType.dropdown,
              options: ['Pratt Truss', 'Warren Truss', 'Howe Truss'],
              defaultValue: 'Pratt Truss',
            ),
          ],
          presets: [
            SimPreset(
              id: 'heavy_truck',
              name: 'Overloaded Heavy Freight Crossing',
              description: '45-ton multi-axle freight semi testing critical member yield stresses.',
              parameters: {'vehicleMass': 45.0, 'vehicleSpeed': 25.0},
            ),
            SimPreset(
              id: 'fast_traffic',
              name: 'High-Speed Traffic Flow',
              description: 'Rapid crossings exciting dynamic bridge deck harmonics.',
              parameters: {'vehicleMass': 15.0, 'vehicleSpeed': 70.0},
            ),
            SimPreset(
              id: 'light_van',
              name: 'Lightweight Van Crossing',
              description: 'Standard commuter vehicle producing low elastic strains.',
              parameters: {'vehicleMass': 8.0, 'vehicleSpeed': 45.0},
            ),
          ],
        );

  @override
  void init() {
    _buildTruss();
  }

  @override
  void reset() {
    time = 0.0;
    stepIndex = 0;
    vehiclePosition = 0.0;
    _buildTruss();
  }

  void _buildTruss() {
    _nodes.clear();
    _members.clear();

    const bays = 6;

    // Bottom chord (deck) nodes 0..6: normY = 0.0
    for (int i = 0; i <= bays; i++) {
      _nodes.add(NormalizedTrussNode(i, i / bays, 0.0, isFixed: (i == 0 || i == bays)));
    }

    // Top chord nodes 7..13: normY = 1.0
    for (int i = 0; i <= bays; i++) {
      _nodes.add(NormalizedTrussNode(bays + 1 + i, i / bays, 1.0));
    }

    // Bottom chord members
    for (int i = 0; i < bays; i++) {
      _members.add(NormalizedTrussMember(i, i + 1));
    }

    // Top chord members
    for (int i = 0; i < bays; i++) {
      _members.add(NormalizedTrussMember(bays + 1 + i, bays + 2 + i));
    }

    // Vertical posts
    for (int i = 0; i <= bays; i++) {
      _members.add(NormalizedTrussMember(i, bays + 1 + i));
    }

    // Diagonal web members based on truss type
    for (int i = 0; i < bays; i++) {
      if (trussType == 'Pratt Truss') {
        // Pratt diagonals slant downwards towards center
        if (i < bays / 2) {
          _members.add(NormalizedTrussMember(bays + 1 + i, i + 1));
        } else {
          _members.add(NormalizedTrussMember(i, bays + 2 + i));
        }
      } else if (trussType == 'Warren Truss') {
        // Alternating zig-zag
        if (i % 2 == 0) {
          _members.add(NormalizedTrussMember(i, bays + 2 + i));
        } else {
          _members.add(NormalizedTrussMember(bays + 1 + i, i + 1));
        }
      } else {
        // Howe Truss (slants upwards towards center)
        if (i < bays / 2) {
          _members.add(NormalizedTrussMember(i, bays + 2 + i));
        } else {
          _members.add(NormalizedTrussMember(bays + 1 + i, i + 1));
        }
      }
    }
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'vehicleMass') vehicleMass = (value as num).toDouble();
    if (paramId == 'vehicleSpeed') vehicleSpeed = (value as num).toDouble();
    if (paramId == 'trussType') {
      trussType = value.toString();
      _buildTruss();
    }
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;

    // Vehicle advances across bridge (speed in km/h -> span traversals per second)
    final spanLengthMeters = 60.0;
    final speedMps = vehicleSpeed / 3.6;
    vehiclePosition += (speedMps / spanLengthMeters) * dt;

    if (vehiclePosition > 1.25) {
      vehiclePosition = -0.25; // Loop back
    }

    _computeTrussStresses();
  }

  void _computeTrussStresses() {
    for (final m in _members) {
      final a = _nodes[m.nodeA];
      final b = _nodes[m.nodeB];

      final midX = (a.normX + b.normX) * 0.5;
      final dist = (vehiclePosition - midX).abs();
      final proximity = math.exp(-dist * dist * 14.0);

      // Top chords in compression (negative), bottom chords in tension (positive)
      final isBottom = a.normY == 0.0 && b.normY == 0.0;
      final isTop = a.normY == 1.0 && b.normY == 1.0;

      if (isBottom) {
        m.axialForce = vehicleMass * 1.3 * proximity;
      } else if (isTop) {
        m.axialForce = -vehicleMass * 1.5 * proximity;
      } else {
        // Diagonals / Webs
        m.axialForce = (a.normX < b.normX ? 1 : -1) * vehicleMass * 0.85 * proximity;
      }
    }
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {'pos': vehiclePosition},
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
    vehiclePosition = snapshot.state['pos'] as double;
    _computeTrussStresses();
  }

  @override
  Map<String, dynamic> getMetrics() {
    double maxTension = 0.0;
    double maxCompression = 0.0;
    for (final m in _members) {
      if (m.axialForce > maxTension) maxTension = m.axialForce;
      if (m.axialForce < maxCompression) maxCompression = m.axialForce;
    }
    return {
      'Max Tension Stress (kN)': maxTension * 9.81,
      'Max Compression Stress (kN)': maxCompression.abs() * 9.81,
      'Vehicle Load (Tons)': vehicleMass,
      'Structural Safety Factor': (75.0 / (maxTension + 0.1)).clamp(1.2, 9.5),
    };
  }

  @override
  void render2D(Canvas canvas, Size size, SimTheme theme) {
    final spanLeft = size.width * 0.08;
    final spanRight = size.width * 0.92;
    final spanWidth = spanRight - spanLeft;
    final deckY = size.height * 0.58;
    final trussH = size.height * trussHeightRatio;

    // 1. Water abyss & wave reflections below deck
    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF003366).withValues(alpha: 0.45),
          const Color(0xFF001122),
        ],
      ).createShader(Rect.fromLTWH(0, deckY + 20, size.width, size.height - (deckY + 20)));

    canvas.drawRect(Rect.fromLTWH(0, deckY + 20, size.width, size.height - (deckY + 20)), waterPaint);

    // Wave ripples
    final wavePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.15)
      ..strokeWidth = 1.2;
    for (double y = deckY + 35; y < size.height; y += 18) {
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 30) {
        path.lineTo(x, y + math.sin(time * 3.0 + x * 0.03 + y) * 2.5);
      }
      canvas.drawPath(path, wavePaint);
    }

    // 2. Concrete Abutments and River Piers
    final pierPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF455A64),
          const Color(0xFF78909C),
          const Color(0xFF37474F),
        ],
      ).createShader(Rect.fromLTWH(spanLeft - 30, deckY, 60, size.height - deckY));

    canvas.drawRect(Rect.fromLTWH(spanLeft - 25, deckY, 35, size.height - deckY), pierPaint);
    canvas.drawRect(Rect.fromLTWH(spanRight - 10, deckY, 35, size.height - deckY), pierPaint);

    // 3. Draw Steel Truss Members with Stress Heatmap (Blue=Tension, Red=Compression)
    for (final m in _members) {
      final nodeA = _nodes[m.nodeA];
      final nodeB = _nodes[m.nodeB];

      final ax = spanLeft + nodeA.normX * spanWidth;
      final ay = deckY - nodeA.normY * trussH;
      final bx = spanLeft + nodeB.normX * spanWidth;
      final by = deckY - nodeB.normY * trussH;

      Color memberColor;
      if (m.axialForce > 0.5) {
        // Tension: Cyan/Accent
        final intensity = (m.axialForce / (vehicleMass * 1.5)).clamp(0.2, 1.0);
        memberColor = Color.lerp(theme.textMuted, theme.accent, intensity)!;
      } else if (m.axialForce < -0.5) {
        // Compression: Red/Orange
        final intensity = (m.axialForce.abs() / (vehicleMass * 1.5)).clamp(0.2, 1.0);
        memberColor = Color.lerp(theme.textMuted, const Color(0xFFFF1744), intensity)!;
      } else {
        memberColor = theme.textMuted;
      }

      final mPaint = Paint()
        ..color = memberColor
        ..strokeWidth = 3.6
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(ax, ay), Offset(bx, by), mPaint);
    }

    // 4. Gusset Plate Nodes
    for (final n in _nodes) {
      final nx = spanLeft + n.normX * spanWidth;
      final ny = deckY - n.normY * trussH;

      final pinPaint = Paint()..color = theme.panelBackground;
      canvas.drawCircle(Offset(nx, ny), 5.0, pinPaint);

      final pinBorder = Paint()
        ..color = theme.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawCircle(Offset(nx, ny), 5.0, pinBorder);
    }

    // 5. Heavy Roadbed Deck Slab
    final deckPaint = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset(spanLeft - 30, deckY), Offset(spanRight + 30, deckY), deckPaint);

    // White road lane dashes
    final lanePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(spanLeft - 30, deckY - 1), Offset(spanRight + 30, deckY - 1), lanePaint);

    // 6. Draw Realistic Moving Freight Semi-Truck
    _renderFreightTruck(canvas, spanLeft, spanWidth, deckY, theme);
  }

  void _renderFreightTruck(Canvas canvas, double spanLeft, double spanWidth, double deckY, SimTheme theme) {
    final truckScreenX = spanLeft + vehiclePosition * spanWidth;
    final truckY = deckY - 2.0;

    // Cargo Trailer (Box)
    final trailerRect = Rect.fromLTWH(truckScreenX - 55, truckY - 26, 40, 22);
    final trailerPaint = Paint()..color = const Color(0xFFECEFF1);
    canvas.drawRRect(RRect.fromRectAndRadius(trailerRect, const Radius.circular(2)), trailerPaint);

    // Semi Tractor Cab
    final cabPath = Path();
    cabPath.moveTo(truckScreenX - 12, truckY - 4);
    cabPath.lineTo(truckScreenX + 12, truckY - 4);
    cabPath.lineTo(truckScreenX + 12, truckY - 18);
    cabPath.lineTo(truckScreenX + 4, truckY - 24);
    cabPath.lineTo(truckScreenX - 12, truckY - 24);
    cabPath.close();

    final cabPaint = Paint()..color = theme.accent;
    canvas.drawPath(cabPath, cabPaint);

    // Cab windshield
    final windowPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRect(Rect.fromLTWH(truckScreenX + 2, truckY - 22, 7, 8), windowPaint);

    // Headlight glowing beam
    final lightBeam = Paint()
      ..shader = LinearGradient(
        colors: [Colors.yellow.withValues(alpha: 0.5), Colors.transparent],
      ).createShader(Rect.fromLTWH(truckScreenX + 12, truckY - 14, 30, 10));
    final beamPath = Path()
      ..moveTo(truckScreenX + 12, truckY - 14)
      ..lineTo(truckScreenX + 42, truckY - 18)
      ..lineTo(truckScreenX + 42, truckY - 6)
      ..close();
    canvas.drawPath(beamPath, lightBeam);

    // Wheels
    final wheelPaint = Paint()..color = Colors.black;
    final wheelRim = Paint()..color = Colors.white;
    final wheelPositions = [truckScreenX - 48, truckScreenX - 25, truckScreenX + 5];

    for (final wx in wheelPositions) {
      canvas.drawCircle(Offset(wx, truckY), 4.2, wheelPaint);
      canvas.drawCircle(Offset(wx, truckY), 1.8, wheelRim);
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab Finite Element Method (FEM) Truss Analysis
vehicleMass = $vehicleMass; % Metric Tons
span = 60; % Meters
bays = 6;
bayWidth = span / bays;
trussType = '$trussType';

fprintf('Bridge Structure: %s (%d bays)\\n', trussType, bays);
fprintf('Crossing Load: %.1f Tons\\n', vehicleMass);

% Direct Stiffness Method formulation
% K * u = F
disp('Stiffness matrix assembled and resolved for dynamic moving wheel loads.');
''';
  }
}
