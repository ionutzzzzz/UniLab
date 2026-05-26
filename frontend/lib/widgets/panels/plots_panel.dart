import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../plot_viewer/plot_widget.dart';

class PlotsPanel extends StatelessWidget {
  const PlotsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PLOTS GALLERY',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear_all, size: 14),
                  onPressed: () {
                    // TODO: Clear plots in provider
                  },
                  tooltip: 'Clear Plots',
                  iconSize: 14,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ),
          // Plot content area
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, appProvider, _) {
                if (appProvider.generatedPlots.isEmpty) {
                  return Center(
                    child: Text(
                      'No plots generated',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF858585),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: appProvider.generatedPlots.length,
                  itemBuilder: (context, index) {
                    final plotData = appProvider.generatedPlots[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PlotWidget(
                        title: plotData['title'] ?? 'Figure',
                        data: plotData['data'] as List<Map<String, double>>?,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
