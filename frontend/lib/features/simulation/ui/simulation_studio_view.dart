import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../theme/ui_theme.dart';
import '../models/sim_camera_3d.dart';
import '../models/sim_definition.dart';
import '../services/simulation_controller.dart';
import 'simulation_catalog_dialog.dart';

class SimulationStudioView extends StatefulWidget {
  const SimulationStudioView({super.key});

  @override
  State<SimulationStudioView> createState() => _SimulationStudioViewState();
}

class _SimulationStudioViewState extends State<SimulationStudioView> {
  final SimulationController _ctrl = SimulationController.instance;
  bool _showParamsDrawer = true;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final simTheme = _ctrl.currentTheme;
    final model = _ctrl.activeModel;

    return Container(
      color: simTheme.background,
      child: Column(
        children: [
          // 1. Top Simulation Studio HUD
          _buildHUD(ui, simTheme, model),

          // 2. Viewport + Collapsible Parameters Drawer
          Expanded(
            child: Row(
              children: [
                // Simulation Interactive Viewport with LayoutBuilder & ClipRect
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          // Viewport Canvas with Mouse Orbit / Interaction
                          Positioned.fill(
                            child: Listener(
                              onPointerSignal: (pointerSignal) {
                                if (pointerSignal is PointerScrollEvent && _ctrl.is3D) {
                                  final zoomFactor = pointerSignal.scrollDelta.dy > 0 ? 1.08 : 0.92;
                                  _ctrl.camera3D.zoom(zoomFactor);
                                  setState(() {});
                                }
                              },
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  if (_ctrl.is3D) {
                                    // Orbit rotation on drag
                                    _ctrl.camera3D.orbit(-details.delta.dx * 0.008, details.delta.dy * 0.008);
                                    setState(() {});
                                  }
                                },
                                child: RepaintBoundary(
                                  key: _ctrl.canvasKey,
                                  child: ClipRect(
                                    child: CustomPaint(
                                      painter: _SimCanvasPainter(
                                        model: model,
                                        camera: _ctrl.camera3D,
                                        theme: simTheme,
                                        is3D: _ctrl.is3D,
                                      ),
                                      size: Size(constraints.maxWidth, constraints.maxHeight),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Floating 3D Navigation Tips
                          if (_ctrl.is3D)
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: simTheme.panelBackground.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: simTheme.gridColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.orbit, size: 13, color: simTheme.accent),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Left Drag: Orbit 3D  •  Scroll: Zoom  •  Double Click: Reset',
                                      style: TextStyle(
                                        color: simTheme.textPrimary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Recording Live Badge
                          if (_ctrl.videoRecorder.isRecording)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF1744).withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: const Color(0xFFFF1744), width: 1.4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF1744).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.fiber_manual_record, size: 14, color: Color(0xFFFF1744)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'REC ${_ctrl.videoRecorder.recordingDurationString} (${_ctrl.videoRecorder.recordedFrames} frames)',
                                      style: const TextStyle(
                                        color: Color(0xFFFF1744),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                // Collapsible Parameters & Telemetry Drawer
                if (_showParamsDrawer) _buildParametersDrawer(ui, simTheme, model),
              ],
            ),
          ),

          // 3. Bottom Time Control Bar (Scrubber, VCR buttons, Speed)
          _buildTimeBar(ui, simTheme),
        ],
      ),
    );
  }

  Widget _buildHUD(UiTheme ui, SimTheme simTheme, SimulationModel model) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: simTheme.panelBackground,
        border: Border(bottom: BorderSide(color: simTheme.gridColor)),
      ),
      child: Row(
        children: [
          // Discipline Icon & Model Name
          Icon(model.category.icon, size: 18, color: simTheme.accent),
          const SizedBox(width: 10),
          Text(
            model.name,
            style: TextStyle(
              color: simTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),

          // 2D / 3D Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _ctrl.is3D
                  ? simTheme.secondaryAccent.withValues(alpha: 0.25)
                  : simTheme.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _ctrl.is3D ? simTheme.secondaryAccent : simTheme.accent,
                width: 0.8,
              ),
            ),
            child: Text(
              _ctrl.is3D ? '3D' : '2D',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _ctrl.is3D ? simTheme.secondaryAccent : simTheme.accent,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Reset Camera for 3D
          if (_ctrl.is3D)
            IconButton(
              icon: Icon(LucideIcons.camera, size: 15, color: simTheme.textMuted),
              tooltip: 'Reset 3D Orbit Camera',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                _ctrl.camera3D.reset();
                setState(() {});
              },
            ),

          const Spacer(),

          // Theme Style Selector Dropdown
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: simTheme.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: simTheme.gridColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SimThemeStyle>(
                value: _ctrl.themeStyle,
                dropdownColor: simTheme.panelBackground,
                icon: Icon(Icons.arrow_drop_down, size: 16, color: simTheme.textMuted),
                style: TextStyle(color: simTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                items: SimThemeStyle.values.map((style) {
                  return DropdownMenuItem<SimThemeStyle>(
                    value: style,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(style.icon, size: 14, color: simTheme.accent),
                        const SizedBox(width: 6),
                        Text(style.label, style: TextStyle(color: simTheme.textPrimary, fontSize: 11)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newStyle) {
                  if (newStyle != null) {
                    _ctrl.setThemeStyle(newStyle);
                    setState(() {});
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Telemetry Vitals
          Text(
            't = ${_ctrl.currentTime.toStringAsFixed(2)}s  |  ${_ctrl.fps.toStringAsFixed(0)} FPS',
            style: TextStyle(color: simTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
          ),
          const SizedBox(width: 14),

          // Library Dialog Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: simTheme.gridColor),
              foregroundColor: simTheme.textPrimary,
              backgroundColor: simTheme.background,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            icon: Icon(LucideIcons.layoutGrid, size: 14, color: simTheme.accent),
            label: const Text('Simulations Library', style: TextStyle(fontSize: 11)),
            onPressed: () => SimulationCatalogDialog.show(context),
          ),
          const SizedBox(width: 8),

          // Toggle Parameters Drawer
          IconButton(
            icon: Icon(
              _showParamsDrawer ? LucideIcons.panelRightClose : LucideIcons.panelRightOpen,
              size: 17,
              color: simTheme.textMuted,
            ),
            tooltip: _showParamsDrawer ? 'Hide Parameters' : 'Show Parameters',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _showParamsDrawer = !_showParamsDrawer),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBar(UiTheme ui, SimTheme simTheme) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: simTheme.panelBackground,
        border: Border(top: BorderSide(color: simTheme.gridColor)),
      ),
      child: Row(
        children: [
          // Play / Pause
          IconButton(
            icon: Icon(_ctrl.isPlaying ? LucideIcons.pause : LucideIcons.play, size: 18),
            color: simTheme.accent,
            tooltip: _ctrl.isPlaying ? 'Pause (Space)' : 'Play (Space)',
            onPressed: _ctrl.togglePlayPause,
          ),

          // Step Backward
          IconButton(
            icon: Icon(LucideIcons.stepBack, size: 16, color: simTheme.textPrimary),
            tooltip: 'Step Back ([)',
            onPressed: _ctrl.stepBackward,
          ),

          // Step Forward
          IconButton(
            icon: Icon(LucideIcons.stepForward, size: 16, color: simTheme.textPrimary),
            tooltip: 'Step Forward (])',
            onPressed: _ctrl.stepForward,
          ),

          // Reset
          IconButton(
            icon: Icon(LucideIcons.rotateCcw, size: 16, color: simTheme.textPrimary),
            tooltip: 'Reset to t=0',
            onPressed: _ctrl.reset,
          ),
          const SizedBox(width: 8),

          // Timeline History Scrubber
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                activeTrackColor: simTheme.accent,
                inactiveTrackColor: simTheme.gridColor,
                thumbColor: simTheme.accent,
                overlayColor: simTheme.accent.withValues(alpha: 0.25),
              ),
              child: Slider(
                min: 0.0,
                max: math.max(0.1, _ctrl.maxTime),
                value: _ctrl.currentTime.clamp(0.0, math.max(0.1, _ctrl.maxTime)).toDouble(),
                onChanged: (val) => _ctrl.seekToTime(val),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Speed Multiplier Dropdown
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: simTheme.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: simTheme.gridColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                value: _ctrl.speedMultiplier,
                dropdownColor: simTheme.panelBackground,
                style: TextStyle(color: simTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                items: const [
                  DropdownMenuItem(value: 0.1, child: Text('0.1x (Slow-Mo)')),
                  DropdownMenuItem(value: 0.25, child: Text('0.25x')),
                  DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                  DropdownMenuItem(value: 1.0, child: Text('1.0x (Real-Time)')),
                  DropdownMenuItem(value: 2.0, child: Text('2.0x')),
                  DropdownMenuItem(value: 5.0, child: Text('5.0x')),
                  DropdownMenuItem(value: 10.0, child: Text('10.0x (Fast)')),
                ],
                onChanged: (v) {
                  if (v != null) _ctrl.setSpeed(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParametersDrawer(UiTheme ui, SimTheme simTheme, SimulationModel model) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: simTheme.panelBackground,
        border: Border(left: BorderSide(color: simTheme.gridColor)),
      ),
      child: Column(
        children: [
          // Drawer Header
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: simTheme.panelBackground,
              border: Border(bottom: BorderSide(color: simTheme.gridColor)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.sliders, size: 15, color: simTheme.accent),
                const SizedBox(width: 8),
                Text(
                  'LIVE PARAMETERS',
                  style: TextStyle(
                    color: simTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    for (final p in model.parameters) {
                      p.reset();
                    }
                    _ctrl.reset();
                  },
                  child: Text('Reset', style: TextStyle(color: simTheme.accent, fontSize: 10)),
                ),
              ],
            ),
          ),

          // Drawer Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Presets Dropdown
                if (model.presets.isNotEmpty) ...[
                  Text(
                    'SCENARIO PRESETS',
                    style: TextStyle(
                      color: simTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: simTheme.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: simTheme.gridColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SimPreset>(
                        isExpanded: true,
                        dropdownColor: simTheme.panelBackground,
                        hint: Text('Choose Scenario...', style: TextStyle(color: simTheme.textMuted, fontSize: 12)),
                        items: model.presets.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(p.name, style: TextStyle(color: simTheme.textPrimary, fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (p) {
                          if (p != null) _ctrl.applyPreset(p);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Dynamic Live Parameters
                ...model.parameters.map((param) => _buildParameterControl(param, simTheme)),

                const SizedBox(height: 12),
                Divider(color: simTheme.gridColor),
                const SizedBox(height: 8),

                // Live Telemetry Readout
                Text(
                  'LIVE METRICS & TELEMETRY',
                  style: TextStyle(
                    color: simTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTelemetryCards(model, simTheme),

                const SizedBox(height: 20),

                // Record MP4 Video Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ctrl.videoRecorder.isRecording
                          ? const Color(0xFFFF1744)
                          : simTheme.accent,
                      foregroundColor: _ctrl.videoRecorder.isRecording
                          ? Colors.white
                          : (simTheme.isDark ? Colors.black : Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: Icon(_ctrl.videoRecorder.isRecording ? Icons.stop : LucideIcons.video, size: 16),
                    label: Text(
                      _ctrl.videoRecorder.isRecording ? 'Stop & Save MP4 Video' : 'Record Simulation (MP4)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: () async {
                      if (_ctrl.videoRecorder.isRecording) {
                        final savedPath = await _ctrl.stopAndSaveVideoRecording(context);
                        if (savedPath != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Simulation MP4 video saved to: $savedPath'),
                              backgroundColor: simTheme.accent,
                            ),
                          );
                        }
                      } else {
                        await _ctrl.startVideoRecording();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Export to MATLAB/UniLab Script
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: simTheme.gridColor),
                      foregroundColor: simTheme.textPrimary,
                      backgroundColor: simTheme.background,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: Icon(LucideIcons.fileCode, size: 15, color: simTheme.accent),
                    label: const Text('Export Script to Editor', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      final script = model.toUniLabScript();
                      final appProvider = context.read<AppProvider>();
                      appProvider.insertCodeIntoActiveScript(
                        script,
                        suggestedFileName: '${model.id}.m',
                        replaceAll: false,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Simulation script exported to code editor.')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterControl(SimParameter param, SimTheme simTheme) {
    if (param.type == SimParameterType.toggle) {
      return SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(param.name, style: TextStyle(color: simTheme.textPrimary, fontSize: 12)),
        value: param.value as bool,
        activeTrackColor: simTheme.accent,
        onChanged: (val) => _ctrl.updateParameter(param.id, val),
      );
    }

    if (param.type == SimParameterType.dropdown && param.options != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(param.name, style: TextStyle(color: simTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: simTheme.background,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: simTheme.gridColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: simTheme.panelBackground,
                value: param.value.toString(),
                items: param.options!.map((opt) {
                  return DropdownMenuItem(
                    value: opt,
                    child: Text(opt, style: TextStyle(color: simTheme.textPrimary, fontSize: 11)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) _ctrl.updateParameter(param.id, val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    // Default: Numeric Slider with Readout
    final numVal = (param.value as num).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                param.name,
                style: TextStyle(color: simTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${numVal.toStringAsFixed(2)} ${param.unit ?? ""}',
              style: TextStyle(
                color: simTheme.accent,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
            activeTrackColor: simTheme.accent,
            inactiveTrackColor: simTheme.gridColor,
            thumbColor: simTheme.accent,
          ),
          child: Slider(
            min: param.min,
            max: param.max,
            value: numVal.clamp(param.min, param.max),
            onChanged: (v) => _ctrl.updateParameter(param.id, v),
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryCards(SimulationModel model, SimTheme simTheme) {
    final metrics = model.getMetrics();
    if (metrics.isEmpty) {
      return Text('No telemetry available', style: TextStyle(color: simTheme.textMuted, fontSize: 11));
    }

    return Column(
      children: metrics.entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: simTheme.background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: simTheme.gridColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(color: simTheme.textMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                entry.value is num ? (entry.value as num).toStringAsFixed(2) : entry.value.toString(),
                style: TextStyle(
                  color: simTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SimCanvasPainter extends CustomPainter {
  final SimulationModel model;
  final SimCamera3D camera;
  final SimTheme theme;
  final bool is3D;

  _SimCanvasPainter({
    required this.model,
    required this.camera,
    required this.theme,
    required this.is3D,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Strict viewport clipping to prevent rendering bleed across IDE panels
    canvas.clipRect(Offset.zero & size);

    // 1. Draw Canvas Background
    canvas.drawRect(Offset.zero & size, Paint()..color = theme.background);

    // 2. Delegate to active model
    if (is3D) {
      model.render3D(canvas, size, camera, theme);
    } else {
      model.render2D(canvas, size, theme);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SimCanvasPainter oldDelegate) => true;
}
