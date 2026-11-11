import '../models/sim_definition.dart';

// Physics & Astrophysics & Quantum & Acoustics
import '../simulations/physics/double_pendulum_sim.dart';
import '../simulations/physics/celestial_nbody_3d_sim.dart';
import '../simulations/physics/lorenz_attractor_3d_sim.dart';
import '../simulations/physics/wave_optics_sim.dart';
import '../simulations/physics/quantum_orbitals_3d_sim.dart';
import '../simulations/physics/black_hole_lensing_3d_sim.dart';
import '../simulations/quantum/bloch_sphere_qubit_3d_sim.dart';
import '../simulations/acoustics/chladni_cymatics_sim.dart';

// Mechanical & Robotics
import '../simulations/mechanical/robotic_arm_6dof_3d_sim.dart';
import '../simulations/mechanical/gyroscope_precession_3d_sim.dart';
import '../simulations/mechanical/internal_combustion_engine_3d_sim.dart';

// Architecture & Civil
import '../simulations/architecture/skyscraper_earthquake_3d_sim.dart';
import '../simulations/architecture/truss_bridge_stress_sim.dart';

// Aerospace & Fluids & Atmospheric
import '../simulations/aerospace/rocket_trajectory_3d_sim.dart';
import '../simulations/aerospace/airfoil_aerodynamics_sim.dart';
import '../simulations/fluids/fluid_sph_dam_break_3d_sim.dart';
import '../simulations/atmospheric/cyclone_hurricane_3d_sim.dart';

// Medical & Biomechanics
import '../simulations/medical/cardiac_ecg_3d_sim.dart';
import '../simulations/biomechanics/bipedal_walker_3d_sim.dart';

// Chemistry & Materials
import '../simulations/chemistry/crystal_lattice_3d_sim.dart';
import '../simulations/chemistry/reaction_diffusion_sim.dart';

// Machine Learning & AI
import '../simulations/machine_learning/loss_landscape_3d_sim.dart';
import '../simulations/machine_learning/neural_decision_boundary_sim.dart';

// Programming & Algorithms
import '../simulations/programming/maze_pathfinding_3d_sim.dart';
import '../simulations/programming/sorting_algorithms_sim.dart';

// Electrical & Telecom
import '../simulations/electrical/antenna_pattern_3d_sim.dart';
import '../simulations/electrical/rlc_resonance_sim.dart';

// Finance
import '../simulations/finance/volatility_surface_3d_sim.dart';

/// Central catalog containing all preinstalled 2D and 3D simulations.
class SimulationRegistry {
  SimulationRegistry._();
  static final SimulationRegistry instance = SimulationRegistry._();

  final List<SimulationModel Function()> _factories = [
    // Physics & Astrophysics
    () => DoublePendulumSim(),
    () => CelestialNBody3DSim(),
    () => LorenzAttractor3DSim(),
    () => WaveOpticsSim(),
    () => QuantumOrbitals3DSim(),
    () => BlackHoleLensing3DSim(),
    () => BlochSphereQubit3DSim(),
    () => ChladniCymaticsSim(),

    // Mechanical & Robotics
    () => RoboticArm6DOF3DSim(),
    () => GyroscopePrecession3DSim(),
    () => InternalCombustionEngine3DSim(),

    // Architecture & Civil
    () => SkyscraperEarthquake3DSim(),
    () => TrussBridgeStressSim(),

    // Aerospace & Fluids & Atmospheric
    () => RocketTrajectory3DSim(),
    () => AirfoilAerodynamicsSim(),
    () => FluidSPHDamBreak3DSim(),
    () => CycloneHurricane3DSim(),

    // Medical & Biomechanics
    () => CardiacECG3DSim(),
    () => BipedalWalker3DSim(),

    // Chemistry & Materials
    () => CrystalLattice3DSim(),
    () => ReactionDiffusionSim(),

    // Machine Learning & AI
    () => LossLandscape3DSim(),
    () => NeuralDecisionBoundarySim(),

    // Programming & Algorithms
    () => MazePathfinding3DSim(),
    () => SortingAlgorithmsSim(),

    // Electrical & Telecom
    () => AntennaPattern3DSim(),
    () => RLCResonanceSim(),

    // Finance
    () => VolatilitySurface3DSim(),
  ];

  late final List<SimulationModel> _models = _factories.map((f) => f()..init()).toList();

  List<SimulationModel> get all => List.unmodifiable(_models);

  SimulationModel? getById(String id) {
    for (final m in _models) {
      if (m.id == id) return m;
    }
    return null;
  }

  List<SimulationModel> getByCategory(SimCategory category) {
    return _models.where((m) => m.category == category).toList();
  }

  List<SimulationModel> getByDimension(SimDimension dim) {
    return _models.where((m) => m.dimension == dim).toList();
  }

  List<SimulationModel> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;

    return _models.where((m) {
      return m.name.toLowerCase().contains(q) ||
          m.description.toLowerCase().contains(q) ||
          m.category.label.toLowerCase().contains(q) ||
          m.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }
}
