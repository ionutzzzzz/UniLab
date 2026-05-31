import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';

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
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.md, vertical: ui.spacing.xs),
      decoration: BoxDecoration(
        color: ui.colors.panelHeader,
        border: Border.all(color: ui.colors.divider.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ui.colors.canvas.withValues(alpha: 0.5),
          borderRadius: ui.spacing.radiusMd,
          border: Border.all(color: ui.colors.divider.withValues(alpha: 0.5)),
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
            
            Color activeColor;
            switch (segment) {
              case 'Variables': activeColor = ui.colors.accent; break;
              case 'Inspector': activeColor = ui.colors.tan; break;
              case 'Plots': activeColor = ui.colors.success; break;
              case 'Help': activeColor = ui.colors.info; break;
              default: activeColor = ui.colors.accent;
            }
            
            return Expanded(
              child: GestureDetector(
                onTap: () => onSegmentChanged(segment),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? activeColor.withValues(alpha: 0.9) : Colors.transparent,
                      borderRadius: ui.spacing.radiusMd,
                      boxShadow: isActive ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ] : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 14, color: isActive ? Colors.black87 : ui.colors.textMuted),
                        if (showLabels) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: UiText(
                              text: segment,
                              variant: UiTextVariant.label,
                              fontSize: 11,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive ? Colors.black87 : ui.colors.textMuted,
                              letterSpacing: 0.1,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
