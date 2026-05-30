import 'package:flutter/material.dart';
import 'ui_theme.dart';
import 'ui_density.dart';

/// Centralized theme configuration for UniLab IDE
/// Migrated to use UiTheme as a ThemeExtension.
class AppTheme {
  // Temporary shim for older widgets during migration
  static const Color darkCanvasBackground = Color(0xFF1E1E1E);
  static const Color darkPanelBackground = Color(0xFF252526);
  static const Color darkRibbonBackground = Color(0xFF2D2D30);
  static const Color darkBorderColor = Color(0xFF3F3F46);
  static const Color darkDividerColor = Color(0xFF333333);
  static const Color darkAccentColor = Color(0xFF2F88FF); 
  static const Color darkHoverColor = Color(0xFF2E2E32);
  static const Color darkTextPrimary = Color(0xFFE6E6E6);
  static const Color darkTextSecondary = Color(0xFFBBBBBB);
  static const Color darkTextTertiary = Color(0xFF858585);

  static const Color editorActiveLineBackground = Color(0xFF2C2C2D);
  static const Color editorCursorColor = Color(0xFFFFFFFE);
  static const Color editorSelectionColor = Color(0xFF264F78);
  static const Color editorGutterBackground = Color(0xFF252526);
  static const Color editorGutterForeground = Color(0xFF858585);
  static const Color editorLineNumberBackground = Color(0xFF1E1E1E);

  /// Create dark theme
  static ThemeData createDarkTheme() {
    final uiTheme = createDarkThemeMode(UiDensity.comfortable);
    return buildAppThemeData(uiTheme);
  }

  /// Create light theme (currently not shipped, but placeholder available)
  static ThemeData createLightTheme() {
    // We can use dark theme for now or implement a light mode UiTheme
    final uiTheme = createDarkThemeMode(UiDensity.comfortable); // fallback
    return buildAppThemeData(uiTheme);
  }
}

UiTheme createDarkThemeMode(UiDensity density) {
  return createDarkTheme(density);
}