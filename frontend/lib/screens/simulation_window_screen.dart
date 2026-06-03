import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/plot_viewer/plot_widget.dart';
import 'dart:convert';
import 'package:desktop_multi_window/desktop_multi_window.dart' as dmw;
import '../models/editor_models.dart';

class SimulationWindowScreen extends StatefulWidget {
  final String windowId;
  final Map<String, dynamic> args;

  const SimulationWindowScreen({
    super.key,
    required this.windowId,
    required this.args,
  });

  @override
  State<SimulationWindowScreen> createState() => _SimulationWindowScreenState();
}

class _SimulationWindowScreenState extends State<SimulationWindowScreen> {
  String? _model;
  List<dynamic> _controls = [];
  List<PlotData> _plots = [];

  @override
  void initState() {
    super.initState();
    _model = widget.args['model'];
    _controls = widget.args['controls'] ?? [];
    if (widget.args['plots'] != null) {
      _plots = (widget.args['plots'] as List).map((p) => PlotData.fromJson(p)).toList();
    }
    
    // Listen for updates from main window
    dmw.WindowMethodChannel('simulation_channel').setMethodCallHandler((call) async {
      if (call.method == 'update_sim_state') {
        final data = jsonDecode(call.arguments);
        if (mounted) {
          setState(() {
            if (data['controls'] != null) _controls = data['controls'];
            if (data['model'] != null) _model = data['model'];
            if (data['plots'] != null) {
              _plots = (data['plots'] as List).map((p) => PlotData.fromJson(p)).toList();
            }
          });
        }
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        final settings = settingsProvider.settings;
        final darkTheme = AppTheme.createTheme(settings, Brightness.dark);
        final lightTheme = AppTheme.createTheme(settings, Brightness.light);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          home: Scaffold(
            appBar: AppBar(
              title: Text('Simulation: ${_model ?? "Running..."}'),
            ),
            body: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _plots.isEmpty
                      ? const Center(child: Text('Waiting for plot output...'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _plots.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: PlotWidget(plot: _plots[index]),
                            );
                          },
                        ),
                ),
                if (_controls.isNotEmpty)
                  Container(
                    width: 280,
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('CONTROLS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _controls.length,
                            itemBuilder: (context, index) {
                              final ctrl = _controls[index];
                              return _buildControl(context, ctrl);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControl(BuildContext context, Map<String, dynamic> ctrl) {
    final id = ctrl['id'];
    final type = ctrl['type'];
    final label = ctrl['label'];

    if (type == 'slider') {
      double value = (ctrl['value'] as num).toDouble();
      double min = (ctrl['min'] as num).toDouble();
      double max = (ctrl['max'] as num).toDouble();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 13)),
                Text(value.toStringAsFixed(2), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              onChanged: (val) {
                dmw.WindowMethodChannel('simulation_channel').invokeMethod('on_sim_control', jsonEncode({
                  'id': id,
                  'value': val,
                }));
                if (mounted) {
                  setState(() {
                    ctrl['value'] = val;
                  });
                }
              },
            ),
          ],
        ),
      );
    } else if (type == 'button') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              dmw.WindowMethodChannel('simulation_channel').invokeMethod('on_sim_control', jsonEncode({
                'id': id,
                'value': true,
              }));
            },
            child: Text(label),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
