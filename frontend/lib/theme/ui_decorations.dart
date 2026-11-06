import 'dart:ui';
import 'package:flutter/material.dart';
import 'ui_theme.dart';

class ShellDecorations {
  /// 1. Panel Decoration (Beveled Inner Top-Border & Sharp Radii)
  static BoxDecoration panelDecoration(UiTheme theme) {
    return BoxDecoration(
      color: theme.colors.panel,
      borderRadius: BorderRadius.circular(6.0),
      border: Border.all(
        color: theme.colors.border,
        width: 1.0,
      ),
      boxShadow: theme.colors.shadowMd,
    );
  }

  /// 2. Glassmorphism Transient Menu (Command Palette / Context Menu)
  static Widget buildGlassMenu({required UiTheme theme, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6.0), // Slightly softer for floaters
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colors.glassBackground, // Semi-transparent
            border: Border.all(
              color: theme.colors.glassBorder, // Subtle accent edge
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: child,
        ),
      ),
    );
  }
}
