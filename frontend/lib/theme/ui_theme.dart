import 'package:flutter/material.dart';

import 'ui_colors.dart';
import 'ui_typography.dart';
import 'ui_spacing.dart';
import 'ui_density.dart';
import 'syntax_palette.dart';
import 'syntax_themes.dart';
import '../models/models.dart';

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

UiTheme createUiTheme(UserSettings settings, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final baseColors = isDark ? UiColors.dark() : UiColors.light();
  
  // Find the selected syntax theme
  final syntaxTheme = SyntaxHighlightTheme.all.firstWhere(
    (t) => t.name == settings.syntaxHighlightTheme,
    orElse: () => SyntaxHighlightTheme.all.first,
  );

  // Determine background and text colors based on interface theme and syntax theme
  final Color canvasColor = isDark ? syntaxTheme.backgroundColor : baseColors.canvas;
  final Color panelColor = isDark ? syntaxTheme.backgroundColor : baseColors.panel;
  final Color headerColor = isDark ? syntaxTheme.backgroundColor : baseColors.panelHeader;
  
  // Use syntax theme foreground for text in dark mode for better integration
  final Color textPrimary = isDark ? syntaxTheme.foregroundColor : baseColors.textPrimary;
  final Color textSecondary = isDark ? syntaxTheme.foregroundColor.withValues(alpha: 0.7) : baseColors.textSecondary;
  final Color textMuted = isDark ? syntaxTheme.foregroundColor.withValues(alpha: 0.5) : baseColors.textMuted;

  final colors = baseColors.copyWith(
    canvas: canvasColor,
    panel: panelColor,
    panelHeader: headerColor,
    ribbonTabs: headerColor,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textMuted: textMuted,
    accent: settings.accentColor,
    accentHover: settings.accentColor.withValues(alpha: 0.8),
  );

  return UiTheme(
    colors: colors,
    typography: UiTypography.base(
      colors.textPrimary, 
      colors.textMuted, 
      scale: settings.uiScale,
      codeFontFamily: settings.fontFamily,
    ),
    spacing: UiSpacing.standard(scale: settings.uiScale),
    density: UiDensity.comfortable,
    syntax: isDark ? SyntaxPalette.darkPlus() : SyntaxPalette.lightPlus(),
  );
}

ThemeData buildAppThemeData(UiTheme uiTheme, Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: brightness == Brightness.dark 
      ? ColorScheme.dark(
          surface: uiTheme.colors.panel,
          primary: uiTheme.colors.accent,
          onPrimary: uiTheme.colors.textInverse,
          secondary: uiTheme.colors.accentMuted,
          error: uiTheme.colors.danger,
        )
      : ColorScheme.light(
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