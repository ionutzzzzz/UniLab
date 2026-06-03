import 'package:flutter/material.dart';
import '../theme/ui_theme.dart';

class UiToggle extends StatelessWidget {
  const UiToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: ui.colors.accent,
      activeTrackColor: ui.colors.accentMuted,
      inactiveThumbColor: ui.colors.textMuted,
      inactiveTrackColor: ui.colors.divider,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
