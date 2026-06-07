import 'package:flutter/material.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
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
    
    // Filter out empty segments and handle root/empty paths
    final segments = pathSegments.where((s) => s.isNotEmpty && s != '/' && s != '\\').toList();
    if (segments.isEmpty) {
      if (pathSegments.isNotEmpty && (pathSegments.first == '/' || pathSegments.first == '\\')) {
         segments.add('Root');
      } else {
         segments.add('Untitled');
      }
    }

    return Container(
      height: 28, // Slightly taller for better readability
      decoration: BoxDecoration(
        color: ui.colors.panelHeader.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5))),
      ),
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.sm),
      child: Row(
        children: [
          SizedBox(width: ui.spacing.xs),
          Icon(LucideIcons.fileCode, size: 14, color: ui.colors.accent),
          SizedBox(width: ui.spacing.sm),
          
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < segments.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(LucideIcons.chevronRight, size: 12, color: ui.colors.textMuted.withValues(alpha: 0.4)),
                      ),
                    _BreadcrumbSegment(
                      label: segments[i],
                      isLast: i == segments.length - 1,
                      icon: i == segments.length - 1 ? null : LucideIcons.folder,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          Container(width: 1, height: 14, color: ui.colors.divider.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          
          // Function Navigator
          const _FunctionNavigator(),
        ],
      ),
    );
  }
}

class _BreadcrumbSegment extends StatefulWidget {
  const _BreadcrumbSegment({
    required this.label, 
    required this.isLast,
    this.icon,
  });
  
  final String label;
  final bool isLast;
  final IconData? icon;

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: _isHovered ? ui.colors.hover : Colors.transparent,
          borderRadius: ui.spacing.radiusSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 12, color: ui.colors.textMuted.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
            ],
            UiText(
              text: widget.label,
              variant: UiTextVariant.label,
              fontSize: 11,
              fontWeight: widget.isLast ? FontWeight.w600 : FontWeight.w400,
              color: widget.isLast ? ui.colors.textPrimary : ui.colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _FunctionNavigator extends StatefulWidget {
  const _FunctionNavigator();

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
          // In a real implementation, this would show a searchable symbol list
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _isHovered ? ui.colors.accent.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: ui.spacing.radiusSm,
            border: Border.all(
              color: _isHovered ? ui.colors.accent.withValues(alpha: 0.3) : Colors.transparent,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.functionSquare, 
                size: 13, 
                color: _isHovered ? ui.colors.accent : ui.colors.textMuted
              ),
              const SizedBox(width: 6),
              UiText(
                text: 'Main Scope',
                variant: UiTextVariant.label,
                fontSize: 11,
                color: _isHovered ? ui.colors.accent : ui.colors.textMuted,
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.chevronDown, 
                size: 12, 
                color: _isHovered ? ui.colors.accent : ui.colors.textMuted.withValues(alpha: 0.5)
              ),
            ],
          ),
        ),
      ),
    );
  }
}