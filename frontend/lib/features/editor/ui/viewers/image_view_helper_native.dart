import 'dart:io' as io;
import 'package:flutter/material.dart';
import '../../../../theme/ui_theme.dart';

Widget buildPlatformImage(String path, UiTheme ui) {
  return Image.file(
    io.File(path),
    errorBuilder: (context, error, stackTrace) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image, size: 64, color: ui.colors.danger),
          const SizedBox(height: 16),
          Text('Failed to load image', style: TextStyle(color: ui.colors.textMuted)),
        ],
      );
    },
  );
}
