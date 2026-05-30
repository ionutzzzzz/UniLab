import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import '../core/layout/shell_layout_state.dart';
import '../theme/ui_theme.dart';

class SplitShell extends ConsumerStatefulWidget {
  const SplitShell({
    super.key,
    required this.leftPanel,
    required this.centerPanel,
    required this.rightPanel,
    required this.bottomPanel,
    this.showLeftPanel = true,
    this.showRightPanel = true,
  });

  final Widget leftPanel;
  final Widget centerPanel;
  final Widget rightPanel;
  final Widget bottomPanel;
  final bool showLeftPanel;
  final bool showRightPanel;

  @override
  ConsumerState<SplitShell> createState() => _SplitShellState();
}

class _SplitShellState extends ConsumerState<SplitShell> {
  MultiSplitViewController? _horizontalController;
  MultiSplitViewController? _verticalController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _horizontalController = MultiSplitViewController(areas: _buildHorizontalAreas());
    _verticalController = MultiSplitViewController(areas: [
      Area(data: 'main'),
      Area(data: 'bottom', size: 220, min: 100),
    ]);
  }

  List<Area> _buildHorizontalAreas() {
    List<Area> areas = [];
    if (widget.showLeftPanel) {
      areas.add(Area(size: 240, min: 150, data: 'left'));
    }
    areas.add(Area(data: 'center'));
    if (widget.showRightPanel) {
      areas.add(Area(size: 280, min: 200, data: 'right'));
    }
    return areas;
  }

  @override
  void didUpdateWidget(SplitShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showLeftPanel != widget.showLeftPanel || 
        oldWidget.showRightPanel != widget.showRightPanel) {
      setState(() {
         _horizontalController?.areas = _buildHorizontalAreas();
      });
    }
  }

  @override
  void dispose() {
    _horizontalController?.dispose();
    _verticalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final layoutState = ref.watch(shellLayoutProvider);

    Widget mainHorizontalSplit = MultiSplitView(
      controller: _horizontalController,
      builder: (context, area) {
        if (area.data == 'left') return widget.leftPanel;
        if (area.data == 'center') return widget.centerPanel;
        if (area.data == 'right') return widget.rightPanel;
        return const SizedBox.shrink();
      },
    );

    MultiSplitViewTheme mainTheme = MultiSplitViewTheme(
      data: MultiSplitViewThemeData(
        dividerThickness: 8, // Increased for much better hit area
        dividerPainter: DividerPainters.background(
          color: ui.colors.divider,
          highlightedColor: ui.colors.accent,
        ),
      ),
      child: mainHorizontalSplit,
    );

    if (!layoutState.showBottomPanel) {
      return mainTheme;
    }

    return MultiSplitViewTheme(
      data: MultiSplitViewThemeData(
        dividerThickness: 8,
        dividerPainter: DividerPainters.background(
          color: ui.colors.divider,
          highlightedColor: ui.colors.accent,
        ),
      ),
      child: MultiSplitView(
        axis: Axis.vertical,
        controller: _verticalController,
        builder: (context, area) {
          if (area.data == 'main') return mainTheme;
          if (area.data == 'bottom') return widget.bottomPanel;
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
