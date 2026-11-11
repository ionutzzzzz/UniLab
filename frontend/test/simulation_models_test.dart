import 'package:flutter_test/flutter_test.dart';
import 'package:unilab/features/simulation/models/sim_definition.dart';
import 'package:unilab/features/simulation/services/simulation_registry.dart';

void main() {
  group('Simulation Models & Registry Tests', () {
    test('Registry contains all disciplines and models', () {
      final registry = SimulationRegistry.instance;
      final all = registry.all;

      expect(all.length, greaterThanOrEqualTo(28));

      // Verify category coverage
      for (final cat in SimCategory.values.where((c) => c != SimCategory.biology)) {
        final modelsInCat = registry.getByCategory(cat);
        expect(modelsInCat.isNotEmpty, isTrue, reason: 'Category ${cat.label} must have models');
      }

      // Verify dimension coverage
      final models2D = registry.getByDimension(SimDimension.twoD);
      final models3D = registry.getByDimension(SimDimension.threeD);
      expect(models2D.isNotEmpty, isTrue);
      expect(models3D.isNotEmpty, isTrue);
    });

    test('Registry contains all 6 new advanced high-complexity simulation models', () {
      final registry = SimulationRegistry.instance;

      expect(registry.getById('fluids_sph_dam_break_3d'), isNotNull);
      expect(registry.getById('physics_black_hole_lensing_3d'), isNotNull);
      expect(registry.getById('quantum_bloch_sphere_qubit_3d'), isNotNull);
      expect(registry.getById('biomechanics_bipedal_walker_3d'), isNotNull);
      expect(registry.getById('atmospheric_cyclone_hurricane_3d'), isNotNull);
      expect(registry.getById('acoustics_chladni_cymatics'), isNotNull);
    });

    test('All models initialize, step, capture and restore snapshot', () {
      final all = SimulationRegistry.instance.all;

      for (final model in all) {
        // Init
        model.init();
        expect(model.time, 0.0);
        expect(model.stepIndex, 0);

        // Step forward 5 ticks
        for (int i = 0; i < 5; i++) {
          model.step(0.016);
        }
        expect(model.time, greaterThan(0.0));
        expect(model.stepIndex, 5);

        // Snapshot capture
        final snapshot = model.captureSnapshot();
        expect(snapshot.time, model.time);
        expect(snapshot.stepIndex, 5);

        // Step further
        model.step(0.016);
        expect(model.stepIndex, 6);

        // Snapshot restore
        model.restoreSnapshot(snapshot);
        expect(model.time, snapshot.time);
        expect(model.stepIndex, 5);

        // Parameters
        for (final param in model.parameters) {
          expect(param.name.isNotEmpty, isTrue);
          expect(param.value, isNotNull);
        }

        // Script generation
        final script = model.toUniLabScript();
        expect(script.isNotEmpty, isTrue);
        expect(script.contains('%'), isTrue);

        // Reset
        model.reset();
        expect(model.time, 0.0);
        expect(model.stepIndex, 0);
      }
    });

    test('Theme profiles are distinct and valid', () {
      final obsidian = SimTheme.obsidian();
      expect(obsidian.style, SimThemeStyle.obsidian);
      expect(obsidian.isDark, isTrue);

      final cyber = SimTheme.cyberMatrix();
      expect(cyber.style, SimThemeStyle.cyberMatrix);
      expect(cyber.isDark, isTrue);

      final blueprint = SimTheme.blueprint();
      expect(blueprint.style, SimThemeStyle.blueprint);
      expect(blueprint.isDark, isTrue);

      final lab = SimTheme.laboratory();
      expect(lab.style, SimThemeStyle.laboratory);
      expect(lab.isDark, isFalse);
    });

    test('Registry search functionality', () {
      final registry = SimulationRegistry.instance;

      final chaosResults = registry.search('chaos');
      expect(chaosResults.isNotEmpty, isTrue);

      final rocketResults = registry.search('rocket');
      expect(rocketResults.isNotEmpty, isTrue);

      final ecgResults = registry.search('ecg');
      expect(ecgResults.isNotEmpty, isTrue);

      final blackHole = registry.search('black hole');
      expect(blackHole.isNotEmpty, isTrue);

      final sph = registry.search('dam break');
      expect(sph.isNotEmpty, isTrue);

      final cymatics = registry.search('cymatics');
      expect(cymatics.isNotEmpty, isTrue);
    });
  });
}
