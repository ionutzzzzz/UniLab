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
      width: double.infinity,
      height: 92,
      color: ui.colors.panelHeader,
      padding: EdgeInsets.only(
        top: ui.spacing.xs,
        bottom: ui.spacing.xxs,
        left: ui.spacing.sm,
        right: ui.spacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: groups,
        ),
      ),
    );
  }
}
