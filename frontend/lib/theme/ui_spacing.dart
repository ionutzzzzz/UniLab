import 'package:flutter/material.dart';

@immutable
class UiSpacing {
  const UiSpacing({
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.radiusNone,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.strokeHair,
    required this.focusRing,
  });

  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  final BorderRadius radiusNone;
  final BorderRadius radiusSm;
  final BorderRadius radiusMd;
  final BorderRadius radiusLg;

  final double strokeHair;
  final double focusRing;

  factory UiSpacing.standard({double scale = 1.0}) => UiSpacing(
        xxs: 2.0 * scale,
        xs: 4.0 * scale,
        sm: 8.0 * scale,
        md: 12.0 * scale,
        lg: 16.0 * scale,
        xl: 24.0 * scale,
        radiusNone: BorderRadius.zero,
        radiusSm: BorderRadius.all(Radius.circular(6.0 * scale)),
        radiusMd: BorderRadius.all(Radius.circular(8.0 * scale)),
        radiusLg: BorderRadius.all(Radius.circular(10.0 * scale)),
        strokeHair: 1.0,
        focusRing: 2.0 * scale,
      );
}