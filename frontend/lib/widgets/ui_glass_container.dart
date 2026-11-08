import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/ui_theme.dart';

class UiGlassContainer extends StatelessWidget {
  const UiGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
    this.margin,
    this.blur = 10.0,
    this.opacity = 0.6,
  });

  final Widget child;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final effectiveRadius = borderRadius ?? ui.spacing.radiusMd;
    final settingsProvider = Provider.of<SettingsProvider?>(context);
    final glassEnabled = settingsProvider?.settings.glassmorphismEnabled ?? true;
    final effectiveBlur = glassEnabled ? blur : 0.0;
    final effectiveOpacity = glassEnabled ? opacity : 0.96;

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: ui.colors.glassBackground.withValues(alpha: effectiveOpacity),
        borderRadius: effectiveRadius,
        border: Border.all(
          color: ui.colors.glassBorder,
          width: ui.spacing.strokeHair,
        ),
      ),
      child: child,
    );

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: ui.colors.shadowMd,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: effectiveBlur > 0
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
                child: content,
              )
            : content,
      ),
    );
  }
}
