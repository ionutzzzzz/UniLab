import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_icon_button.dart';

class FigureView extends StatelessWidget {
  const FigureView({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return Column(
      children: [
        // Figure Toolbar (Inspired by matlab.html)
        Container(
          padding: EdgeInsets.symmetric(horizontal: ui.spacing.sm, vertical: 4),
          decoration: BoxDecoration(
            color: ui.colors.panelHeader,
            border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              UiIconButton(
                icon: LucideIcons.arrowLeft,
                tooltip: 'Back to Gallery',
                size: 28,
                iconSize: 16,
                onPressed: onBack,
              ),
              const SizedBox(width: 8),
              UiText(
                text: title,
                variant: UiTextVariant.label,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              const Spacer(),
              _FigureChip(icon: LucideIcons.mousePointer2, label: 'Select', color: ui.colors.accent),
              const SizedBox(width: 4),
              _FigureChip(icon: LucideIcons.zoomIn, label: 'Zoom', color: ui.colors.success),
              const SizedBox(width: 4),
              _FigureChip(icon: LucideIcons.hand, label: 'Pan', color: ui.colors.yellow),
              const SizedBox(width: 8),
              Container(width: 1, height: 20, color: ui.colors.divider),
              const SizedBox(width: 8),
              UiIconButton(icon: LucideIcons.save, tooltip: 'Export Figure', size: 28, iconSize: 16),
            ],
          ),
        ),
        
        // Secondary Toolbar (Format)
        Container(
          height: 32,
          padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
          decoration: BoxDecoration(
            color: ui.colors.panel.withValues(alpha: 0.5),
            border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.2))),
          ),
          child: Row(
            children: [
              _ToolbarAction(icon: LucideIcons.grid3X3, label: 'Grid'),
              const SizedBox(width: 16),
              _ToolbarAction(icon: LucideIcons.type, label: 'Labels'),
              const SizedBox(width: 16),
              _ToolbarAction(icon: LucideIcons.list, label: 'Legend'),
            ],
          ),
        ),

        // Figure Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: ui.spacing.radiusLg,
              border: Border.all(color: ui.colors.divider.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.lineChart, size: 64, color: ui.colors.accent.withValues(alpha: 0.4)),
                  const SizedBox(height: 24),
                  UiText(
                    text: 'High-Fidelity Rendering: $title',
                    variant: UiTextVariant.body,
                    color: ui.colors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FigureChip extends StatelessWidget {
  const _FigureChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          UiText(text: label, variant: UiTextVariant.label, fontSize: 9, color: color, fontWeight: FontWeight.bold),
        ],
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: ui.colors.textMuted),
        const SizedBox(width: 6),
        UiText(text: label, variant: UiTextVariant.label, fontSize: 10, color: ui.colors.textMuted),
      ],
    );
  }
}
