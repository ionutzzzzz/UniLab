import 'package:flutter/material.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';

class RibbonGroup extends StatelessWidget {
  const RibbonGroup({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children.map((child) => Padding(
              padding: EdgeInsets.symmetric(horizontal: ui.spacing.xs),
              child: child,
            )).toList(),
          ),
        ),
        SizedBox(height: ui.spacing.xs),
        UiText(
          text: title,
          variant: UiTextVariant.caption,
          color: ui.colors.textMuted,
        ),
      ],
    );
  }
}
