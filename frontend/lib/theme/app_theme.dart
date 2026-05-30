import 'package:flutter/material.dart';
import 'ui_theme.dart';
import '../models/models.dart';

/// Centralized theme configuration for UniLab IDE
class AppTheme {
  /// Create theme data based on user settings and brightness
  static ThemeData createTheme(UserSettings settings, Brightness brightness) {
    final uiTheme = createUiTheme(settings, brightness);
    return buildAppThemeData(uiTheme, brightness);
  }

  // Shims for legacy code if any remains
  static Color getAccent(BuildContext context) => UiTheme.of(context).colors.accent;
}
