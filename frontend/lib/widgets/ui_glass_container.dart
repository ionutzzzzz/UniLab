import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/ui_theme.dart';

class UiGlassContainer extends StatelessWidget {
  const UiGlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
    this.blur = 10.0,
    this.opacity = 0.6,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final effectiveRadius = borderRadius ?? ui.spacing.radiusMd;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: ui.colors.shadowMd,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: ui.colors.glassBackground.withOpacity(opacity),
              borderRadius: effectiveRadius,
              border: Border.all(
                color: ui.colors.glassBorder,
                width: ui.spacing.strokeHair,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
