import 'package:flutter/material.dart';
import '../theme/ui_theme.dart';

enum UiBadgeVariant { info, success, warning, danger, neutral }

class UiBadge extends StatelessWidget {
  const UiBadge({
    super.key,
    required this.label,
    this.variant = UiBadgeVariant.neutral,
  });

  final String label;
  final UiBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    Color bgColor;
    Color fgColor;

    switch (variant) {
      case UiBadgeVariant.info:
        bgColor = ui.colors.info;
        fgColor = ui.colors.textInverse;
        break;
      case UiBadgeVariant.success:
        bgColor = ui.colors.success;
        fgColor = ui.colors.textInverse;
        break;
      case UiBadgeVariant.warning:
        bgColor = ui.colors.warning;
        fgColor = ui.colors.textInverse;
        break;
      case UiBadgeVariant.danger:
        bgColor = ui.colors.danger;
        fgColor = ui.colors.textInverse;
        break;
      case UiBadgeVariant.neutral:
        bgColor = ui.colors.panelHeader;
        fgColor = ui.colors.textSecondary;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10), // Pill shape
      ),
      child: Text(
        label,
        style: ui.typography.caption.copyWith(color: fgColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
