import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_icon_button.dart';
import 'figure_view.dart';

class PlotsGallery extends ConsumerStatefulWidget {
  const PlotsGallery({super.key});

  @override
  ConsumerState<PlotsGallery> createState() => _PlotsGalleryState();
}

class _PlotsGalleryState extends ConsumerState<PlotsGallery> {
  String? _selectedPlot;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    // Mock plots for UI development
    final mockPlots = [
      'Quantum Mechanics: Wave Function',
      'Fluid Dynamics: Streamlines',
      'Structural Analysis: Stress Distribution',
      'Signal Processing: FFT Analysis',
    ];

    if (_selectedPlot != null) {
      return FigureView(
        title: _selectedPlot!,
        onBack: () => setState(() => _selectedPlot = null),
      );
    }

    if (mockPlots.isEmpty) {
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
              UiText(text: 'Plot History', variant: UiTextVariant.label, fontWeight: FontWeight.bold),
              const Spacer(),
              UiIconButton(icon: LucideIcons.layoutGrid, tooltip: 'Grid View', size: 24, iconSize: 14),
              SizedBox(width: ui.spacing.xs),
              UiIconButton(icon: LucideIcons.trash2, tooltip: 'Clear All', size: 24, iconSize: 14),
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
            itemCount: mockPlots.length,
            itemBuilder: (context, index) {
              return _PlotThumbnail(
                title: mockPlots[index],
                onTap: () => setState(() => _selectedPlot = mockPlots[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlotThumbnail extends StatefulWidget {
  const _PlotThumbnail({required this.title, required this.onTap});
  final String title;
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
            boxShadow: _isHovered ? ui.colors.shadowMd : ui.colors.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mock Plot Content Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: ui.colors.panelHeader.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(ui.spacing.radiusMd.topLeft.x)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(LucideIcons.image, size: 32, color: ui.colors.textDisabled.withValues(alpha: 0.5)),
                      if (_isHovered)
                        Container(
                          color: Colors.black.withValues(alpha: 0.2),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ui.colors.accent,
                                shape: BoxShape.circle,
                                boxShadow: ui.colors.shadowSm,
                              ),
                              child: const Icon(LucideIcons.maximize2, size: 16, color: Colors.black87),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Caption
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiText(
                      text: widget.title,
                      variant: UiTextVariant.label,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    UiText(
                      text: 'Generated 2m ago',
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
}
