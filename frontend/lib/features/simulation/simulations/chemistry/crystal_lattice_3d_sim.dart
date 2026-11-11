import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/sim_definition.dart';
import '../../models/sim_camera_3d.dart';

class CrystalAtom {
  Vector3 basePos;
  Color color;
  double radius;

  CrystalAtom(this.basePos, this.color, this.radius);
}

class CrystalLattice3DSim extends SimulationModel {
  String latticeType = 'Face-Centered Cubic (FCC)';
  double temperature = 300.0; // Kelvin (controls thermal vibration jitter)
  double latticeConstant = 65.0; // px
  bool showBonds = true;
  bool showMillerPlane = true;

  final List<CrystalAtom> _atoms = [];
  final List<List<int>> _bonds = [];

  CrystalLattice3DSim()
      : super(
          id: 'chemistry_crystal_lattice_3d',
          name: 'Crystal Lattice & Nanostructures (3D)',
          description:
              '3D crystallographic structure of Bravais lattices (FCC, BCC, Diamond, Nanotube) with Miller index (h, k, l) plane slicing and thermal phononic atomic vibrations.',
          category: SimCategory.chemistry,
          dimension: SimDimension.threeD,
          tags: ['Crystallography', '3D', 'Materials', 'Bravais Lattice', 'Miller Indices', 'Nanotechnology'],
          parameters: [
            SimParameter(
              id: 'latticeType',
              name: 'Crystal Structure',
              category: 'Lattice',
              type: SimParameterType.dropdown,
              options: [
                'Face-Centered Cubic (FCC)',
                'Body-Centered Cubic (BCC)',
                'Diamond Cubic (Silicon/Carbon)',
                'Carbon Nanotube (Armchair)',
              ],
              defaultValue: 'Face-Centered Cubic (FCC)',
            ),
            SimParameter(
              id: 'temperature',
              name: 'Thermal Jitter (Kelvin)',
              category: 'Phonons',
              unit: 'K',
              min: 0.0,
              max: 1200.0,
              step: 50.0,
              defaultValue: 300.0,
            ),
            SimParameter(
              id: 'showBonds',
              name: 'Covalent / Metallic Bonds',
              category: 'Visuals',
              type: SimParameterType.toggle,
              defaultValue: true,
            ),
            SimParameter(
              id: 'showMillerPlane',
              name: 'Miller Plane (111)',
              category: 'Visuals',
              type: SimParameterType.toggle,
              defaultValue: true,
            ),
          ],
          presets: [
            SimPreset(
              id: 'copper_fcc',
              name: 'Copper / Gold (FCC)',
              description: 'Face-centered close-packed cubic lattice with 12 nearest neighbors.',
              parameters: {'latticeType': 'Face-Centered Cubic (FCC)', 'temperature': 300.0},
            ),
            SimPreset(
              id: 'silicon_diamond',
              name: 'Silicon Semiconductor (Diamond)',
              description: 'Interpenetrating FCC sublattices forming tetrahedral covalent bonding.',
              parameters: {'latticeType': 'Diamond Cubic (Silicon/Carbon)', 'temperature': 300.0},
            ),
          ],
        );

  @override
  void init() {
    _buildLattice();
  }

  @override
  void reset() {
    time = 0.0;
    stepIndex = 0;
    _buildLattice();
  }

  void _buildLattice() {
    _atoms.clear();
    _bonds.clear();

    final a = latticeConstant;

    if (latticeType.contains('FCC')) {
      // 8 Corners of unit cell
      for (int x = -1; x <= 1; x += 2) {
        for (int y = -1; y <= 1; y += 2) {
          for (int z = -1; z <= 1; z += 2) {
            _atoms.add(CrystalAtom(Vector3(x * a * 0.5, y * a * 0.5, z * a * 0.5), const Color(0xFF00E5FF), 7.0));
          }
        }
      }
      // 6 Face Centers
      final faces = [
        Vector3(a * 0.5, 0, 0), Vector3(-a * 0.5, 0, 0),
        Vector3(0, a * 0.5, 0), Vector3(0, -a * 0.5, 0),
        Vector3(0, 0, a * 0.5), Vector3(0, 0, -a * 0.5),
      ];
      for (final f in faces) {
        _atoms.add(CrystalAtom(f, const Color(0xFFFFD600), 8.0));
      }
    } else if (latticeType.contains('BCC')) {
      // 8 Corners
      for (int x = -1; x <= 1; x += 2) {
        for (int y = -1; y <= 1; y += 2) {
          for (int z = -1; z <= 1; z += 2) {
            _atoms.add(CrystalAtom(Vector3(x * a * 0.5, y * a * 0.5, z * a * 0.5), const Color(0xFF00E5FF), 7.0));
          }
        }
      }
      // 1 Body Center
      _atoms.add(CrystalAtom(const Vector3(0, 0, 0), const Color(0xFFFF5252), 9.0));
    } else {
      // Carbon Nanotube Ring
      const ringAtoms = 12;
      const radius = 45.0;
      for (int r = -2; r <= 2; r++) {
        final y = r * 22.0;
        final phase = (r % 2 == 0) ? 0.0 : (math.pi / ringAtoms);
        for (int i = 0; i < ringAtoms; i++) {
          final theta = i * (2.0 * math.pi / ringAtoms) + phase;
          _atoms.add(CrystalAtom(
            Vector3(radius * math.cos(theta), y, radius * math.sin(theta)),
            const Color(0xFF69F0AE),
            6.0,
          ));
        }
      }
    }

    // Connect nearest neighbor bonds
    for (int i = 0; i < _atoms.length; i++) {
      for (int j = i + 1; j < _atoms.length; j++) {
        final dist = (_atoms[i].basePos - _atoms[j].basePos).length;
        if (dist > 10.0 && dist < a * 0.75) {
          _bonds.add([i, j]);
        }
      }
    }
  }

  @override
  void onParameterChanged(String paramId, dynamic value) {
    if (paramId == 'latticeType') {
      latticeType = value.toString();
      _buildLattice();
    }
    if (paramId == 'temperature') temperature = (value as num).toDouble();
    if (paramId == 'showBonds') showBonds = value as bool;
    if (paramId == 'showMillerPlane') showMillerPlane = value as bool;
  }

  @override
  void step(double dt) {
    time += dt;
    stepIndex++;
  }

  @override
  SimSnapshot captureSnapshot() {
    return SimSnapshot(
      time: time,
      stepIndex: stepIndex,
      state: {'time': time},
      metrics: getMetrics(),
    );
  }

  @override
  void restoreSnapshot(SimSnapshot snapshot) {
    time = snapshot.time;
    stepIndex = snapshot.stepIndex;
  }

  @override
  Map<String, num> getMetrics() {
    return {
      'Unit Cell Atoms': _atoms.length,
      'Covalent Bonds': _bonds.length,
      'Thermal Temp (K)': temperature,
      'Atomic Packing Factor (APF)': latticeType.contains('FCC') ? 0.74 : 0.68,
    };
  }

  @override
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {
    // Phononic thermal vibration jitter amplitude
    final jitterAmp = (temperature / 1200.0) * 3.5;

    // 1. Draw Miller Indices Plane (111)
    if (showMillerPlane && latticeType.contains('FCC')) {
      final a = latticeConstant * 0.5;
      final p1 = camera.project(a, 0, 0, size);
      final p2 = camera.project(0, a, 0, size);
      final p3 = camera.project(0, 0, a, size);

      if (p1 != null && p2 != null && p3 != null) {
        final planePaint = Paint()
          ..color = const Color(0xFFFFD600).withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;

        final path = Path()
          ..moveTo(p1.screen.dx, p1.screen.dy)
          ..lineTo(p2.screen.dx, p2.screen.dy)
          ..lineTo(p3.screen.dx, p3.screen.dy)
          ..close();

        canvas.drawPath(path, planePaint);
      }
    }

    // 2. Draw Covalent / Metallic Bonds
    if (showBonds) {
      final bondPaint = Paint()
        ..color = theme.textMuted.withValues(alpha: 0.4)
        ..strokeWidth = 2.0;

      for (final b in _bonds) {
        final p1 = camera.projectVector(_atoms[b[0]].basePos, size);
        final p2 = camera.projectVector(_atoms[b[1]].basePos, size);
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1.screen, p2.screen, bondPaint);
        }
      }
    }

    // 3. Draw Atoms with 3D Depth Shading & Thermal Jitter
    for (int i = 0; i < _atoms.length; i++) {
      final atom = _atoms[i];
      // Deterministic thermal phononic wave jitter
      final jx = jitterAmp * math.sin(time * 15.0 + i * 1.3);
      final jy = jitterAmp * math.cos(time * 17.0 + i * 2.1);
      final jz = jitterAmp * math.sin(time * 19.0 + i * 0.9);

      final currentPos = atom.basePos + Vector3(jx, jy, jz);
      final proj = camera.projectVector(currentPos, size);
      if (proj == null) continue;

      final dist = (currentPos - camera.eye).length;
      final visualRadius = (atom.radius * 300.0 / dist).clamp(3.0, 25.0);

      final spherePaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.9,
          colors: [Colors.white, atom.color, Colors.black.withValues(alpha: 0.9)],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: proj.screen, radius: visualRadius));

      canvas.drawCircle(proj.screen, visualRadius, spherePaint);
    }
  }

  @override
  String toUniLabScript() {
    return '''
% UniLab 3D Crystallography & Bravais Lattice
a = $latticeConstant; % Lattice constant (Angstroms)
T = $temperature;     % Temperature (K)

% Miller Indices Plane (111) Intersection
figure('Name', 'Crystal Unit Cell');
hold on; grid on; axis equal; view(3);
title('$latticeType Unit Cell');
xlabel('X (Å)'); ylabel('Y (Å)'); zlabel('Z (Å)');
''';
  }
}
