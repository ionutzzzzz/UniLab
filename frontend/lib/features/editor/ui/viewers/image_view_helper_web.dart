import 'package:flutter/material.dart';
import '../../../../theme/ui_theme.dart';

Widget buildPlatformImage(String path, UiTheme ui) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off, size: 64, color: ui.colors.textDisabled),
        const SizedBox(height: 16),
        Text('Image viewing on web is not yet supported.', style: TextStyle(color: ui.colors.textSecondary)),
      ],
    ),
  );
}
