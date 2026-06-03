import 'package:flutter/material.dart';
import '../theme/ui_theme.dart';

class UiIcon extends StatelessWidget {
  const UiIcon(
    this.icon, {
    super.key,
    this.size = 16,
    this.color,
  });

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return Icon(
      icon,
      size: size,
      color: color ?? ui.colors.icon,
    );
  }
}
