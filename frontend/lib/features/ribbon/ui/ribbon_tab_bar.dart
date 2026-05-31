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
      height: 34,
      decoration: BoxDecoration(
        color: ui.colors.ribbonTabs,
        border: Border(
          bottom: BorderSide(color: ui.colors.divider),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.sm),
      child: Row(
        children: tabs.map((tab) {
          final isActive = tab == activeTab;
          return _RibbonTab(
            title: tab,
            isActive: isActive,
            onTap: () => onTabTap(tab),
            onDoubleTap: onDoubleTap,
          );
        }).toList(),
      ),
    );
  }
}

class _RibbonTab extends StatefulWidget {
  const _RibbonTab({
    required this.title,
    required this.isActive,
    required this.onTap,
    required this.onDoubleTap,
  });

  final String title;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  @override
  State<_RibbonTab> createState() => _RibbonTabState();
}

class _RibbonTabState extends State<_RibbonTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
          alignment: Alignment.center,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: widget.isActive
                ? ui.colors.panelHeader
                : (_isHovered
                    ? ui.colors.accent
                    : Colors.transparent),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            border: Border.all(
              color: (widget.isActive || _isHovered) ? ui.colors.divider : Colors.transparent,
              width: 1.0,
            ),
          ),
          child: UiText(
            text: widget.title,
            variant: UiTextVariant.label,
            fontWeight: (widget.isActive || _isHovered) ? FontWeight.bold : FontWeight.normal,
            color: _isHovered
                ? ui.colors.textInverse
                : (widget.isActive ? ui.colors.textPrimary : ui.colors.textSecondary),
          ),
        ),
      ),
    );
  }
}
