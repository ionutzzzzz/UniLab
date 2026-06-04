import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../plot_viewer/plot_widget.dart';
import '../../theme/ui_theme.dart';
import '../ui_text.dart';

class PlotsPanel extends StatelessWidget {
  const PlotsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);

    return Container(
      color: ui.colors.canvas,
      child: Column(
        children: [
          // Header (Optional, since ConsolePanel has its own tab bar, but good for local actions)
          if (false) // Hide local header for now to avoid duplication
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ui.colors.panelHeader,
              border: Border(
                bottom: BorderSide(
                  color: ui.colors.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                UiText(
                  text: 'PLOTS GALLERY',
                  variant: UiTextVariant.label,
                  fontWeight: FontWeight.bold,
                ),
                IconButton(
                  icon: const Icon(Icons.clear_all, size: 14),
                  onPressed: () {
                    Provider.of<AppProvider>(context, listen: false).clearPlots();
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insights,
                          size: 48,
                          color: ui.colors.textMuted.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        UiText(
                          text: 'No plots generated',
                          variant: UiTextVariant.label,
                          color: ui.colors.textMuted,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: appProvider.generatedPlots.length,
                  itemBuilder: (context, index) {
                    final plotData = appProvider.generatedPlots[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PlotWidget(
                        key: ValueKey(plotData.id),
                        plot: plotData,
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
