import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/editor_models.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_icon_button.dart';
import '../../../widgets/plot_viewer/plot_widget.dart';

class FigureView extends StatelessWidget {
  const FigureView({
    super.key,
    required this.plotData,
    required this.onBack,
  });

  final PlotData plotData;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);

    return Column(
      children: [
        // Figure Toolbar
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
              Expanded(
                child: UiText(
                  text: plotData.title,
                  variant: UiTextVariant.label,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
            child: _buildPlotContent(context, ui),
          ),
        ),
      ],
    );
  }

  Widget _buildPlotContent(BuildContext context, UiTheme ui) {
    // Case 1: Base64 PNG image
    if (plotData.imageDataUri != null) {
      return InteractiveViewer(
        child: Image.memory(
          base64Decode(plotData.imageDataUri!.split(',').last),
          fit: BoxFit.contain,
          errorBuilder: (_, e, __) => Center(
            child: UiText(text: 'Image error: $e', color: ui.colors.danger),
          ),
        ),
      );
    }

    // Case 2: Structured line/scatter data
    if (plotData.xData.isNotEmpty &&
        (plotData.type == 'line' || plotData.type == 'scatter' || plotData.type == 'plot')) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: PlotWidget(
          title: plotData.title,
          data: List.generate(
            plotData.xData.length,
            (i) => {'x': plotData.xData[i], 'y': plotData.yData[i]},
          ),
        ),
      );
    }

    // Case 3: 3D plots (not yet supported)
    if (plotData.type == 'surf' || plotData.type == 'mesh') {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.box, size: 48, color: ui.colors.textDisabled),
            const SizedBox(height: 16),
            UiText(
              text: '3D surface rendering not yet supported.\nUse the PNG output.',
              variant: UiTextVariant.body,
              textAlign: TextAlign.center,
              color: ui.colors.textMuted,
            ),
          ],
        ),
      );
    }

    // Fallback
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.lineChart, size: 64, color: ui.colors.accent.withValues(alpha: 0.4)),
          const SizedBox(height: 24),
          UiText(
            text: plotData.title,
            variant: UiTextVariant.body,
            color: ui.colors.textMuted,
          ),
        ],
      ),
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
