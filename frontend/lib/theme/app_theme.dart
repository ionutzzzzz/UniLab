import 'package:flutter/material.dart';
import 'ui_theme.dart';
import 'syntax_themes.dart';
import '../models/models.dart';

/// Centralized theme configuration for UniLab IDE
class AppTheme {
  /// Create theme data based on user settings and syntax highlight theme
  static ThemeData createTheme(UserSettings settings, Brightness brightness) {
    final syntaxTheme = SyntaxHighlightTheme.all.firstWhere(
      (t) => t.name == settings.syntaxHighlightTheme,
      orElse: () => SyntaxHighlightTheme.all.first,
    );
    final effectiveBrightness =
        syntaxTheme.backgroundColor.computeLuminance() > 0.5
            ? Brightness.light
            : Brightness.dark;
    final uiTheme = createUiTheme(settings, effectiveBrightness);
    return buildAppThemeData(uiTheme, effectiveBrightness);
  }

  // Shims for legacy code if any remains
  static Color getAccent(BuildContext context) => UiTheme.of(context).colors.accent;
}
