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
