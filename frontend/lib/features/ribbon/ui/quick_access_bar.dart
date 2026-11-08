import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_icon_button.dart';
import '../../../widgets/ui_button.dart';
import '../../../widgets/ui_text.dart';
import '../../../screens/settings_screen.dart';
import '../../../providers/app_provider.dart';
import '../../../bridge/unilab_bridge.dart';
import '../../command_palette/ui/command_palette.dart';

class QuickAccessBar extends StatelessWidget {
  const QuickAccessBar({super.key});

  void _showAccountDialog(BuildContext context, AppProvider appProvider) {
    final ui = UiTheme.of(context);
    final controller = TextEditingController(text: appProvider.username);
    final sessionId = UniLabBridge.instance.sessionId ?? 'Not connected';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(LucideIcons.user, color: ui.colors.accent, size: 18),
            const SizedBox(width: 10),
            const UiText(text: 'User Profile & Kernel Session', variant: UiTextVariant.body, fontWeight: FontWeight.bold),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UiText(text: 'Session Username', variant: UiTextVariant.caption, color: ui.colors.textMuted),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                style: TextStyle(color: ui.colors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: ui.colors.canvas,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              UiText(text: 'Active Session ID', variant: UiTextVariant.caption, color: ui.colors.textMuted),
              const SizedBox(height: 4),
              UiText(text: sessionId, variant: UiTextVariant.codeBody, color: ui.colors.accent),
              const SizedBox(height: 12),
              UiText(text: 'Backend Status', variant: UiTextVariant.caption, color: ui.colors.textMuted),
              const SizedBox(height: 4),
              UiText(text: appProvider.backendStatus.name.toUpperCase(), variant: UiTextVariant.codeBody),
            ],
          ),
        ),
        actions: [
          UiButton(
            label: 'Restart Session',
            icon: LucideIcons.refreshCw,
            variant: UiButtonVariant.secondary,
            onPressed: () {
              Navigator.pop(dialogContext);
              appProvider.restartBackend();
            },
          ),
          UiButton(
            label: 'Save Profile',
            variant: UiButtonVariant.primary,
            onPressed: () async {
              await appProvider.setUsername(controller.text);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    );
  }

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
          tooltip: 'User & Kernel Session',
          onPressed: () => _showAccountDialog(context, appProvider),
        ),
        SizedBox(width: ui.spacing.sm),
      ],
    );
  }
}
