import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';

import '../../../widgets/ui_tooltip.dart';

class WorkspaceSegmented extends StatelessWidget {
  const WorkspaceSegmented({
    super.key,
    required this.segments,
    required this.activeSegment,
    required this.onSegmentChanged,
    this.showLabels = true,
  });

  final List<String> segments;
  final String activeSegment;
  final ValueChanged<String> onSegmentChanged;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return Container(
      height: 36, // Slightly slimmer for secondary nav
      decoration: BoxDecoration(
        color: ui.colors.panelHeader.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.3), width: ui.spacing.strokeHair),
        ),
      ),
      child: Row(
        children: segments.map((segment) {
          final isActive = segment == activeSegment;
          IconData icon;
          switch (segment) {
            case 'Variables': icon = LucideIcons.variable; break;
            case 'Inspector': icon = LucideIcons.info; break;
            case 'Plots': icon = LucideIcons.lineChart; break;
            case 'Help': icon = LucideIcons.helpCircle; break;
            default: icon = LucideIcons.box;
          }
          
          return Expanded(
            child: _WorkspaceTab(
              label: segment,
              icon: icon,
              isActive: isActive,
              showLabel: showLabels,
              onTap: () => onSegmentChanged(segment),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WorkspaceTab extends StatefulWidget {
  const _WorkspaceTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.showLabel,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  State<_WorkspaceTab> createState() => _WorkspaceTabState();
}

class _WorkspaceTabState extends State<_WorkspaceTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final isActive = widget.isActive;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.xs),
      decoration: BoxDecoration(
        color: isActive ? ui.colors.canvas : (_isHovered ? ui.colors.hover.withValues(alpha: 0.5) : Colors.transparent),
      ),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 24) {
                  return const SizedBox.shrink();
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon, 
                      size: 14, 
                      color: isActive ? ui.colors.accent : (_isHovered ? ui.colors.textPrimary : ui.colors.textMuted),
                    ),
                    if (widget.showLabel) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: UiText(
                          text: widget.label,
                          variant: UiTextVariant.label,
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive ? ui.colors.textPrimary : (_isHovered ? ui.colors.textPrimary : ui.colors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                );
              }
            ),
          ),
          // Subtle active indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: isActive ? (widget.showLabel ? 40 : 20) : 0,
            decoration: BoxDecoration(
              color: ui.colors.accent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
            ),
          ),
        ],
      ),
    );

    return UiTooltip(
      message: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            hoverColor: Colors.transparent,
            splashColor: ui.colors.accent.withValues(alpha: 0.1),
            highlightColor: Colors.transparent,
            child: content,
          ),
        ),
      ),
    );
  }
}
