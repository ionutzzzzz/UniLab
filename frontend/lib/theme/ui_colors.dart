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
    required this.icon,
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

  final Color icon;

  factory UiColors.dark() => const UiColors(
        canvas: Color(0xFF1E2127),
        panel: Color(0xFF252A31),
        panelHeader: Color(0xFF2B3038),
        ribbonTabs: Color(0xFF242831),
        overlay: Color(0xFF2B3038),
        hover: Color(0xFF2F3742),
        selected: Color(0xFF173654),
        selectedMuted: Color(0xFF22262D),
        divider: Color(0xFF3A414C),
        border: Color(0xFF4A5361),
        textPrimary: Color(0xFFE5E7EB),
        textSecondary: Color(0xFFB5BDC9),
        textMuted: Color(0xFF96A0AD),
        textDisabled: Color(0xFF6B7280),
        textInverse: Color(0xFFFFFFFF),
        accent: Color(0xFF4AA3FF),
        accentHover: Color(0xFF6BB1FF),
        accentMuted: Color(0xFF173654),
        success: Color(0xFF23D18B),
        warning: Color(0xFFE5E510),
        danger: Color(0xFFF14C4C),
        info: Color(0xFF29B8DB),
        icon: Color(0xFFB5BDC9),
      );
      
  factory UiColors.light() => const UiColors(
        canvas: Color(0xFFFFFFFF),
        panel: Color(0xFFF3F3F3),
        panelHeader: Color(0xFFE0E0E0),
        ribbonTabs: Color(0xFFE0E0E0),
        overlay: Color(0xFFFFFFFF),
        hover: Color(0xFFE5E5E5),
        selected: Color(0xFFD3E3FD),
        selectedMuted: Color(0xFFE8ECEF),
        divider: Color(0xFFD0D0D0),
        border: Color(0xFFC0C0C0),
        textPrimary: Color(0xFF333333),
        textSecondary: Color(0xFF666666),
        textMuted: Color(0xFF858585),
        textDisabled: Color(0xFFA0A0A0),
        textInverse: Color(0xFFFFFFFF),
        accent: Color(0xFF0078D4),
        accentHover: Color(0xFF006CBE),
        accentMuted: Color(0xFFE0EFFF),
        success: Color(0xFF107C10),
        warning: Color(0xFF797700),
        danger: Color(0xFFD13438),
        info: Color(0xFF005A9E),
        icon: Color(0xFF666666),
      );
}
