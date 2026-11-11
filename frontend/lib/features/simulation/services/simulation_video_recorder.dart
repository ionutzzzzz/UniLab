import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

/// Service managing in-window MP4 video recording of the simulation canvas.
class SimulationVideoRecorder extends ChangeNotifier {
  bool _isRecording = false;
  int _recordedFrames = 0;
  DateTime? _recordingStartTime;
  Directory? _tempDir;
  Timer? _recordingTimer;
  String _recordingDurationString = '00:00';
  bool _isExporting = false;

  bool get isRecording => _isRecording;
  int get recordedFrames => _recordedFrames;
  String get recordingDurationString => _recordingDurationString;
  bool get isExporting => _isExporting;

  /// Starts recording frames from the provided [boundaryKey].
  Future<bool> startRecording() async {
    if (_isRecording || _isExporting) return false;

    try {
      final now = DateTime.now();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final tempBase = Directory.systemTemp.path;
      _tempDir = Directory('$tempBase/unilab_rec_$stamp');
      if (await _tempDir!.exists()) {
        await _tempDir!.delete(recursive: true);
      }
      await _tempDir!.create(recursive: true);

      _isRecording = true;
      _recordedFrames = 0;
      _recordingStartTime = now;
      _recordingDurationString = '00:00';

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_recordingStartTime != null) {
          final diff = DateTime.now().difference(_recordingStartTime!);
          final minutes = diff.inMinutes.toString().padLeft(2, '0');
          final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
          _recordingDurationString = '$minutes:$seconds';
          notifyListeners();
        }
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error starting video recording: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Captures a single rendered frame from the RepaintBoundary.
  Future<void> captureFrame(GlobalKey boundaryKey) async {
    if (!_isRecording || _tempDir == null) return;

    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Capture canvas as image at 1.0 pixel ratio for optimal performance
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (byteData != null && _tempDir != null && _isRecording) {
        final frameNum = _recordedFrames.toString().padLeft(5, '0');
        final file = File('${_tempDir!.path}/frame_$frameNum.png');
        await file.writeAsBytes(byteData.buffer.asUint8List(), flush: false);
        _recordedFrames++;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Frame capture error: $e');
    }
  }

  /// Stops recording and compiles buffered frames into an MP4 file.
  Future<String?> stopAndSaveRecording(BuildContext context, {String modelName = 'simulation'}) async {
    if (!_isRecording && !_isExporting) return null;

    _isRecording = false;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _isExporting = true;
    notifyListeners();

    if (_tempDir == null || _recordedFrames == 0) {
      _isExporting = false;
      notifyListeners();
      return null;
    }

    try {
      final now = DateTime.now();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final sanitizedName = modelName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final defaultFileName = 'UniLab_${sanitizedName}_$stamp.mp4';

      // Ask user where to save the MP4 video
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Simulation MP4 Video',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['mp4'],
      );

      if (outputPath == null) {
        // User cancelled save dialog
        await _cleanupTemp();
        _isExporting = false;
        notifyListeners();
        return null;
      }

      if (!outputPath.endsWith('.mp4')) {
        outputPath += '.mp4';
      }

      // Locate video_exporter.py
      final rootDir = Directory.current.path;
      final scriptCandidates = [
        '$rootDir/backend/utils/exporters/video_exporter.py',
        '$rootDir/../backend/utils/exporters/video_exporter.py',
      ];

      String? scriptPath;
      for (final candidate in scriptCandidates) {
        if (await File(candidate).exists()) {
          scriptPath = candidate;
          break;
        }
      }

      if (scriptPath == null) {
        throw Exception('video_exporter.py not found');
      }

      // Run OpenCV MP4 compilation worker
      final result = await Process.run('python3', [
        scriptPath,
        '--input-dir',
        _tempDir!.path,
        '--output',
        outputPath,
        '--fps',
        '30',
      ]);

      if (result.exitCode != 0) {
        throw Exception('Video compilation failed: ${result.stderr}');
      }

      await _cleanupTemp();
      _isExporting = false;
      notifyListeners();
      return outputPath;
    } catch (e) {
      debugPrint('Failed to save simulation video: $e');
      await _cleanupTemp();
      _isExporting = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _cleanupTemp() async {
    if (_tempDir != null && await _tempDir!.exists()) {
      try {
        await _tempDir!.delete(recursive: true);
      } catch (_) {}
      _tempDir = null;
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _cleanupTemp();
    super.dispose();
  }
}
