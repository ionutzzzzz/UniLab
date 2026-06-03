import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/editor_models.dart';
import '../features/workspace/ui/figure_view.dart';
import '../widgets/ui_text.dart';
import '../theme/ui_theme.dart';

class PlotsWindowScreen extends StatefulWidget {
  final String windowId;
  final Map<String, dynamic> args;

  const PlotsWindowScreen({
    super.key,
    required this.windowId,
    required this.args,
  });

  @override
  State<PlotsWindowScreen> createState() => _PlotsWindowScreenState();
}

class _PlotsWindowScreenState extends State<PlotsWindowScreen>
    with WidgetsBindingObserver {
  List<PlotData> _plots = [];
  String? _selectedPlotId;
  late final WindowMethodChannel _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize with data from args if available
    if (widget.args.containsKey('plots')) {
      final List<dynamic> plotsJson = widget.args['plots'];
      _plots = plotsJson
          .map((data) => _parsePlotData(data as Map<String, dynamic>))
          .toList();
    }

    // Set up method channel for communication
    _channel = WindowMethodChannel('plots_window_channel');
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'update_plots') {
        final List<dynamic> plotsData = jsonDecode(call.arguments);
        if (mounted) {
          setState(() {
            _plots = plotsData
                .map((data) => _parsePlotData(data as Map<String, dynamic>))
                .toList();
          });
        }
        return 'success';
      } else if (call.method == 'close_window') {
        await _closeWindow();
        return 'success';
      }
      return null;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    await _closeWindow();
    return true;
  }

  Future<void> _closeWindow() async {
    try {
      await _channel.invokeMethod('window_closing', {});

      await WindowController.fromWindowId(widget.windowId).hide();
    } catch (e) {
      debugPrint('Error closing window: $e');
    }
  }

  PlotData _parsePlotData(Map<String, dynamic> data) {
    return PlotData(
      id: data['id'],
      title: data['title'],
      type: data['type'],
      xData:
          (data['xData'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      yData:
          (data['yData'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      imageDataUri: data['imageDataUri'],
      createdAt: DateTime.parse(data['createdAt']),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final settings = settingsProvider.settings;
    final ui = createUiTheme(settings, Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: ui.colors.canvas,
      body: Column(
        children: [
          // Custom Title Bar for the detached window
          _buildTitleBar(ui),
          Expanded(
            child: _plots.isEmpty
                ? _buildEmptyState(ui)
                : _selectedPlotId != null
                ? FigureView(
                    plotData: _plots.firstWhere((p) => p.id == _selectedPlotId),
                    onBack: () => setState(() => _selectedPlotId = null),
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(ui.spacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                    itemCount: _plots.length,
                    itemBuilder: (context, index) {
                      return _PlotThumbnail(
                        plotData: _plots[index],
                        ui: ui,
                        onTap: () =>
                            setState(() => _selectedPlotId = _plots[index].id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar(UiTheme ui) {
    return Container(
      height: 40,
      color: ui.colors.panelHeader,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.insights, size: 18, color: ui.colors.accent),
          const SizedBox(width: 12),
          const UiText(
            text: 'UniLab Simulations & Plots',
            variant: UiTextVariant.label,
            fontWeight: FontWeight.bold,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 16),
            tooltip: 'Refresh',
            onPressed: () {
              // Request data from main window if needed
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            tooltip: 'Close',
            onPressed: _closeWindow,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(UiTheme ui) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_graph, size: 64, color: ui.colors.textDisabled),
          const SizedBox(height: 24),
          UiText(
            text: 'Waiting for simulation data...',
            variant: UiTextVariant.body,
            color: ui.colors.textMuted,
          ),
        ],
      ),
    );
  }
}

// Internal thumbnail widget matching plots_gallery.dart style
class _PlotThumbnail extends StatelessWidget {
  final PlotData plotData;
  final UiTheme ui;
  final VoidCallback onTap;

  const _PlotThumbnail({
    required this.plotData,
    required this.ui,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ui.colors.canvas,
          borderRadius: ui.spacing.radiusMd,
          border: Border.all(color: ui.colors.divider.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Expanded(
              child: plotData.imageDataUri != null
                  ? Image.memory(
                      base64Decode(plotData.imageDataUri!.split(',').last),
                      fit: BoxFit.contain,
                    )
                  : Center(
                      child: Icon(Icons.show_chart, color: ui.colors.accent),
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              color: ui.colors.panelHeader.withValues(alpha: 0.5),
              width: double.infinity,
              child: Text(
                plotData.title,
                style: ui.typography.label.copyWith(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
