import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../theme/ui_theme.dart';
import '../../../../widgets/ui_text.dart';
import '../../../../utils/platform_io.dart' as io;

class AudioViewer extends StatefulWidget {
  final String path;
  final String name;

  const AudioViewer({super.key, required this.path, required this.name});

  @override
  State<AudioViewer> createState() => _AudioViewerState();
}

class _AudioViewerState extends State<AudioViewer> {
  bool _isPlaying = false;
  double _position = 0.0;
  int _fileSizeBytes = 0;
  int _sampleRate = 44100;
  int _numChannels = 2;
  int _bitsPerSample = 16;
  double _totalDurationSeconds = 0.0;
  List<double> _waveformBars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAudioFile();
  }

  Future<void> _loadAudioFile() async {
    try {
      if (!kIsWeb && io.File(widget.path).existsSync()) {
        final file = io.File(widget.path);
        final bytes = await file.readAsBytes();
        _fileSizeBytes = bytes.length;

        // Parse WAV headers if available
        if (bytes.length >= 44 &&
            String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
            String.fromCharCodes(bytes.sublist(8, 12)) == 'WAVE') {
          _numChannels = bytes[22] | (bytes[23] << 8);
          _sampleRate = bytes[24] | (bytes[25] << 8) | (bytes[26] << 16) | (bytes[27] << 24);
          _bitsPerSample = bytes[34] | (bytes[35] << 8);
          final byteRate = bytes[28] | (bytes[29] << 8) | (bytes[30] << 16) | (bytes[31] << 24);
          final dataSize = bytes.length > 44 ? bytes.length - 44 : 0;
          if (byteRate > 0) {
            _totalDurationSeconds = dataSize / byteRate;
          }
        } else {
          _totalDurationSeconds = math.max(1.0, _fileSizeBytes / 176400.0);
        }

        // Generate 48 waveform amplitude points from raw bytes
        _waveformBars = _generateWaveform(bytes, 48);
      } else {
        _fileSizeBytes = 1024 * 512;
        _totalDurationSeconds = 45.0;
        _waveformBars = List.generate(48, (i) => 0.15 + 0.7 * (math.sin(i * 0.3).abs()));
      }
    } catch (_) {
      _waveformBars = List.generate(48, (i) => 0.2 + 0.6 * math.Random(i).nextDouble());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<double> _generateWaveform(Uint8List bytes, int barCount) {
    if (bytes.length < 100) {
      return List.filled(barCount, 0.3);
    }
    final int startOffset = math.min(44, bytes.length ~/ 2);
    final int dataLen = bytes.length - startOffset;
    final int chunkSize = math.max(1, dataLen ~/ barCount);

    final List<double> bars = [];
    double maxAmp = 1.0;

    for (int i = 0; i < barCount; i++) {
      int sum = 0;
      int count = 0;
      final start = startOffset + i * chunkSize;
      final end = math.min(start + chunkSize, bytes.length);

      for (int j = start; j < end; j += 4) {
        final val = (bytes[j] - 128).abs();
        sum += val;
        count++;
      }
      final avg = count > 0 ? (sum / count) : 10.0;
      bars.add(avg);
      if (avg > maxAmp) maxAmp = avg;
    }

    return bars.map((b) => (b / maxAmp).clamp(0.12, 1.0)).toList();
  }

  String _formatTime(double seconds) {
    final int s = seconds.toInt();
    final int m = s ~/ 60;
    final int sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: ui.colors.accent),
      );
    }
    final duration = _totalDurationSeconds > 0 ? _totalDurationSeconds : 1.0;
    final currentPosSec = (_position / 100.0) * duration;

    return Container(
      color: ui.colors.canvas,
      child: Center(
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: ui.colors.panel,
            borderRadius: ui.spacing.radiusLg,
            border: Border.all(color: ui.colors.divider),
            boxShadow: ui.colors.shadowLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: ui.colors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.audioWaveform, size: 36, color: ui.colors.accent),
              ),
              const SizedBox(height: 20),
              UiText(text: widget.name, variant: UiTextVariant.title, fontSize: 16, fontWeight: FontWeight.bold),
              const SizedBox(height: 6),
              UiText(
                text: '${_formatFileSize(_fileSizeBytes)} • $_sampleRate Hz • ${_numChannels == 1 ? 'Mono' : 'Stereo'} • $_bitsPerSample-bit',
                variant: UiTextVariant.caption,
                color: ui.colors.textMuted,
              ),
              const SizedBox(height: 28),

              // Waveform Display
              Container(
                height: 60,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(_waveformBars.length, (i) {
                    final fraction = i / _waveformBars.length;
                    final isPlayed = fraction <= (_position / 100.0);
                    final barHeight = math.max(4.0, 52.0 * _waveformBars[i]);

                    return Container(
                      width: 4,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: isPlayed ? ui.colors.accent : ui.colors.accent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),

              Slider(
                value: _position,
                max: 100.0,
                activeColor: ui.colors.accent,
                onChanged: (val) {
                  setState(() => _position = val);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    UiText(text: _formatTime(currentPosSec), variant: UiTextVariant.caption),
                    UiText(text: _formatTime(duration), variant: UiTextVariant.caption),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.rotateCcw, size: 20),
                    tooltip: 'Back 10s',
                    onPressed: () {
                      final stepPercent = duration > 0 ? (10.0 / duration) * 100.0 : 5.0;
                      setState(() => _position = math.max(0.0, _position - stepPercent));
                    },
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: ui.colors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(_isPlaying ? LucideIcons.pause : LucideIcons.play, color: Colors.white, size: 26),
                      onPressed: () {
                        setState(() => _isPlaying = !_isPlaying);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(LucideIcons.rotateCw, size: 20),
                    tooltip: 'Forward 10s',
                    onPressed: () {
                      final stepPercent = duration > 0 ? (10.0 / duration) * 100.0 : 5.0;
                      setState(() => _position = math.min(100.0, _position + stepPercent));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}