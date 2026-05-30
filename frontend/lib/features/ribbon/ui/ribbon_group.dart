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

    return Container(
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.sm),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: ui.colors.divider.withOpacity(0.5),
            width: ui.spacing.strokeHair,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children
                  .map((child) => Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: ui.spacing.xxs),
                        child: child,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 6),
          UiText(
            text: title.toUpperCase(),
            variant: UiTextVariant.label,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: ui.colors.textMuted.withOpacity(0.7),
            letterSpacing: 0.8,
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
