import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/sim_definition.dart';
import '../models/sim_camera_3d.dart';
import '../models/sim_state_buffer.dart';
import 'simulation_registry.dart';
import 'simulation_video_recorder.dart';

/// Central state controller powering the in-window Simulation Studio.
class SimulationController extends ChangeNotifier {
  static final SimulationController instance = SimulationController._internal();

  SimulationController._internal() {
    _activeModel = SimulationRegistry.instance.all.first;
    _activeModel.init();
    _stateBuffer.addSnapshot(_activeModel.captureSnapshot());
    _startLoop();
  }

  late SimulationModel _activeModel;
  final SimCamera3D _camera3D = SimCamera3D();
  final SimulationStateBuffer _stateBuffer = SimulationStateBuffer();
  final SimulationVideoRecorder _videoRecorder = SimulationVideoRecorder();
  final GlobalKey _canvasKey = GlobalKey();
  SimThemeStyle _themeStyle = SimThemeStyle.obsidian;

  bool _isPlaying = true;
  double _fps = 60.0;
  DateTime _lastFrameTime = DateTime.now();
  Ticker? _ticker;
  bool _isDisposed = false;

  // Getters
  SimulationModel get activeModel => _activeModel;
  SimCamera3D get camera3D => _camera3D;
  SimulationStateBuffer get stateBuffer => _stateBuffer;
  SimulationVideoRecorder get videoRecorder => _videoRecorder;
  GlobalKey get canvasKey => _canvasKey;
  SimThemeStyle get themeStyle => _themeStyle;
  bool get isPlaying => _isPlaying;
  double get fps => _fps;
  double get speedMultiplier => _stateBuffer.speedMultiplier;
  double get currentTime => _stateBuffer.currentTime;
  double get maxTime => _stateBuffer.maxTime;
  bool get is3D => _activeModel.dimension == SimDimension.threeD;

  SimTheme get currentTheme {
    switch (_themeStyle) {
      case SimThemeStyle.obsidian:
        return SimTheme.obsidian();
      case SimThemeStyle.cyberMatrix:
        return SimTheme.cyberMatrix();
      case SimThemeStyle.blueprint:
        return SimTheme.blueprint();
      case SimThemeStyle.laboratory:
        return SimTheme.laboratory();
    }
  }

  void setThemeStyle(SimThemeStyle style) {
    _themeStyle = style;
    notifyListeners();
  }

  void _startLoop() {
    _ticker = Ticker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (_isDisposed) return;

    final now = DateTime.now();
    final dtSeconds = (now.difference(_lastFrameTime).inMicroseconds / 1e6).clamp(0.001, 0.05);
    _lastFrameTime = now;
    _fps = (1.0 / dtSeconds) * 0.15 + _fps * 0.85;

    if (_isPlaying && !_stateBuffer.isScrubbing) {
      final effectiveDt = dtSeconds * _stateBuffer.speedMultiplier;
      _activeModel.step(effectiveDt);
      _stateBuffer.addSnapshot(_activeModel.captureSnapshot());

      // Frame capture for MP4 video recording
      if (_videoRecorder.isRecording) {
        _videoRecorder.captureFrame(_canvasKey);
      }
    }

    notifyListeners();
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    if (_isPlaying && _stateBuffer.isScrubbing) {
      _stateBuffer.resumeFromScrub();
    }
    notifyListeners();
  }

  void play() {
    _isPlaying = true;
    _stateBuffer.resumeFromScrub();
    notifyListeners();
  }

  void pause() {
    _isPlaying = false;
    notifyListeners();
  }

  void stepForward() {
    _isPlaying = false;
    final snapshot = _stateBuffer.stepForward();
    if (snapshot != null) {
      _activeModel.restoreSnapshot(snapshot);
    }
    notifyListeners();
  }

  void stepBackward() {
    _isPlaying = false;
    final snapshot = _stateBuffer.stepBackward();
    if (snapshot != null) {
      _activeModel.restoreSnapshot(snapshot);
    }
    notifyListeners();
  }

  void reset() {
    _activeModel.reset();
    _stateBuffer.clear();
    _stateBuffer.addSnapshot(_activeModel.captureSnapshot());
    _camera3D.reset();
    notifyListeners();
  }

  void seekToTime(double time) {
    _isPlaying = false;
    final snapshot = _stateBuffer.seekToTime(time);
    if (snapshot != null) {
      _activeModel.restoreSnapshot(snapshot);
    }
    notifyListeners();
  }

  void setSpeed(double multiplier) {
    _stateBuffer.speedMultiplier = multiplier;
    notifyListeners();
  }

  void selectModel(String modelId) {
    final model = SimulationRegistry.instance.getById(modelId);
    if (model != null && model.id != _activeModel.id) {
      _activeModel = model;
      _activeModel.init();
      _stateBuffer.clear();
      _stateBuffer.addSnapshot(_activeModel.captureSnapshot());
      _camera3D.reset();
      notifyListeners();
    }
  }

  void applyPreset(SimPreset preset) {
    _activeModel.applyPreset(preset);
    reset();
    notifyListeners();
  }

  void updateParameter(String paramId, dynamic value) {
    _activeModel.setParameter(paramId, value);
    notifyListeners();
  }

  Future<bool> startVideoRecording() async {
    return await _videoRecorder.startRecording();
  }

  Future<String?> stopAndSaveVideoRecording(BuildContext context) async {
    return await _videoRecorder.stopAndSaveRecording(context, modelName: _activeModel.id);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _ticker?.dispose();
    _videoRecorder.dispose();
    super.dispose();
  }
}
