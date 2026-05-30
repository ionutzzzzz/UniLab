import 'dart:io' as io;
import 'package:flutter/material.dart';
import '../../../../theme/ui_theme.dart';
import '../../../../widgets/ui_text.dart';

class ImageViewer extends StatelessWidget {
  final String path;
  final String name;

  const ImageViewer({super.key, required this.path, required this.name});

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return Container(
      color: ui.colors.canvas,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: InteractiveViewer(
                  maxScale: 5.0,
                  child: Image.file(
                    io.File(path),
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image, size: 64, color: ui.colors.danger),
                          const SizedBox(height: 16),
                          UiText(text: 'Failed to load image', color: ui.colors.textMuted),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: ui.colors.panelHeader,
            child: Row(
              children: [
                Icon(Icons.image, size: 14, color: ui.colors.accent),
                const SizedBox(width: 8),
                UiText(text: name, variant: UiTextVariant.caption),
                const Spacer(),
                UiText(text: 'Pinch to zoom', variant: UiTextVariant.caption, color: ui.colors.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
