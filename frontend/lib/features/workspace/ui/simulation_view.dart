import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/plot_viewer/plot_widget.dart';

class SimulationView extends StatelessWidget {
  const SimulationView({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final controls = appProvider.simulationControls;
    final plots = appProvider.simulationPlots;

    if (!appProvider.isSimulationActive && plots.isEmpty && controls.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No active simulation', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Row(
            children: [
              Icon(
                appProvider.isSimulationActive ? Icons.play_circle : Icons.stop_circle,
                color: appProvider.isSimulationActive ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Simulation: ${appProvider.simulationModel ?? "Unknown"}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (appProvider.isSimulationActive)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: plots.isEmpty
                    ? const Center(child: Text('Waiting for plot output...'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: plots.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: PlotWidget(plot: plots[index]),
                          );
                        },
                      ),
              ),
              if (controls.isNotEmpty)
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
                    color: Theme.of(context).cardColor.withValues(alpha: 0.5),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: controls.length,
                    itemBuilder: (context, index) {
                      final ctrl = controls[index];
                      return _buildControl(context, ctrl, appProvider);
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControl(BuildContext context, Map<String, dynamic> ctrl, AppProvider provider) {
    final id = ctrl['id'];
    final type = ctrl['type'];
    final label = ctrl['label'];

    if (type == 'slider') {
      double value = (ctrl['value'] as num).toDouble();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Slider(
              value: value,
              min: (ctrl['min'] as num).toDouble(),
              max: (ctrl['max'] as num).toDouble(),
              onChanged: (val) {
                provider.sendSimControlUpdate(id, val);
              },
            ),
          ],
        ),
      );
    } else if (type == 'button') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ElevatedButton(
          onPressed: () => provider.sendSimControlUpdate(id, true),
          child: Text(label),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
