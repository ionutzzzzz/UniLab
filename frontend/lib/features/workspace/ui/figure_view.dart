import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../models/editor_models.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_icon_button.dart';
import '../../../widgets/plot_viewer/plot_widget.dart';
import '../../../providers/app_provider.dart';

class FigureView extends StatefulWidget {
  const FigureView({
    super.key,
    required this.plotData,
    required this.onBack,
  });

  final PlotData plotData;
  final VoidCallback onBack;

  @override
  State<FigureView> createState() => _FigureViewState();
}

class _FigureViewState extends State<FigureView> {
  double _zoom = 1.0;
  Uint8List? _decodedImage;
  final ScrollController _verticalScroll = ScrollController();
  final ScrollController _horizontalScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(FigureView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plotData.imageDataUri != widget.plotData.imageDataUri) {
      setState(() {
        _decodeImage();
      });
    }
  }

  @override
  void dispose() {
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  void _decodeImage() {
    if (widget.plotData.imageDataUri != null) {
      try {
        final base64Data = widget.plotData.imageDataUri!.split(',').last;
        _decodedImage = base64Decode(base64Data);
      } catch (e) {
        _decodedImage = null;
      }
    } else {
      _decodedImage = null;
    }
  }

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
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: UiText(
                  text: widget.plotData.title,
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
              UiIconButton(
                icon: LucideIcons.externalLink, 
                tooltip: 'Detach to Window', 
                size: 28, 
                iconSize: 16,
                onPressed: () {
                 try {
                   Provider.of<AppProvider>(context, listen: false).openDetachedPlotsWindow();
                 } catch (e) {
                   // AppProvider not available in this context (e.g., plots window)
                 }
               },
              ),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanUpdate: (details) {
                  if (_verticalScroll.hasClients) {
                    _verticalScroll.jumpTo(
                      (_verticalScroll.offset - details.delta.dy)
                          .clamp(0.0, _verticalScroll.position.maxScrollExtent),
                    );
                  }
                  if (_horizontalScroll.hasClients) {
                    _horizontalScroll.jumpTo(
                      (_horizontalScroll.offset - details.delta.dx)
                          .clamp(0.0, _horizontalScroll.position.maxScrollExtent),
                    );
                  }
                },
                child: SingleChildScrollView(
                  controller: _verticalScroll,
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    controller: _horizontalScroll,
                    scrollDirection: Axis.horizontal,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: ui.spacing.radiusLg,
                          border: Border.all(color: ui.colors.divider.withValues(alpha: 0.5)),
                        ),
                        child: _buildPlotContent(context, ui, constraints.maxWidth - 32),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlotContent(BuildContext context, UiTheme ui, double availableWidth) {
    // Case 1: Base64 PNG image
    if (widget.plotData.imageDataUri != null) {
      if (_decodedImage == null) {
        return Center(
          child: UiText(text: 'Error decoding image data', color: ui.colors.danger),
        );
      }
      return Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            final newZoom =
                (_zoom - pointerSignal.scrollDelta.dy / 1000.0).clamp(0.2, 5.0);
            if (newZoom != _zoom) {
              setState(() {
                _zoom = newZoom;
              });
            }
          }
        },
        child: RepaintBoundary(
          child: Image.memory(
            _decodedImage!,
            width: availableWidth * _zoom,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
            errorBuilder: (_, e, _) => Center(
              child: UiText(text: 'Image error: $e', color: ui.colors.danger),
            ),
          ),
        ),
      );
    }

    // Case 2: Structured line/scatter data
    if (widget.plotData.xData.isNotEmpty &&
        (widget.plotData.type == 'line' || widget.plotData.type == 'scatter' || widget.plotData.type == 'plot')) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: availableWidth * _zoom,
          height: (availableWidth * 0.6) * _zoom,
          child: PlotWidget(
            title: widget.plotData.title,
            data: List.generate(
              widget.plotData.xData.length,
              (i) => {'x': widget.plotData.xData[i], 'y': widget.plotData.yData[i]},
            ),
          ),
        ),
      );
    }

    // Case 3: 3D plots (not yet supported)
    if (widget.plotData.type == 'surf' || widget.plotData.type == 'mesh') {
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
            text: widget.plotData.title,
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
