import 'package:flutter/material.dart';
import '../theme/ui_theme.dart';

class UiDivider extends StatelessWidget {
  const UiDivider({
    super.key,
    this.horizontal = true,
  });

  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    if (horizontal) {
      return Container(
        height: ui.spacing.strokeHair,
        color: ui.colors.divider,
      );
    } else {
      return Container(
        width: ui.spacing.strokeHair,
        color: ui.colors.divider,
      );
    }
  }
}
