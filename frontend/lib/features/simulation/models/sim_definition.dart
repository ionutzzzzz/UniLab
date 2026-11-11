import 'package:flutter/material.dart';
import 'sim_camera_3d.dart';

/// Categories spanning engineering and scientific domains.
enum SimCategory {
  physics('Physics & Astrophysics', Icons.blur_on),
  mechanical('Mechanical & Robotics', Icons.precision_manufacturing),
  architecture('Civil & Architecture', Icons.architecture),
  aerospace('Aerospace & Fluids', Icons.rocket_launch),
  medical('Medical & Biomedical', Icons.monitor_heart),
  chemistry('Chemical & Materials', Icons.science),
  biology('Biological Systems', Icons.biotech),
  machineLearning('Machine Learning & AI', Icons.psychology),
  programming('Algorithms & CS', Icons.terminal),
  electrical('Electrical & Telecom', Icons.electric_bolt),
  finance('Quantitative Finance', Icons.trending_up);

  const SimCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Simulation dimensionality: 2D plane or interactive 3D perspective.
enum SimDimension {
  twoD('2D Flat Surface'),
  threeD('3D Interactive Orbit');

  const SimDimension(this.label);
  final String label;
}

/// Control input type for simulation parameters.
enum SimParameterType {
  slider,
  toggle,
  dropdown,
  button,
}

/// Definition of a tweakable parameter in a simulation.
class SimParameter {
  final String id;
  final String name;
  final String category;
  final SimParameterType type;
  final String? unit;
  final double min;
  final double max;
  final double step;
  final List<String>? options;
  dynamic value;
  final dynamic defaultValue;

  SimParameter({
    required this.id,
    required this.name,
    this.category = 'Parameters',
    this.type = SimParameterType.slider,
    this.unit,
    this.min = 0.0,
    this.max = 1.0,
    this.step = 0.01,
    this.options,
    required this.defaultValue,
    dynamic initialValue,
  }) : value = initialValue ?? defaultValue;

  void reset() {
    value = defaultValue;
  }
}

/// Pre-configured parameter setup representing a known real-world case.
class SimPreset {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  const SimPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.parameters,
  });
}

/// Point-in-time snapshot allowing bidirectional time travel.
class SimSnapshot {
  final double time;
  final int stepIndex;
  final Map<String, dynamic> state;
  final Map<String, dynamic> metrics;

  const SimSnapshot({
    required this.time,
    required this.stepIndex,
    required this.state,
    required this.metrics,
  });
}

/// Available themes for the Simulation Studio.
enum SimThemeStyle {
  obsidian('Obsidian Deep Space', Icons.dark_mode),
  cyberMatrix('Cyber Matrix', Icons.terminal),
  blueprint('Technical Blueprint', Icons.architecture),
  laboratory('Clinical Laboratory', Icons.biotech);

  const SimThemeStyle(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Styling context for drawing simulations consistently with UniLab's UI.
class SimTheme {
  final SimThemeStyle style;
  final Color background;
  final Color panelBackground;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color secondaryAccent;
  final Color gridColor;
  final Color danger;
  final Color success;
  final Color warning;
  final bool isDark;

  const SimTheme({
    this.style = SimThemeStyle.obsidian,
    required this.background,
    required this.panelBackground,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    this.secondaryAccent = const Color(0xFF7000FF),
    required this.gridColor,
    required this.danger,
    required this.success,
    required this.warning,
    required this.isDark,
  });

  factory SimTheme.obsidian({Color? accent}) {
    return SimTheme(
      style: SimThemeStyle.obsidian,
      background: const Color(0xFF070A0F),
      panelBackground: const Color(0xFF0E131F),
      textPrimary: const Color(0xFFF0F6FC),
      textMuted: const Color(0xFF8B949E),
      accent: accent ?? const Color(0xFF00F0FF),
      secondaryAccent: const Color(0xFF7000FF),
      gridColor: const Color(0xFF212836).withValues(alpha: 0.35),
      danger: const Color(0xFFFF5252),
      success: const Color(0xFF00E676),
      warning: const Color(0xFFFFD600),
      isDark: true,
    );
  }

  factory SimTheme.cyberMatrix() {
    return SimTheme(
      style: SimThemeStyle.cyberMatrix,
      background: const Color(0xFF030508),
      panelBackground: const Color(0xFF080D12),
      textPrimary: const Color(0xFFD8FADC),
      textMuted: const Color(0xFF5A7A60),
      accent: const Color(0xFF00FF66),
      secondaryAccent: const Color(0xFFFFB300),
      gridColor: const Color(0xFF00FF66).withValues(alpha: 0.14),
      danger: const Color(0xFFFF1744),
      success: const Color(0xFF00FF66),
      warning: const Color(0xFFFFB300),
      isDark: true,
    );
  }

  factory SimTheme.blueprint() {
    return SimTheme(
      style: SimThemeStyle.blueprint,
      background: const Color(0xFF0B1D3A),
      panelBackground: const Color(0xFF0F274C),
      textPrimary: const Color(0xFFE2EBF5),
      textMuted: const Color(0xFF7F9DBE),
      accent: const Color(0xFF4FC3F7),
      secondaryAccent: const Color(0xFFFFE082),
      gridColor: const Color(0xFFFFFFFF).withValues(alpha: 0.16),
      danger: const Color(0xFFFF7043),
      success: const Color(0xFF81C784),
      warning: const Color(0xFFFFD54F),
      isDark: true,
    );
  }

  factory SimTheme.laboratory() {
    return const SimTheme(
      style: SimThemeStyle.laboratory,
      background: Color(0xFFF4F6F9),
      panelBackground: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF1F2937),
      textMuted: Color(0xFF6B7280),
      accent: Color(0xFF0284C7),
      secondaryAccent: Color(0xFF0D9488),
      gridColor: Color(0xFFE2E8F0),
      danger: Color(0xFFDC2626),
      success: Color(0xFF16A34A),
      warning: Color(0xFFD97706),
      isDark: false,
    );
  }

  factory SimTheme.dark({Color? accent}) => SimTheme.obsidian(accent: accent);
  factory SimTheme.light({Color? accent}) => SimTheme.laboratory();
}

/// Abstract base class for all preinstalled simulations.
abstract class SimulationModel {
  final String id;
  final String name;
  final String description;
  final SimCategory category;
  final SimDimension dimension;
  final List<String> tags;
  final List<SimParameter> parameters;
  final List<SimPreset> presets;

  double time = 0.0;
  int stepIndex = 0;

  SimulationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.dimension,
    required this.tags,
    required this.parameters,
    this.presets = const [],
  });

  /// Initialize model state, default parameters, and memory buffers.
  void init();

  /// Step the simulation forward by delta time [dt] (in seconds).
  void step(double dt);

  /// Reset the simulation back to initial time zero.
  void reset() {
    time = 0.0;
    stepIndex = 0;
    init();
  }

  /// Set parameter value and notify model of modification.
  void setParameter(String paramId, dynamic value) {
    for (final param in parameters) {
      if (param.id == paramId) {
        param.value = value;
        onParameterChanged(paramId, value);
        break;
      }
    }
  }

  /// Hook called when a parameter value is updated.
  void onParameterChanged(String paramId, dynamic value) {}

  /// Apply a preset scenario to the simulation.
  void applyPreset(SimPreset preset) {
    preset.parameters.forEach((key, val) {
      setParameter(key, val);
    });
  }

  /// Capture a deep copy of current state for time-travel ring buffer.
  SimSnapshot captureSnapshot();

  /// Restore the exact physical/algorithmic state from a snapshot.
  void restoreSnapshot(SimSnapshot snapshot);

  /// 2D Canvas rendering logic.
  void render2D(Canvas canvas, Size size, SimTheme theme) {}

  /// 3D Canvas rendering logic using orbit camera.
  void render3D(Canvas canvas, Size size, SimCamera3D camera, SimTheme theme) {}

  /// Telemetry metrics for HUD and live dashboards.
  Map<String, dynamic> getMetrics() => {};

  /// Convert simulation setup and equations to reproducible MATLAB/UniLab script.
  String toUniLabScript();
}
