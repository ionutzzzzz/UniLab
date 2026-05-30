import 'package:flutter/material.dart';

import 'ui_colors.dart';
import 'ui_typography.dart';
import 'ui_spacing.dart';
import 'ui_density.dart';
import 'syntax_palette.dart';

@immutable
class UiTheme extends ThemeExtension<UiTheme> {
  const UiTheme({
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.density,
    required this.syntax,
  });

  final UiColors colors;
  final UiTypography typography;
  final UiSpacing spacing;
  final UiDensity density;
  final SyntaxPalette syntax;

  static UiTheme of(BuildContext context) => Theme.of(context).extension<UiTheme>()!;

  @override
  UiTheme copyWith({
    UiColors? colors,
    UiTypography? typography,
    UiSpacing? spacing,
    UiDensity? density,
    SyntaxPalette? syntax,
  }) {
    return UiTheme(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
      spacing: spacing ?? this.spacing,
      density: density ?? this.density,
      syntax: syntax ?? this.syntax,
    );
  }

  @override
  UiTheme lerp(ThemeExtension<UiTheme>? other, double t) {
    // Shell colors don't lerp — instant flip on theme switch
    return this;
  }
}

// Global accessor for convenience, but context-based lookup is preferred.
UiTheme createDarkTheme(UiDensity density) {
  final colors = UiColors.dark();
  return UiTheme(
    colors: colors,
    typography: UiTypography.base(colors.textPrimary, colors.textMuted),
    spacing: UiSpacing.standard(),
    density: density,
    syntax: SyntaxPalette.darkPlus(),
  );
}

ThemeData buildAppThemeData(UiTheme uiTheme) {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark, // Assuming dark theme for now
    colorScheme: ColorScheme.dark(
      surface: uiTheme.colors.panel,
      primary: uiTheme.colors.accent,
      onPrimary: uiTheme.colors.textInverse,
      secondary: uiTheme.colors.accentMuted,
      error: uiTheme.colors.danger,
    ),
    scaffoldBackgroundColor: uiTheme.colors.canvas,
    extensions: <ThemeExtension<dynamic>>[
      uiTheme,
    ],
  );
}
