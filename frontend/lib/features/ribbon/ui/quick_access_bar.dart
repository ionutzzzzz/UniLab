import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_icon_button.dart';
import '../../../screens/settings_screen.dart';

class QuickAccessBar extends StatelessWidget {
  const QuickAccessBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UiIconButton(
          icon: LucideIcons.undo2,
          tooltip: 'Undo (⌘Z)',
          onPressed: () {},
        ),
        UiIconButton(
          icon: LucideIcons.redo2,
          tooltip: 'Redo (⌘Y)',
          onPressed: () {},
        ),
        SizedBox(width: ui.spacing.sm),
        Container(width: 1, height: 16, color: ui.colors.divider.withValues(alpha: 0.5)),
        SizedBox(width: ui.spacing.sm),
        UiIconButton(
          icon: LucideIcons.search,
          tooltip: 'Command Palette (⌘K)',
          onPressed: () {},
        ),
        UiIconButton(
          icon: LucideIcons.settings,
          tooltip: 'Settings',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
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
