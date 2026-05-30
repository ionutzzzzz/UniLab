import 'package:flutter/material.dart';

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

  factory UiColors.dark() => UiColors(
        canvas: const Color(0xFF0F1115),
        panel: const Color(0xFF16191E),
        panelHeader: const Color(0xFF1A1D23),
        ribbonTabs: const Color(0xFF121419),
        overlay: const Color(0xFF1A1D23),
        hover: const Color(0xFF232830),
        selected: const Color(0xFF2D343F),
        selectedMuted: const Color(0xFF1C2028),
        divider: const Color(0xFF2A2D35),
        border: const Color(0xFF2A2D35),
        textPrimary: const Color(0xFFE2E4E9),
        textSecondary: const Color(0xFFADB3BD),
        textMuted: const Color(0xFF8B949E),
        textDisabled: const Color(0xFF626971),
        textInverse: const Color(0xFF0F1115), // Dark text on light accents
        accent: const Color(0xFFB3CDE3), // Matplotlib Pastel1 Blue
        accentHover: const Color(0xFFCBD5E8), // Matplotlib Pastel2 Light Periwinkle
        accentMuted: const Color(0xFF1C2028),
        success: const Color(0xFFCCEBC5), // Matplotlib Pastel1 Green
        warning: const Color(0xFFFED9A6), // Matplotlib Pastel1 Orange
        danger: const Color(0xFFFBB4AE), // Matplotlib Pastel1 Red
        info: const Color(0xFFDECBE4), // Matplotlib Pastel1 Purple
        tan: const Color(0xFFE5D8BD), // Matplotlib Pastel1 Tan
        yellow: const Color(0xFFFFFFCC), // Matplotlib Pastel1 Yellow
        icon: const Color(0xFFADB3BD),
        glassBackground: const Color(0xAA1A1D23),
        glassBorder: const Color(0x26B3CDE3), // Subtle accent edge for glass
        shadowSm: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        shadowMd: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
        shadowLg: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        shadowMd: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        shadowLg: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );
}
