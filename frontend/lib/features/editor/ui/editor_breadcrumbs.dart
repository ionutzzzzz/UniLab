import 'package:flutter/material.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_icon.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EditorBreadcrumbs extends StatelessWidget {
  const EditorBreadcrumbs({
    super.key,
    required this.pathSegments,
  });

  final List<String> pathSegments;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return Container(
      height: 22,
      color: ui.colors.canvas,
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
      child: Row(
        children: [
          for (int i = 0; i < pathSegments.length; i++) ...[
            if (i > 0)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ui.spacing.xs),
                child: UiIcon(LucideIcons.chevronRight, size: 12, color: ui.colors.textMuted),
              ),
            UiText(
              text: pathSegments[i],
              variant: UiTextVariant.caption,
              color: i == pathSegments.length - 1 ? ui.colors.textSecondary : ui.colors.textMuted,
            ),
          ]
        ],
      ),
    );
  }
}
