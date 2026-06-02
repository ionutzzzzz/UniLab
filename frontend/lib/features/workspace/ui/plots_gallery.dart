import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/editor_models.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_icon_button.dart';
import '../../../widgets/plot_viewer/plot_widget.dart';
import '../../../providers/riverpod_providers.dart';
import '../../../providers/app_provider.dart';
import 'figure_view.dart';

class PlotsGallery extends ConsumerStatefulWidget {
  const PlotsGallery({super.key});

  @override
  ConsumerState<PlotsGallery> createState() => _PlotsGalleryState();
}

class _PlotsGalleryState extends ConsumerState<PlotsGallery> {
  String? _selectedPlotId;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final plots = ref.watch(plotGalleryProvider);

    if (_selectedPlotId != null) {
      final plot = plots.firstWhere(
        (p) => p.id == _selectedPlotId,
        orElse: () => plots.isNotEmpty ? plots.first : PlotData(title: '', type: '', xData: [], yData: []),
      );
      return FigureView(
        plotData: plot,
        onBack: () => setState(() => _selectedPlotId = null),
      );
    }

    if (plots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ui.colors.panelHeader.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.lineChart, size: 40, color: ui.colors.textDisabled),
              ),
              const SizedBox(height: 20),
              UiText(
                text: 'No plots generated',
                variant: UiTextVariant.body,
                fontWeight: FontWeight.bold,
                color: ui.colors.textSecondary,
              ),
              const SizedBox(height: 8),
              UiText(
                text: 'Run simulation scripts that generate visual outputs to see them here.',
                variant: UiTextVariant.label,
                color: ui.colors.textMuted,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Toolbar for Plots
        Container(
          padding: EdgeInsets.symmetric(horizontal: ui.spacing.md, vertical: ui.spacing.xs),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              Expanded(
                child: UiText(
                  text: 'Plot History',
                  variant: UiTextVariant.label,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              UiIconButton(icon: LucideIcons.layoutGrid, tooltip: 'Grid View', size: 24, iconSize: 14),
              SizedBox(width: ui.spacing.xs),
              UiIconButton(
                icon: LucideIcons.trash2, 
                tooltip: 'Clear All', 
                size: 24, 
                iconSize: 14,
                onPressed: () => p.Provider.of<AppProvider>(context, listen: false).clearPlots(),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(ui.spacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: plots.length,
            itemBuilder: (context, index) {
              return _PlotThumbnail(
                plotData: plots[index],
                onTap: () => setState(() => _selectedPlotId = plots[index].id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlotThumbnail extends StatefulWidget {
  const _PlotThumbnail({required this.plotData, required this.onTap});
  final PlotData plotData;
  final VoidCallback onTap;

  @override
  State<_PlotThumbnail> createState() => _PlotThumbnailState();
}

class _PlotThumbnailState extends State<_PlotThumbnail> {
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
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: ui.colors.canvas,
            borderRadius: ui.spacing.radiusMd,
            border: Border.all(
              color: _isHovered ? ui.colors.accent.withValues(alpha: 0.5) : ui.colors.divider.withValues(alpha: 0.5),
              width: 1.0,
            ),
            boxShadow: _isHovered ? ui.colors.shadowMd : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Plot Content Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: ui.colors.panelHeader.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(ui.spacing.radiusMd.topLeft.x)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Render actual plot data
                      if (widget.plotData.imageDataUri != null)
                        Image.memory(
                          base64Decode(widget.plotData.imageDataUri!.split(',').last),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            LucideIcons.lineChart,
                            size: 32,
                            color: ui.colors.textDisabled.withValues(alpha: 0.3),
                          ),
                        )
                      else if (widget.plotData.xData.isNotEmpty)
                        PlotWidget(
                          title: '',
                          data: List.generate(
                            widget.plotData.xData.length,
                            (i) => {
                              'x': widget.plotData.xData[i],
                              'y': widget.plotData.yData[i],
                            },
                          ),
                        )
                      else
                        Icon(
                          LucideIcons.lineChart,
                          size: 32,
                          color: ui.colors.textDisabled.withValues(alpha: 0.3),
                        ),
                      if (_isHovered)
                        Container(
                          decoration: BoxDecoration(
                            color: ui.colors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(ui.spacing.radiusMd.topLeft.x),
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ui.colors.accent,
                                shape: BoxShape.circle,
                                boxShadow: ui.colors.shadowSm,
                              ),
                              child: Icon(
                                LucideIcons.maximize2,
                                size: 16,
                                color: ui.colors.textInverse,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Caption
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _isHovered ? ui.colors.accent.withValues(alpha: 0.05) : Colors.transparent,
                  border: Border(top: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5))),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(ui.spacing.radiusMd.bottomLeft.x),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiText(
                      text: widget.plotData.title,
                      variant: UiTextVariant.label,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _isHovered ? ui.colors.accent : ui.colors.textPrimary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    UiText(
                      text: 'Generated ${_formatTime(widget.plotData.createdAt)}',
                      variant: UiTextVariant.label,
                      fontSize: 9,
                      color: ui.colors.textMuted,
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
