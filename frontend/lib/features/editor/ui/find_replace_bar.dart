import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_icon_button.dart';
import '../../../widgets/ui_input_field.dart';
import '../../../widgets/ui_text.dart';

class FindReplaceBar extends StatelessWidget {
  const FindReplaceBar({
    super.key,
    required this.onClose,
    this.isReplaceMode = false,
  });

  final VoidCallback onClose;
  final bool isReplaceMode;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.md, vertical: ui.spacing.sm),
      decoration: BoxDecoration(
        color: ui.colors.panel,
        border: Border(bottom: BorderSide(color: ui.colors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: UiInputField(
                        hintText: 'Find',
                        prefixIcon: LucideIcons.search,
                      ),
                    ),
                    SizedBox(width: ui.spacing.sm),
                    UiText(text: '0 of 0', variant: UiTextVariant.caption, color: ui.colors.textMuted),
                    SizedBox(width: ui.spacing.md),
                    UiIconButton(icon: LucideIcons.arrowUp, tooltip: 'Previous Match'),
                    SizedBox(width: ui.spacing.xs),
                    UiIconButton(icon: LucideIcons.arrowDown, tooltip: 'Next Match'),
                  ],
                ),
                if (isReplaceMode) ...[
                  SizedBox(height: ui.spacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: UiInputField(
                          hintText: 'Replace',
                          prefixIcon: LucideIcons.replace,
                        ),
                      ),
                      SizedBox(width: ui.spacing.sm),
                      UiIconButton(icon: LucideIcons.replace, tooltip: 'Replace'),
                      SizedBox(width: ui.spacing.xs),
                      UiIconButton(icon: LucideIcons.replaceAll, tooltip: 'Replace All'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: ui.spacing.md),
          UiIconButton(
            icon: LucideIcons.x,
            tooltip: 'Close',
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
