import 'package:flutter/material.dart';
import 'syntax_themes.dart';

@immutable
class UiColors {
  const UiColors({
    required this.canvas,
    required this.panel,
    required this.panelHeader,
    required this.ribbonTabs,
    required this.overlay,
    required this.hover,
    required this.selected,
    required this.selectedMuted,
    required this.divider,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.textInverse,
    required this.accent,
    required this.accentHover,
    required this.accentMuted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.tan,
    required this.yellow,
    required this.icon,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
    required this.glassBackground,
    required this.glassBorder,
  });

  final Color canvas;
  final Color panel;
  final Color panelHeader;
  final Color ribbonTabs;
  final Color overlay;
  final Color hover;
  final Color selected;
  final Color selectedMuted;
  final Color divider;
  final Color border;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color textInverse;

  final Color accent;
  final Color accentHover;
  final Color accentMuted;

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color tan;
  final Color yellow;

  final Color icon;

  // Shadow and Glass tokens
  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowLg;
  final Color glassBackground;
  final Color glassBorder;

  UiColors copyWith({
    Color? canvas,
    Color? panel,
    Color? panelHeader,
    Color? ribbonTabs,
    Color? overlay,
    Color? hover,
    Color? selected,
    Color? selectedMuted,
    Color? divider,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? textInverse,
    Color? accent,
    Color? accentHover,
    Color? accentMuted,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? tan,
    Color? yellow,
    Color? icon,
    List<BoxShadow>? shadowSm,
    List<BoxShadow>? shadowMd,
    List<BoxShadow>? shadowLg,
    Color? glassBackground,
    Color? glassBorder,
  }) {
    return UiColors(
      canvas: canvas ?? this.canvas,
      panel: panel ?? this.panel,
      panelHeader: panelHeader ?? this.panelHeader,
      ribbonTabs: ribbonTabs ?? this.ribbonTabs,
      overlay: overlay ?? this.overlay,
      hover: hover ?? this.hover,
      selected: selected ?? this.selected,
      selectedMuted: selectedMuted ?? this.selectedMuted,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      textInverse: textInverse ?? this.textInverse,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentMuted: accentMuted ?? this.accentMuted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      tan: tan ?? this.tan,
      yellow: yellow ?? this.yellow,
      icon: icon ?? this.icon,
      shadowSm: shadowSm ?? this.shadowSm,
      shadowMd: shadowMd ?? this.shadowMd,
      shadowLg: shadowLg ?? this.shadowLg,
      glassBackground: glassBackground ?? this.glassBackground,
      glassBorder: glassBorder ?? this.glassBorder,
    );
  }

  factory UiColors.dark() => UiColors(
        canvas: const Color(0xFF1E1E1E), // Standard IDE Background
        panel: const Color(0xFF1E1E1E),
        panelHeader: const Color(0xFF252526),
        ribbonTabs: const Color(0xFF2D2D30),
        overlay: const Color(0xFF252526),
        hover: const Color(0xFF2A2D2E),
        selected: const Color(0xFF37373D),
        selectedMuted: const Color(0xFF2A2D2E),
        divider: const Color(0xFF3F3F46),
        border: const Color(0xFF3F3F46),
        textPrimary: const Color(0xFFE2E4E9),
        textSecondary: const Color(0xFFADB3BD),
        textMuted: const Color(0xFF8B949E),
        textDisabled: const Color(0xFF626971),
        textInverse: const Color(0xFFFFFFFF),
        accent: const Color(0xFF4AA3FF),
        accentHover: const Color(0xFF6BB1FF),
        accentMuted: const Color(0xFF264F78),
        success: const Color(0xFF23D18B),
        warning: const Color(0xFFE5E510),
        danger: const Color(0xFFF14C4C),
        info: const Color(0xFF4AA3FF),
        tan: const Color(0xFFE5D8BD),
        yellow: const Color(0xFFFFFFCC),
        icon: const Color(0xFFADB3BD),
        glassBackground: const Color(0xCC252526),
        glassBorder: const Color(0x334AA3FF),
        shadowSm: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        shadowMd: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
        shadowLg: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      );
      
  factory UiColors.light() => UiColors(
        canvas: const Color(0xFFFFFFFF),
        panel: const Color(0xFFF3F3F3),
        panelHeader: const Color(0xFFE0E0E0),
        ribbonTabs: const Color(0xFFE0E0E0),
        overlay: const Color(0xFFFFFFFF),
        hover: const Color(0xFFE5E5E5),
        selected: const Color(0xFFD3E3FD),
        selectedMuted: const Color(0xFFE8ECEF),
        divider: const Color(0xFFD0D0D0),
        border: const Color(0xFFC0C0C0),
        textPrimary: const Color(0xFF333333),
        textSecondary: const Color(0xFF666666),
        textMuted: const Color(0xFF858585),
        textDisabled: const Color(0xFFA0A0A0),
        textInverse: const Color(0xFFFFFFFF),
        accent: const Color(0xFF0078D4),
        accentHover: const Color(0xFF006CBE),
        accentMuted: const Color(0xFFE0EFFF),
        success: const Color(0xFF107C10),
        warning: const Color(0xFF797700),
        danger: const Color(0xFFD13438),
        info: const Color(0xFF005A9E),
        tan: const Color(0xFF8B7355),
        yellow: const Color(0xFFB8860B),
        icon: const Color(0xFF666666),
        glassBackground: const Color(0xCCFFFFFF),
        glassBorder: const Color(0x33000000),
        shadowSm: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        shadowMd: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        shadowLg: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  /// Derive a full-application UI color palette from a [SyntaxHighlightTheme]
  /// so changing the code highlight theme transforms the entire IDE shell.
  factory UiColors.fromSyntaxTheme(
    SyntaxHighlightTheme syntaxTheme, {
    Color? customAccent,
  }) {
    final bg = syntaxTheme.backgroundColor;
    final fg = syntaxTheme.foregroundColor;
    final isLight = bg.computeLuminance() > 0.5;
    final themePrimary = syntaxTheme.colors.isNotEmpty
        ? syntaxTheme.colors.first
        : (isLight ? const Color(0xFF0078D4) : const Color(0xFF4AA3FF));

    // Use the syntax theme's signature highlight color unless the user picked a non-default custom accent
    final bool hasCustomAccent = customAccent != null &&
        customAccent.toARGB32() != const Color(0xFF4AA3FF).toARGB32();
    final Color accent = hasCustomAccent ? customAccent : themePrimary;

    final Color panel = isLight
        ? Color.lerp(bg, const Color(0xFF000000), 0.04)!
        : Color.lerp(bg, const Color(0xFF000000), 0.16)!;
    final Color panelHeader = isLight
        ? Color.lerp(bg, const Color(0xFF000000), 0.08)!
        : Color.lerp(bg, const Color(0xFFFFFFFF), 0.05)!;
    final Color ribbonTabs = isLight
        ? Color.lerp(bg, const Color(0xFF000000), 0.12)!
        : Color.lerp(bg, const Color(0xFF000000), 0.26)!;
    final Color overlay = isLight
        ? bg
        : Color.lerp(bg, const Color(0xFFFFFFFF), 0.07)!;
    final Color hover = Color.lerp(bg, fg, 0.09)!;
    final Color selected = Color.lerp(bg, accent, isLight ? 0.18 : 0.24)!;
    final Color selectedMuted = Color.lerp(bg, fg, 0.11)!;
    final Color divider = Color.lerp(bg, fg, isLight ? 0.18 : 0.15)!;
    final Color border = Color.lerp(bg, fg, isLight ? 0.22 : 0.18)!;

    final Color textPrimary = fg;
    final Color textSecondary = Color.lerp(fg, bg, 0.25)!;
    final Color textMuted = Color.lerp(fg, bg, 0.44)!;
    final Color textDisabled = Color.lerp(fg, bg, 0.62)!;
    final Color textInverse = accent.computeLuminance() > 0.55
        ? const Color(0xFF121212)
        : const Color(0xFFFFFFFF);

    final Color accentHover =
        Color.lerp(accent, isLight ? Colors.black : Colors.white, 0.16)!;
    final Color accentMuted = accent.withValues(alpha: 0.22);

    return UiColors(
      canvas: bg,
      panel: panel,
      panelHeader: panelHeader,
      ribbonTabs: ribbonTabs,
      overlay: overlay,
      hover: hover,
      selected: selected,
      selectedMuted: selectedMuted,
      divider: divider,
      border: border,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      textDisabled: textDisabled,
      textInverse: textInverse,
      accent: accent,
      accentHover: accentHover,
      accentMuted: accentMuted,
      success: syntaxTheme.colors.length > 1
          ? syntaxTheme.colors[1]
          : (isLight ? const Color(0xFF107C10) : const Color(0xFF23D18B)),
      warning: syntaxTheme.colors.length > 2
          ? syntaxTheme.colors[2]
          : (isLight ? const Color(0xFF797700) : const Color(0xFFE5E510)),
      danger: isLight ? const Color(0xFFD13438) : const Color(0xFFF14C4C),
      info: syntaxTheme.colors.length > 3 ? syntaxTheme.colors[3] : accent,
      tan: isLight ? const Color(0xFF8B7355) : const Color(0xFFE5D8BD),
      yellow: isLight ? const Color(0xFFB8860B) : const Color(0xFFFFFFCC),
      icon: textSecondary,
      glassBackground: panelHeader.withValues(alpha: 0.85),
      glassBorder: accent.withValues(alpha: 0.25),
      shadowSm: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isLight ? 0.06 : 0.22),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
      shadowMd: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isLight ? 0.10 : 0.40),
          blurRadius: 12,
          offset: const Offset(0, 8),
        ),
      ],
      shadowLg: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isLight ? 0.14 : 0.50),
          blurRadius: 30,
          offset: const Offset(0, 15),
          spreadRadius: -5,
        ),
      ],
    );
  }
}
