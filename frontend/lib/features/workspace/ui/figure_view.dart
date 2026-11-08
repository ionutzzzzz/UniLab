import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../models/editor_models.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_button.dart';
import '../../../widgets/ui_icon_button.dart';
import '../../../widgets/plot_viewer/plot_widget.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/platform_io.dart' as io;

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
  final TransformationController _transController = TransformationController();
  late bool _showGrid;
  late bool _showLegend;
  late bool _showLabels;
  late String _title;
  String? _plotTitle;
  String? _xlabel;
  String? _ylabel;
  String _colormap = 'Viridis';
  double _lineWidth = 1.8;
  double _fontSize = 9.5;
  String _themeMode = 'theme';
  Uint8List? _decodedImage;

  static const List<String> _availableColormaps = [
    'Viridis',
    'Plasma',
    'Inferno',
    'Magma',
    'Cividis',
    'Coolwarm',
    'Turbo',
    'Jet',
    'Rainbow',
    'Greys',
    'Blues',
  ];

  @override
  void initState() {
    super.initState();
    _syncMetadataFromWidget();
    _decodeImage();
  }

  void _syncMetadataFromWidget() {
    _showGrid = widget.plotData.showGrid ?? true;
    _showLegend = widget.plotData.showLegend ?? false;
    _showLabels = widget.plotData.showLabels ?? true;
    _title = widget.plotData.title;
    _plotTitle = widget.plotData.plotTitle ?? '';
    _xlabel = widget.plotData.xlabel;
    _ylabel = widget.plotData.ylabel;
    if (widget.plotData.colormap != null && widget.plotData.colormap!.isNotEmpty) {
      final match = _availableColormaps.firstWhere(
        (c) => c.toLowerCase() == widget.plotData.colormap!.toLowerCase(),
        orElse: () => _availableColormaps.first,
      );
      _colormap = match;
    }
    _lineWidth = widget.plotData.lineWidth ?? 1.8;
    _fontSize = widget.plotData.fontSize ?? 9.5;
    _themeMode = widget.plotData.themeMode ?? 'theme';
  }

  @override
  void didUpdateWidget(FigureView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plotData.imageDataUri != widget.plotData.imageDataUri ||
        oldWidget.plotData.title != widget.plotData.title ||
        oldWidget.plotData.plotTitle != widget.plotData.plotTitle ||
        oldWidget.plotData.showGrid != widget.plotData.showGrid ||
        oldWidget.plotData.showLegend != widget.plotData.showLegend ||
        oldWidget.plotData.showLabels != widget.plotData.showLabels ||
        oldWidget.plotData.colormap != widget.plotData.colormap ||
        oldWidget.plotData.lineWidth != widget.plotData.lineWidth ||
        oldWidget.plotData.fontSize != widget.plotData.fontSize ||
        oldWidget.plotData.xlabel != widget.plotData.xlabel ||
        oldWidget.plotData.ylabel != widget.plotData.ylabel) {
      setState(() {
        _syncMetadataFromWidget();
        _decodeImage();
      });
    }
  }

  @override
  void dispose() {
    _transController.dispose();
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

  void _applyCustomization({
    String? title,
    String? xlabel,
    String? ylabel,
    bool? showGrid,
    bool? showLegend,
    bool? showLabels,
    String? colormap,
    double? lineWidth,
    double? fontSize,
    String? themeMode,
  }) {
    final app = Provider.of<AppProvider?>(context, listen: false);
    if (app != null) {
      app.customizePlotFigure(
        widget.plotData.figNum,
        title: title,
        xlabel: xlabel,
        ylabel: ylabel,
        showGrid: showGrid,
        showLegend: showLegend,
        showLabels: showLabels,
        colormap: colormap,
        lineWidth: lineWidth,
        fontSize: fontSize,
        themeMode: themeMode,
      );
    }
  }

  Future<void> _exportFigure() async {
    final appProvider = Provider.of<AppProvider?>(context, listen: false);
    if (appProvider != null) {
      final ok = await appProvider.exportPlotSnapshot(widget.plotData);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Figure exported successfully.')),
        );
      }
      return;
    }

    try {
      final sanitized = _title.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      if (_decodedImage != null) {
        String? out = await FilePicker.platform.saveFile(
          dialogTitle: 'Export Figure as PNG',
          fileName: '$sanitized.png',
          type: FileType.custom,
          allowedExtensions: ['png'],
        );
        if (out == null) return;
        if (!out.toLowerCase().endsWith('.png')) out += '.png';
        await io.File(out).writeAsBytes(_decodedImage!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved figure to $out')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export figure: $e')),
        );
      }
    }
  }

  void _showLabelsDialog() {
    final ui = UiTheme.of(context);
    final titleCtrl = TextEditingController(text: _plotTitle?.isNotEmpty == true ? _plotTitle! : '');
    final xCtrl = TextEditingController(text: _xlabel ?? '');
    final yCtrl = TextEditingController(text: _ylabel ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        title: const UiText(
          text: 'Edit Matplotlib Figure Labels',
          variant: UiTextVariant.body,
          fontWeight: FontWeight.bold,
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UiText(text: 'Plot Title', variant: UiTextVariant.caption, color: ui.colors.textMuted),
              const SizedBox(height: 4),
              TextField(
                controller: titleCtrl,
                style: TextStyle(color: ui.colors.textPrimary, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'e.g. Frequency Response / Step Response',
                  hintStyle: TextStyle(color: ui.colors.textDisabled, fontSize: 11),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              UiText(text: 'X-Axis Label', variant: UiTextVariant.caption, color: ui.colors.textMuted),
              const SizedBox(height: 4),
              TextField(
                controller: xCtrl,
                style: TextStyle(color: ui.colors.textPrimary, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'e.g. Time (s) or Frequency (rad/s)',
                  hintStyle: TextStyle(color: ui.colors.textDisabled, fontSize: 11),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              UiText(text: 'Y-Axis Label', variant: UiTextVariant.caption, color: ui.colors.textMuted),
              const SizedBox(height: 4),
              TextField(
                controller: yCtrl,
                style: TextStyle(color: ui.colors.textPrimary, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'e.g. Amplitude or Magnitude (dB)',
                  hintStyle: TextStyle(color: ui.colors.textDisabled, fontSize: 11),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          UiButton(
            label: 'Cancel',
            variant: UiButtonVariant.ghost,
            onPressed: () => Navigator.pop(dialogContext),
          ),
          UiButton(
            label: 'Apply to Figure',
            variant: UiButtonVariant.primary,
            onPressed: () {
              final newT = titleCtrl.text.trim();
              final newX = xCtrl.text.trim();
              final newY = yCtrl.text.trim();
              Navigator.pop(dialogContext);
              setState(() {
                _plotTitle = newT;
                _xlabel = newX;
                _ylabel = newY;
              });
              _applyCustomization(
                title: newT,
                xlabel: newX,
                ylabel: newY,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showStyleDialog() {
    final ui = UiTheme.of(context);
    double localLw = _lineWidth;
    double localFs = _fontSize;
    String localTheme = _themeMode;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: ui.colors.panel,
          surfaceTintColor: Colors.transparent,
          title: const UiText(
            text: 'Plot Style & Rendering Options',
            variant: UiTextVariant.body,
            fontWeight: FontWeight.bold,
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    UiText(text: 'Line Width: ${localLw.toStringAsFixed(1)} pt', variant: UiTextVariant.caption),
                    UiText(text: 'Default 1.8 pt', variant: UiTextVariant.caption, color: ui.colors.textMuted),
                  ],
                ),
                Slider(
                  value: localLw,
                  min: 0.8,
                  max: 4.0,
                  divisions: 16,
                  label: '${localLw.toStringAsFixed(1)} pt',
                  onChanged: (v) => setDialogState(() => localLw = v),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    UiText(text: 'Font Size: ${localFs.toStringAsFixed(1)} pt', variant: UiTextVariant.caption),
                    UiText(text: 'Default 9.5 pt', variant: UiTextVariant.caption, color: ui.colors.textMuted),
                  ],
                ),
                Slider(
                  value: localFs,
                  min: 7.0,
                  max: 16.0,
                  divisions: 18,
                  label: '${localFs.toStringAsFixed(1)} pt',
                  onChanged: (v) => setDialogState(() => localFs = v),
                ),
                const SizedBox(height: 12),
                UiText(text: 'Plot Color Theme', variant: UiTextVariant.caption, color: ui.colors.textMuted),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: localTheme,
                  isDense: true,
                  dropdownColor: ui.colors.panel,
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  items: const [
                    DropdownMenuItem(value: 'theme', child: Text('Match Editor Theme (Unified)')),
                    DropdownMenuItem(value: 'dark', child: Text('Engineering Dark High-Contrast')),
                    DropdownMenuItem(value: 'light', child: Text('Publication Clean Light')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => localTheme = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            UiButton(
              label: 'Cancel',
              variant: UiButtonVariant.ghost,
              onPressed: () => Navigator.pop(dialogCtx),
            ),
            UiButton(
              label: 'Apply Options',
              variant: UiButtonVariant.primary,
              onPressed: () {
                Navigator.pop(dialogCtx);
                setState(() {
                  _lineWidth = localLw;
                  _fontSize = localFs;
                  _themeMode = localTheme;
                });
                _applyCustomization(
                  lineWidth: localLw,
                  fontSize: localFs,
                  themeMode: localTheme,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _zoomIn() {
    final cur = _transController.value.clone();
    cur.scaleByDouble(1.25, 1.25, 1.0, 1.0);
    _transController.value = cur;
  }

  void _zoomOut() {
    final cur = _transController.value.clone();
    cur.scaleByDouble(0.8, 0.8, 1.0, 1.0);
    _transController.value = cur;
  }

  void _resetZoom() {
    _transController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final settings = Provider.of<SettingsProvider?>(context);

    return Column(
      children: [
        // Primary Header Toolbar
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
                child: Row(
                  children: [
                    UiText(
                      text: _title,
                      variant: UiTextVariant.label,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.plotData.numSubplots != null && widget.plotData.numSubplots! > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ui.colors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: UiText(
                          text: '${widget.plotData.numSubplots} Panels',
                          variant: UiTextVariant.caption,
                          fontSize: 9,
                          color: ui.colors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              UiIconButton(
                icon: LucideIcons.zoomIn,
                tooltip: 'Zoom In',
                size: 28,
                iconSize: 15,
                onPressed: _zoomIn,
              ),
              UiIconButton(
                icon: LucideIcons.zoomOut,
                tooltip: 'Zoom Out',
                size: 28,
                iconSize: 15,
                onPressed: _zoomOut,
              ),
              UiIconButton(
                icon: LucideIcons.maximize2,
                tooltip: 'Fit to View (Reset Zoom)',
                size: 28,
                iconSize: 15,
                onPressed: _resetZoom,
              ),
              Container(width: 1, height: 18, color: ui.colors.divider, margin: const EdgeInsets.symmetric(horizontal: 4)),
              UiIconButton(
                icon: LucideIcons.sliders,
                tooltip: 'Style Options (Line Width / Font / Theme)',
                size: 28,
                iconSize: 15,
                onPressed: _showStyleDialog,
              ),
              UiIconButton(
                icon: LucideIcons.download,
                tooltip: 'Export PNG Snapshot',
                size: 28,
                iconSize: 15,
                onPressed: _exportFigure,
              ),
            ],
          ),
        ),

        // Secondary Formatting Toolbar (Live Matplotlib Figure Controls)
        Container(
          height: 36,
          padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
          decoration: BoxDecoration(
            color: ui.colors.panel.withValues(alpha: 0.65),
            border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.3))),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ToolbarAction(
                  icon: LucideIcons.grid3x3,
                  label: 'Grid',
                  isActive: _showGrid,
                  onTap: () {
                    final newVal = !_showGrid;
                    setState(() => _showGrid = newVal);
                    _applyCustomization(showGrid: newVal);
                    settings?.updateSettings(settings.settings.copyWith(plotShowGrid: newVal));
                  },
                ),
                const SizedBox(width: 12),
                _ToolbarAction(
                  icon: LucideIcons.list,
                  label: 'Legend',
                  isActive: _showLegend,
                  onTap: () {
                    final newVal = !_showLegend;
                    setState(() => _showLegend = newVal);
                    _applyCustomization(showLegend: newVal);
                    settings?.updateSettings(settings.settings.copyWith(plotShowLegend: newVal));
                  },
                ),
                const SizedBox(width: 12),
                _ToolbarAction(
                  icon: LucideIcons.type,
                  label: 'Labels',
                  isActive: _showLabels,
                  onTap: () {
                    final newVal = !_showLabels;
                    setState(() => _showLabels = newVal);
                    _applyCustomization(showLabels: newVal);
                    settings?.updateSettings(settings.settings.copyWith(plotShowLabels: newVal));
                  },
                ),
                const SizedBox(width: 6),
                UiIconButton(
                  icon: LucideIcons.edit3,
                  tooltip: 'Edit Titles & Labels',
                  size: 24,
                  iconSize: 12,
                  onPressed: _showLabelsDialog,
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 16, color: ui.colors.divider),
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.palette, size: 12, color: ui.colors.textMuted),
                    const SizedBox(width: 6),
                    UiText(text: 'Colormap:', variant: UiTextVariant.caption, color: ui.colors.textMuted),
                    const SizedBox(width: 6),
                    DropdownButton<String>(
                      value: _colormap,
                      isDense: true,
                      underline: const SizedBox(),
                      dropdownColor: ui.colors.panel,
                      style: TextStyle(color: ui.colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                      items: _availableColormaps.map((cm) {
                        return DropdownMenuItem(
                          value: cm,
                          child: Text(cm),
                        );
                      }).toList(),
                      onChanged: (newCm) {
                        if (newCm != null && newCm != _colormap) {
                          setState(() => _colormap = newCm);
                          _applyCustomization(colormap: newCm);
                          settings?.updateSettings(settings.settings.copyWith(plotColormap: newCm));
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Plot Canvas with Smooth InteractiveViewer (Pan / Zoom / Pinch)
        Expanded(
          child: Container(
            color: ui.colors.canvas,
            width: double.infinity,
            height: double.infinity,
            child: InteractiveViewer(
              transformationController: _transController,
              minScale: 0.2,
              maxScale: 6.0,
              boundaryMargin: const EdgeInsets.all(250),
              clipBehavior: Clip.hardEdge,
              child: Center(
                child: _buildPlotContent(context, ui),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlotContent(BuildContext context, UiTheme ui) {
    if (widget.plotData.imageDataUri != null) {
      if (_decodedImage == null) {
        return Center(
          child: UiText(text: 'Error decoding figure image', color: ui.colors.danger),
        );
      }
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.memory(
            _decodedImage!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, e, __) => Center(
              child: UiText(text: 'Image error: $e', color: ui.colors.danger),
            ),
          ),
        ),
      );
    }

    if (widget.plotData.xData.isNotEmpty &&
        (widget.plotData.type == 'line' || widget.plotData.type == 'scatter' || widget.plotData.type == 'plot')) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 640,
          height: 420,
          child: PlotWidget(
            title: widget.plotData.title,
            data: List.generate(
              math.min(widget.plotData.xData.length, widget.plotData.yData.length),
              (i) => {'x': widget.plotData.xData[i], 'y': widget.plotData.yData[i]},
            ),
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.lineChart, size: 64, color: ui.colors.accent.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
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

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final fg = isActive ? ui.colors.accent : ui.colors.textMuted;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? ui.colors.accent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: ui.spacing.radiusSm,
            border: Border.all(
              color: isActive ? ui.colors.accent.withValues(alpha: 0.4) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 6),
              UiText(
                text: label,
                variant: UiTextVariant.label,
                fontSize: 10,
                color: fg,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
