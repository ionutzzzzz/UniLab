import 'package:flutter/material.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';

class WorkspaceSegmented extends StatelessWidget {
  const WorkspaceSegmented({
    super.key,
    required this.segments,
    required this.activeSegment,
    required this.onSegmentChanged,
  });

  final List<String> segments;
  final String activeSegment;
  final ValueChanged<String> onSegmentChanged;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return Container(
      height: 34,
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.sm, vertical: ui.spacing.xs),
      decoration: BoxDecoration(
        color: ui.colors.panelHeader,
        border: Border(bottom: BorderSide(color: ui.colors.divider)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ui.colors.canvas,
          borderRadius: ui.spacing.radiusSm,
          border: Border.all(color: ui.colors.border),
        ),
        child: Row(
          children: segments.map((segment) {
            final isActive = segment == activeSegment;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSegmentChanged(segment),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? ui.colors.selected : Colors.transparent,
                    borderRadius: ui.spacing.radiusSm,
                  ),
                  child: UiText(
                    text: segment,
                    variant: UiTextVariant.label,
                    color: isActive ? ui.colors.textInverse : ui.colors.textSecondary,
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
