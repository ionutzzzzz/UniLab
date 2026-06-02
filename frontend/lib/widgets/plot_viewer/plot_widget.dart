import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import '../../models/editor_models.dart';

class PlotWidget extends StatelessWidget {
  final PlotData? plot;
  final String? title;
  final List<Map<String, double>>? data;

  const PlotWidget({
    super.key,
    this.plot,
    this.title,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = plot?.title ?? title ?? 'Figure';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayTitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_in, size: 14),
                    onPressed: () {
                      _showZoomedPlot(context);
                    },
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save, size: 14),
                    onPressed: () {},
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: _buildPlotContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPlotContent(BuildContext context) {
    if (plot?.type == 'image' && plot?.imageDataUri != null) {
      try {
        final uri = plot!.imageDataUri!;
        final String base64Data = uri.contains(',') ? uri.split(',')[1] : uri;
        return Center(
          child: Image.memory(
            base64Decode(base64Data),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Text('Error decoding image'),
            ),
          ),
        );
      } catch (e) {
        return const Center(child: Text('Invalid image data'));
      }
    }

    // Default to line chart for structured data
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).dividerColor,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Theme.of(context).dividerColor,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: const FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _getSpots(),
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getSpots() {
    if (plot != null) {
      if (plot!.xData.isEmpty || plot!.yData.isEmpty) {
        return const [
          FlSpot(0, 3),
          FlSpot(2.6, 2),
          FlSpot(4.9, 5),
          FlSpot(6.8, 3.1),
          FlSpot(8, 4),
          FlSpot(9.5, 3),
          FlSpot(11, 4),
        ];
      }

      final List<FlSpot> spots = [];
      final int len = plot!.xData.length < plot!.yData.length 
          ? plot!.xData.length 
          : plot!.yData.length;
      
      for (int i = 0; i < len; i++) {
        spots.add(FlSpot(plot!.xData[i], plot!.yData[i]));
      }
      return spots;
    }

    if (data != null && data!.isNotEmpty) {
      return data!.map((e) => FlSpot(e['x']!, e['y']!)).toList();
    }

    return const [
      FlSpot(0, 3),
      FlSpot(2.6, 2),
      FlSpot(4.9, 5),
      FlSpot(6.8, 3.1),
      FlSpot(8, 4),
      FlSpot(9.5, 3),
      FlSpot(11, 4),
    ];
  }

  void _showZoomedPlot(BuildContext context) {
    final displayTitle = plot?.title ?? title ?? 'Figure';
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).cardColor,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    displayTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildPlotContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
