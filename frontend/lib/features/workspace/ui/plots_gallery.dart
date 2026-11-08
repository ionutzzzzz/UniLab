import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
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
  bool _isListView = false;
  bool _showGallery = false;

  Widget _buildSimulationControlsBar(UiTheme ui, AppProvider appProvider) {
    if (!appProvider.isSimulationActive && appProvider.simulationControls.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: EdgeInsets.all(ui.spacing.sm),
      decoration: BoxDecoration(
        color: ui.colors.panelHeader,
        border: Border(
          top: BorderSide(color: ui.colors.divider.withValues(alpha: 0.6)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(LucideIcons.activity, size: 14, color: ui.colors.accent),
              const SizedBox(width: 6),
              UiText(
                text: 'LIVE SIMULATION (${(appProvider.simulationModel ?? "model").toUpperCase()})',
                variant: UiTextVariant.label,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: ui.colors.accent,
              ),
              const Spacer(),
              if (appProvider.isSimulationActive)
                TextButton.icon(
                  onPressed: () => appProvider.stopExecution(),
                  icon: Icon(LucideIcons.square, size: 12, color: ui.colors.danger),
                  label: UiText(
                    text: 'Stop',
                    variant: UiTextVariant.caption,
                    color: ui.colors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          ...appProvider.simulationControls.map((ctrl) {
            final id = ctrl['id']?.toString() ?? '';
            final label = ctrl['label']?.toString() ?? id;
            final type = ctrl['type']?.toString() ?? '';
            if (type == 'slider') {
              final minVal = (ctrl['min'] as num?)?.toDouble() ?? 0.0;
              final maxVal = (ctrl['max'] as num?)?.toDouble() ?? 100.0;
              final val = ((ctrl['value'] as num?)?.toDouble() ?? minVal).clamp(minVal, maxVal);
              return Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: UiText(
                      text: label,
                      variant: UiTextVariant.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: val,
                      min: minVal,
                      max: maxVal > minVal ? maxVal : minVal + 1.0,
                      activeColor: ui.colors.accent,
                      onChanged: (v) => appProvider.sendSimControlUpdate(id, v),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: UiText(
                      text: val.toStringAsFixed(2),
                      variant: UiTextVariant.codeBody,
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            } else if (type == 'button') {
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: OutlinedButton(
                  onPressed: () => appProvider.sendSimControlUpdate(id, true),
                  child: Text(label, style: const TextStyle(fontSize: 11)),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final appProvider = p.Provider.of<AppProvider>(context);

    // Automatically select the newest plot when plots are generated
    ref.listen(plotGalleryProvider, (previous, next) {
      if (previous != next && next.isNotEmpty) {
        setState(() {
          _selectedPlotId = next.last.id;
          _showGallery = false;
        });
      } else if (next.isEmpty && _selectedPlotId != null) {
        setState(() {
          _selectedPlotId = null;
        });
      }
    });

    final plots = ref.watch(plotGalleryProvider);

    if (plots.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: Center(
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
                      text: 'Run scripts or use the Engineering Toolbox to render interactive plots here.',
                      variant: UiTextVariant.label,
                      color: ui.colors.textMuted,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildSimulationControlsBar(ui, appProvider),
        ],
      );
    }

    // Ensure _selectedPlotId defaults to latest plot when not in gallery mode
    final activePlotId = _selectedPlotId != null && plots.any((p) => p.id == _selectedPlotId)
        ? _selectedPlotId!
        : plots.last.id;

    return Column(
      children: [
        // Local Figure Tab Bar & Controls
        Container(
          height: 34,
          padding: EdgeInsets.symmetric(horizontal: ui.spacing.sm),
          decoration: BoxDecoration(
            color: ui.colors.panelHeader,
            border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(plots.length, (i) {
                      final pItem = plots[i];
                      final isSelected = !_showGallery && pItem.id == activePlotId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => setState(() {
                            _selectedPlotId = pItem.id;
                            _showGallery = false;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? ui.colors.accent.withValues(alpha: 0.18)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected
                                    ? ui.colors.accent
                                    : ui.colors.divider.withValues(alpha: 0.4),
                              ),
                            ),
                            child: UiText(
                              text: pItem.figNum != null ? 'Fig ${pItem.figNum}' : 'Fig ${i + 1}',
                              variant: UiTextVariant.caption,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? ui.colors.accent : ui.colors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              UiIconButton(
                icon: LucideIcons.layoutGrid,
                tooltip: _showGallery ? 'Show Active Figure' : 'Show Thumbnail Gallery (${plots.length})',
                isActive: _showGallery,
                size: 24,
                iconSize: 14,
                onPressed: () => setState(() => _showGallery = !_showGallery),
              ),
              if (_showGallery) ...[
                SizedBox(width: ui.spacing.xs),
                UiIconButton(
                  icon: _isListView ? LucideIcons.list : LucideIcons.columns2,
                  tooltip: _isListView ? '2-Column Grid' : 'Single-Column List',
                  isActive: _isListView,
                  size: 24,
                  iconSize: 14,
                  onPressed: () => setState(() => _isListView = !_isListView),
                ),
              ],
              SizedBox(width: ui.spacing.xs),
              UiIconButton(
                icon: LucideIcons.trash2,
                tooltip: 'Clear All Plots',
                size: 24,
                iconSize: 14,
                onPressed: () => appProvider.clearPlots(),
              ),
            ],
          ),
        ),
        Expanded(
          child: _showGallery
              ? GridView.builder(
                  padding: EdgeInsets.all(ui.spacing.md),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _isListView ? 1 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: _isListView ? 1.8 : 1.2,
                  ),
                  itemCount: plots.length,
                  itemBuilder: (context, index) {
                    return _PlotThumbnail(
                      plotData: plots[index],
                      onTap: () => setState(() {
                        _selectedPlotId = plots[index].id;
                        _showGallery = false;
                      }),
                    );
                  },
                )
              : FigureView(
                  key: ValueKey(activePlotId),
                  plotData: plots.firstWhere(
                    (p) => p.id == activePlotId,
                    orElse: () => plots.last,
                  ),
                  onBack: () => setState(() => _showGallery = true),
                ),
        ),
        _buildSimulationControlsBar(ui, appProvider),
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
  Uint8List? _cachedImageBytes;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(_PlotThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plotData.imageDataUri != widget.plotData.imageDataUri) {
      _decodeImage();
    }
  }

  void _decodeImage() {
    if (widget.plotData.imageDataUri != null) {
      try {
        _cachedImageBytes =
            base64Decode(widget.plotData.imageDataUri!.split(',').last);
      } catch (_) {
        _cachedImageBytes = null;
      }
    } else {
      _cachedImageBytes = null;
    }
  }

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
                      if (_cachedImageBytes != null)
                        Image.memory(
                          _cachedImageBytes!,
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
                            math.min(
                              widget.plotData.xData.length,
                              widget.plotData.yData.length,
                            ),
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
