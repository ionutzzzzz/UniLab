import 'package:flutter/material.dart';
import '../../providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Manages draggable panel layout with reordering support
class DraggablePanelLayout extends StatefulWidget {
  final List<PanelItem> panels;
  final Axis axis;
  final Function(List<PanelItem>)? onPanelsReordered;

  const DraggablePanelLayout({
    super.key,
    required this.panels,
    this.axis = Axis.horizontal,
    this.onPanelsReordered,
  });

  @override
  State<DraggablePanelLayout> createState() => _DraggablePanelLayoutState();
}

class _DraggablePanelLayoutState extends State<DraggablePanelLayout> {
  late List<PanelItem> _panels;

  @override
  void initState() {
    super.initState();
    _panels = List.from(widget.panels);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        return widget.axis == Axis.horizontal
            ? Row(
                children: _buildPanelList(context),
              )
            : Column(
                children: _buildPanelList(context),
              );
      },
    );
  }

  List<Widget> _buildPanelList(BuildContext context) {
    final widgets = <Widget>[];

    for (int i = 0; i < _panels.length; i++) {
      final panel = _panels[i];

      // Panel item
      widgets.add(
        Expanded(
          flex: (panel.flex * 100).toInt(),
          child: DragTarget<int>(
            onWillAcceptWithDetails: (details) {
              return details.data != i;
            },
            onAcceptWithDetails: (details) {
              setState(() {
                final item = _panels.removeAt(details.data);
                _panels.insert(i, item);
              });
              widget.onPanelsReordered?.call(_panels);
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;

              return Container(
                decoration: BoxDecoration(
                  border: isHovering
                      ? Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        )
                      : null,
                ),
                child: Draggable<int>(
                  data: i,
                  feedback: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.7),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Center(
                      child: Text(
                        panel.title,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  child: panel.child,
                ),
              );
            },
          ),
        ),
      );

      // Divider between panels
      if (i < _panels.length - 1) {
        widgets.add(
          MouseRegion(
            cursor: widget.axis == Axis.horizontal
                ? SystemMouseCursors.resizeColumn
                : SystemMouseCursors.resizeRow,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  if (widget.axis == Axis.horizontal) {
                    _panels[i] =
                        _panels[i].copyWith(flex: _panels[i].flex + details.delta.dx / 1000);
                    _panels[i + 1] = _panels[i + 1]
                        .copyWith(flex: _panels[i + 1].flex - details.delta.dx / 1000);
                  } else {
                    _panels[i] =
                        _panels[i].copyWith(flex: _panels[i].flex + details.delta.dy / 1000);
                    _panels[i + 1] = _panels[i + 1]
                        .copyWith(flex: _panels[i + 1].flex - details.delta.dy / 1000);
                  }

                  // Clamp flex values
                  _panels[i] = _panels[i].copyWith(
                    flex: _panels[i].flex.clamp(0.1, 0.8),
                  );
                  _panels[i + 1] = _panels[i + 1].copyWith(
                    flex: _panels[i + 1].flex.clamp(0.1, 0.8),
                  );
                });
                widget.onPanelsReordered?.call(_panels);
              },
              child: Container(
                width: widget.axis == Axis.horizontal ? 4 : double.infinity,
                height: widget.axis == Axis.vertical ? 4 : double.infinity,
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

/// Represents a panel in the draggable layout
class PanelItem {
  final String id;
  final String title;
  final Widget child;
  final double flex;
  final double minFlex;
  final double maxFlex;

  PanelItem({
    required this.id,
    required this.title,
    required this.child,
    this.flex = 0.3,
    this.minFlex = 0.1,
    this.maxFlex = 0.8,
  });

  PanelItem copyWith({
    String? id,
    String? title,
    Widget? child,
    double? flex,
    double? minFlex,
    double? maxFlex,
  }) {
    return PanelItem(
      id: id ?? this.id,
      title: title ?? this.title,
      child: child ?? this.child,
      flex: flex ?? this.flex,
      minFlex: minFlex ?? this.minFlex,
      maxFlex: maxFlex ?? this.maxFlex,
    );
  }
}
