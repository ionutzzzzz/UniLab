import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_icon_button.dart';

class QuickAccessBar extends StatelessWidget {
  const QuickAccessBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UiIconButton(
          icon: LucideIcons.search,
          tooltip: 'Command Palette (⌘K)',
          onPressed: () {},
        ),
        SizedBox(width: ui.spacing.xs),
        UiIconButton(
          icon: LucideIcons.settings,
          tooltip: 'Settings',
          onPressed: () {},
        ),
        SizedBox(width: ui.spacing.xs),
        UiIconButton(
          icon: LucideIcons.user,
          tooltip: 'Account',
          onPressed: () {},
        ),
        SizedBox(width: ui.spacing.sm),
      ],
    );
  }
}
