import 'package:flutter/material.dart';
import '../theme/ui_theme.dart';

class UiTooltip extends StatelessWidget {
  const UiTooltip({
    super.key,
    required this.message,
    required this.child,
  });

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return Tooltip(
      message: message,
      textStyle: ui.typography.caption.copyWith(color: ui.colors.textInverse),
      decoration: BoxDecoration(
        color: ui.colors.overlay,
        borderRadius: ui.spacing.radiusSm,
        border: Border.all(color: ui.colors.border, width: 1.0),
      ),
      waitDuration: const Duration(milliseconds: 500),
      child: child,
    );
  }
}
