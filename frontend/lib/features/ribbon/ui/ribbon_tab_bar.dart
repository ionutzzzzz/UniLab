import 'package:flutter/material.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';

class RibbonTabBar extends StatelessWidget {
  const RibbonTabBar({
    super.key,
    required this.tabs,
    required this.activeTab,
    required this.onTabTap,
    required this.onDoubleTap,
  });

  final List<String> tabs;
  final String activeTab;
  final ValueChanged<String> onTabTap;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return Container(
      height: 32,
      color: ui.colors.ribbonTabs,
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.sm),
      child: Row(
        children: tabs.map((tab) {
          final isActive = tab == activeTab;
          return GestureDetector(
            onTap: () => onTabTap(tab),
            onDoubleTap: onDoubleTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
              alignment: Alignment.center,
              margin: EdgeInsets.only(top: ui.spacing.xs),
              decoration: BoxDecoration(
                color: isActive ? ui.colors.panelHeader : Colors.transparent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                border: isActive ? Border(
                  top: BorderSide(color: ui.colors.divider),
                  left: BorderSide(color: ui.colors.divider),
                  right: BorderSide(color: ui.colors.divider),
                ) : null,
              ),
              child: UiText(
                text: tab,
                variant: UiTextVariant.body,
                color: isActive ? ui.colors.textPrimary : ui.colors.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
