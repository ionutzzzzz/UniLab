import 'package:flutter/material.dart';
import '../../../../theme/ui_theme.dart';
import '../../../../widgets/ui_text.dart';

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

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return Container(
      color: ui.colors.canvas,
      child: Center(
        child: Container(
          width: 400,
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
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ui.colors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.music_note, size: 40, color: ui.colors.accent),
              ),
              const SizedBox(height: 24),
              UiText(text: widget.name, variant: UiTextVariant.body, fontWeight: FontWeight.bold),
              const SizedBox(height: 8),
              UiText(text: 'Audio File', variant: UiTextVariant.caption, color: ui.colors.textMuted),
              const SizedBox(height: 32),
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
                    UiText(text: '0:00', variant: UiTextVariant.caption),
                    UiText(text: '3:45', variant: UiTextVariant.caption),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: ui.colors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 32),
                      onPressed: () {
                        setState(() => _isPlaying = !_isPlaying);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    onPressed: () {},
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