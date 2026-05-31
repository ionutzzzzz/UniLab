import 'package:flutter/material.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_icon.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EditorTabModel {
  final String id;
  final String title;
  final bool isDirty;
  final bool isActive;
  final IconData? icon;

  const EditorTabModel({
    required this.id,
    required this.title,
    this.isDirty = false,
    this.isActive = false,
    this.icon,
  });
}

class EditorTabBar extends StatelessWidget {
  const EditorTabBar({
    super.key,
    required this.tabs,
    required this.onTabTap,
    required this.onTabClose,
    this.onNewTab,
  });

  final List<EditorTabModel> tabs;
  final ValueChanged<String> onTabTap;
  final ValueChanged<String> onTabClose;
  final VoidCallback? onNewTab;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: ui.colors.panelHeader,
        border: Border(
          bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                return _EditorTab(
                  tab: tab,
                  onTap: () => onTabTap(tab.id),
                  onClose: () => onTabClose(tab.id),
                );
              },
            ),
          ),
          if (onNewTab != null)
            IconButton(
              icon: UiIcon(LucideIcons.plus, size: 14),
              onPressed: onNewTab,
              splashRadius: 14,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
        ],
      ),
    );
  }
}

class _EditorTab extends StatefulWidget {
  const _EditorTab({
    required this.tab,
    required this.onTap,
    required this.onClose,
  });

  final EditorTabModel tab;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  State<_EditorTab> createState() => _EditorTabState();
}

class _EditorTabState extends State<_EditorTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          height: 30,
          padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
          decoration: BoxDecoration(
            color: widget.tab.isActive ? ui.colors.canvas : (_isHovered ? ui.colors.hover.withValues(alpha: 0.5) : Colors.transparent),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6.0)),
            // Removed non-uniform border to fix exception. 
            // We use the parent's bottom border and right margin for separation.
          ),
          margin: const EdgeInsets.only(right: 1),
          child: Column(
            children: [
              // Top Accent Line
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: widget.tab.isActive ? 40 : 0,
                decoration: BoxDecoration(
                  color: ui.colors.accent,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.tab.isDirty)
                      Container(
                        width: 6,
                        height: 6,
                        margin: EdgeInsets.only(right: ui.spacing.xs),
                        decoration: BoxDecoration(
                          color: ui.colors.accent,
                          shape: BoxShape.circle,
                        ),
                      )
                    else if (widget.tab.icon != null) ...[
                      UiIcon(
                        widget.tab.icon!, 
                        size: 14, 
                        color: widget.tab.isActive ? ui.colors.accent : ui.colors.icon.withValues(alpha: 0.7)
                      ),
                      SizedBox(width: ui.spacing.xs),
                    ],
                    UiText(
                      text: widget.tab.title,
                      variant: UiTextVariant.label,
                      fontWeight: widget.tab.isActive ? FontWeight.w600 : FontWeight.w500,
                      color: widget.tab.isActive ? ui.colors.textPrimary : ui.colors.textMuted,
                    ),
                    SizedBox(width: ui.spacing.sm),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _isHovered || widget.tab.isActive ? 1.0 : 0.0,
                      child: GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: ui.spacing.radiusSm,
                            color: _isHovered ? ui.colors.hover : Colors.transparent,
                          ),
                          child: UiIcon(LucideIcons.x, size: 10, color: ui.colors.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}