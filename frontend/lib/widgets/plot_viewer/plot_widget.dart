import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../models/editor_models.dart';

class PlotWidget extends StatefulWidget {
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
  State<PlotWidget> createState() => _PlotWidgetState();
}

class _PlotWidgetState extends State<PlotWidget> {
  double _zoom = 1.0;
  Uint8List? _decodedImage;
  final ScrollController _horizontalScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(PlotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plot?.imageDataUri != widget.plot?.imageDataUri) {
      setState(() {
        _decodeImage();
      });
    }
  }

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  void _decodeImage() {
    if (widget.plot?.imageDataUri != null) {
      try {
        final uri = widget.plot!.imageDataUri!;
        final base64Data = uri.contains(',') ? uri.split(',')[1] : uri;
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
    final displayTitle = widget.plot?.title ?? widget.title ?? 'Figure';

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 24; // account for padding
        return Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              if (_horizontalScroll.hasClients) {
                _horizontalScroll.jumpTo(
                  (_horizontalScroll.offset - details.delta.dx)
                      .clamp(0.0, _horizontalScroll.position.maxScrollExtent),
                );
              }
            },
            child: SingleChildScrollView(
              controller: _horizontalScroll,
              scrollDirection: Axis.horizontal,
              child: Listener(
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
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.zero,
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 36.0),
                      child: _buildPlotContent(context, availableWidth),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayTitle,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.zoom_in, size: 14),
                              onPressed: () {
                                _showZoomedPlot(context);
                              },
                              constraints:
                                  const BoxConstraints(minWidth: 24, minHeight: 24),
                              padding: const EdgeInsets.all(4),
                            ),
                            IconButton(
                              icon: const Icon(Icons.save, size: 14),
                              onPressed: () {},
                              constraints:
                                  const BoxConstraints(minWidth: 24, minHeight: 24),
                              padding: const EdgeInsets.all(4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildPlotContent(BuildContext context, double availableWidth) {
    if (widget.plot?.type == 'image' && widget.plot?.imageDataUri != null) {
      if (_decodedImage == null) {
        return const Center(child: Text('Error decoding image data'));
      }
      return RepaintBoundary(
        child: Image.memory(
          _decodedImage!,
          width: availableWidth * _zoom,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.low,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Text('Error rendering image'),
          ),
        ),
      );
    }

    // Default to line chart for structured data
    return SizedBox(
      height: (availableWidth * 0.6) * _zoom,
      width: availableWidth * _zoom,
      child: LineChart(
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
    ),
    );
  }

  List<FlSpot> _getSpots() {
    if (widget.plot != null) {
      if (widget.plot!.xData.isEmpty || widget.plot!.yData.isEmpty) {
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
      final int len = widget.plot!.xData.length < widget.plot!.yData.length
          ? widget.plot!.xData.length
          : widget.plot!.yData.length;

      for (int i = 0; i < len; i++) {
        spots.add(FlSpot(widget.plot!.xData[i], widget.plot!.yData[i]));
      }
      return spots;
    }

    if (widget.data != null && widget.data!.isNotEmpty) {
      return widget.data!.map((e) => FlSpot(e['x']!, e['y']!)).toList();
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
    final displayTitle = widget.plot?.title ?? widget.title ?? 'Figure';
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
                child: _buildPlotContent(
                  context,
                  MediaQuery.of(context).size.width * 0.8 - 48,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
