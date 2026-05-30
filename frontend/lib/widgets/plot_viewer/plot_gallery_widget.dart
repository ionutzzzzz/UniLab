import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/ui_theme.dart';

class PlotGalleryWidget extends StatelessWidget {
  const PlotGalleryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: ui.colors.panel,
        border: Border(
          left: BorderSide(color: ui.colors.border, width: ui.spacing.strokeHair),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, ui),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPlotCard(
                  context,
                  ui,
                  title: 'Signal Response (Hz)',
                  color: ui.colors.accent, // Pastel1 Blue
                  data: [
                    const FlSpot(0, 1),
                    const FlSpot(1, 1.5),
                    const FlSpot(2, 1.4),
                    const FlSpot(3, 3.4),
                    const FlSpot(4, 2),
                    const FlSpot(5, 2.2),
                    const FlSpot(6, 1.8),
                    const FlSpot(7, 3),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPlotCard(
                  context,
                  ui,
                  title: 'Entropy Distribution',
                  color: ui.colors.danger, // Pastel1 Red
                  data: [
                    const FlSpot(0, 3),
                    const FlSpot(1, 2.6),
                    const FlSpot(2, 4),
                    const FlSpot(3, 1.5),
                    const FlSpot(4, 2),
                    const FlSpot(5, 3.5),
                    const FlSpot(6, 2.5),
                    const FlSpot(7, 2),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPlotCard(
                  context,
                  ui,
                  title: 'Kernel Density Estimation',
                  color: ui.colors.success, // Pastel1 Green
                  data: [
                    const FlSpot(0, 1),
                    const FlSpot(1, 1.2),
                    const FlSpot(2, 1.8),
                    const FlSpot(3, 2.5),
                    const FlSpot(4, 3),
                    const FlSpot(5, 2.8),
                    const FlSpot(6, 2.2),
                    const FlSpot(7, 1.5),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UiTheme ui) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ui.colors.panelHeader,
        border: Border(
          bottom: BorderSide(color: ui.colors.border, width: ui.spacing.strokeHair),
          top: BorderSide(color: ui.colors.accent.withValues(alpha: 0.1), width: 1), // 1px border highlight
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.barChart3, size: 16, color: ui.colors.accent),
          const SizedBox(width: 8),
          Text(
            'VISUALIZATION',
            style: ui.typography.label.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: ui.colors.textPrimary,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          _buildHeaderAction(LucideIcons.plus, ui),
          _buildHeaderAction(LucideIcons.filter, ui),
          _buildHeaderAction(LucideIcons.moreHorizontal, ui),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, UiTheme ui) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 14, color: ui.colors.textMuted),
        ),
      ),
    );
  }

  Widget _buildPlotCard(
    BuildContext context,
    UiTheme ui, {
    required String title,
    required Color color,
    required List<FlSpot> data,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ui.colors.canvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ui.colors.border, width: ui.spacing.strokeHair),
      ),
      child: Column(
        children: [
          // Plot Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ui.colors.panelHeader.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              border: Border(
                bottom: BorderSide(color: ui.colors.border, width: ui.spacing.strokeHair),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: ui.typography.body.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ui.colors.textSecondary,
                  ),
                ),
                const Spacer(),
                _buildPlotAction(LucideIcons.zoomIn, ui),
                _buildPlotAction(LucideIcons.maximize2, ui),
                _buildPlotAction(LucideIcons.download, ui),
              ],
            ),
          ),
          // Chart Area
          Container(
            height: 180,
            padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: ui.colors.border.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: ui.colors.border.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 2,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: ui.typography.label.copyWith(
                          fontSize: 9,
                          color: ui.colors.textDisabled,
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: ui.typography.label.copyWith(
                          fontSize: 9,
                          color: ui.colors.textDisabled,
                        ),
                      ),
                      reservedSize: 22,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: color,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0.01),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => ui.colors.overlay,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y}',
                          ui.typography.label.copyWith(
                            color: ui.colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlotAction(IconData icon, UiTheme ui) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Icon(icon, size: 14, color: ui.colors.textMuted),
      ),
    );
  }
}
