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

  factory UiSpacing.standard() => const UiSpacing(
        xxs: 2.0,
        xs: 4.0,
        sm: 8.0,
        md: 12.0,
        lg: 16.0,
        xl: 24.0,
        radiusNone: BorderRadius.zero,
        radiusSm: BorderRadius.all(Radius.circular(6.0)),
        radiusMd: BorderRadius.all(Radius.circular(8.0)),
        radiusLg: BorderRadius.all(Radius.circular(10.0)),
        strokeHair: 1.0,
        focusRing: 2.0,
      );


}
