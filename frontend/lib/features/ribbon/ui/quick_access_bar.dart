import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_icon_button.dart';
import '../../../screens/settings_screen.dart';
import '../../../providers/app_provider.dart';
import '../../command_palette/ui/command_palette.dart';

class QuickAccessBar extends StatelessWidget {
  const QuickAccessBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UiIconButton(
          icon: LucideIcons.undo2,
          tooltip: 'Undo (⌘Z)',
          onPressed: () => appProvider.triggerEditorAction('editor.undo'),
        ),
        UiIconButton(
          icon: LucideIcons.redo2,
          tooltip: 'Redo (⌘Y)',
          onPressed: () => appProvider.triggerEditorAction('editor.redo'),
        ),
        SizedBox(width: ui.spacing.sm),
        Container(width: 1, height: 16, color: ui.colors.divider.withValues(alpha: 0.5)),
        SizedBox(width: ui.spacing.sm),
        UiIconButton(
          icon: LucideIcons.search,
          tooltip: 'Command Palette (⌘K)',
          onPressed: () => CommandPalette.show(context),
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
