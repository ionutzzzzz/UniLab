import 'package:flutter/material.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_icon.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EditorBreadcrumbs extends StatelessWidget {
  const EditorBreadcrumbs({
    super.key,
    required this.pathSegments,
  });

  final List<String> pathSegments;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: ui.colors.canvas,
        border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.3))),
      ),
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
      child: Row(
        children: [
          Icon(LucideIcons.folderOpen, size: 12, color: ui.colors.textMuted),
          SizedBox(width: ui.spacing.sm),
          for (int i = 0; i < pathSegments.length; i++) ...[
            if (i > 0)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ui.spacing.xxs),
                child: UiIcon(LucideIcons.chevronRight, size: 10, color: ui.colors.textMuted.withValues(alpha: 0.5)),
              ),
            _BreadcrumbSegment(
              label: pathSegments[i],
              isLast: i == pathSegments.length - 1,
            ),
          ],
          const Spacer(),
          // Function Navigator
          _FunctionNavigator(),
        ],
      ),
    );
  }
}

class _BreadcrumbSegment extends StatefulWidget {
  const _BreadcrumbSegment({required this.label, required this.isLast});
  final String label;
  final bool isLast;

  @override
  State<_BreadcrumbSegment> createState() => _BreadcrumbSegmentState();
}

class _BreadcrumbSegmentState extends State<_BreadcrumbSegment> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _isHovered ? ui.colors.hover.withValues(alpha: 0.5) : Colors.transparent,
            borderRadius: ui.spacing.radiusSm,
          ),
          child: UiText(
            text: widget.label,
            variant: UiTextVariant.caption,
            fontSize: 10,
            fontWeight: widget.isLast ? FontWeight.w600 : FontWeight.w400,
            color: widget.isLast ? ui.colors.textSecondary : ui.colors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _FunctionNavigator extends StatefulWidget {
  @override
  State<_FunctionNavigator> createState() => _FunctionNavigatorState();
}

class _FunctionNavigatorState extends State<_FunctionNavigator> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Show function list
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _isHovered ? ui.colors.accent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: ui.spacing.radiusSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.functionSquare, size: 12, color: _isHovered ? ui.colors.accent : ui.colors.textMuted),
              const SizedBox(width: 6),
              UiText(
                text: 'step(t, a)',
                variant: UiTextVariant.caption,
                fontSize: 10,
                color: _isHovered ? ui.colors.accent : ui.colors.textMuted,
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, size: 14, color: _isHovered ? ui.colors.accent : ui.colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
