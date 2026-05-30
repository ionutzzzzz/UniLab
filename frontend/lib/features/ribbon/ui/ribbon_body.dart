import 'package:flutter/material.dart';
import '../../../theme/ui_theme.dart';
import 'ribbon_group.dart';

class RibbonBody extends StatelessWidget {
  const RibbonBody({
    super.key,
    required this.groups,
    this.isCollapsed = false,
  });

  final List<RibbonGroup> groups;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) return const SizedBox.shrink();

    final ui = UiTheme.of(context);
    
    return Container(
      height: 92,
      color: ui.colors.panelHeader,
      padding: EdgeInsets.only(
        top: ui.spacing.xs,
        bottom: ui.spacing.xxs,
        left: ui.spacing.sm,
        right: ui.spacing.sm,
      ),
      child: Row(
        children: [
          for (int i = 0; i < groups.length; i++) ...[
            if (i > 0)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ui.spacing.sm),
                child: VerticalDivider(
                  color: ui.colors.divider,
                  width: ui.spacing.strokeHair,
                  thickness: ui.spacing.strokeHair,
                ),
              ),
            groups[i],
          ]
        ],
      ),
    );
  }
}
