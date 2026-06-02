import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import '../core/layout/shell_layout_state.dart';
import '../theme/ui_theme.dart';

class SplitShell extends ConsumerStatefulWidget {
  const SplitShell({
    super.key,
    required this.leftPanel,
    required this.leftRail,
    required this.centerPanel,
    required this.rightPanel,
    required this.rightRail,
    required this.bottomPanel,
    this.showLeftPanel = true,
    this.showRightPanel = true,
  });

  final Widget leftPanel;
  final Widget leftRail;
  final Widget centerPanel;
  final Widget rightPanel;
  final Widget rightRail;
  final Widget bottomPanel;
  final bool showLeftPanel;
  final bool showRightPanel;

  @override
  ConsumerState<SplitShell> createState() => _SplitShellState();
}

class _SplitShellState extends ConsumerState<SplitShell> {
  MultiSplitViewController? _horizontalController;
  MultiSplitViewController? _verticalController;
  final GlobalKey _horizontalKey = GlobalKey(debugLabel: 'main_horizontal_split');
  final GlobalKey _verticalKey = GlobalKey(debugLabel: 'center_vertical_split');

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _horizontalController = MultiSplitViewController(areas: _buildHorizontalAreas());
    _verticalController = MultiSplitViewController(areas: [
      Area(data: 'main', min: 100),
      Area(data: 'bottom', size: 220, min: 100),
    ]);
  }

  List<Area> _buildHorizontalAreas() {
    List<Area> areas = [];
    if (widget.showLeftPanel) {
      areas.add(Area(size: 240, min: 50, data: 'left'));
    } else {
      areas.add(Area(size: 48, min: 48, data: 'left_rail'));
    }
    
    areas.add(Area(data: 'center'));
    
    if (widget.showRightPanel) {
      areas.add(Area(size: 280, min: 50, data: 'right'));
    } else {
      areas.add(Area(size: 48, min: 48, data: 'right_rail'));
    }
    return areas;
  }

  List<Area> _buildVerticalAreas(bool showBottom) {
    List<Area> areas = [
      Area(data: 'main'),
    ];
    if (showBottom) {
      areas.add(Area(data: 'bottom', size: 220, min: 100));
    }
    return areas;
  }

  @override
  void didUpdateWidget(SplitShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showLeftPanel != widget.showLeftPanel || 
        oldWidget.showRightPanel != widget.showRightPanel) {
      _horizontalController?.areas = _buildHorizontalAreas();
    }
  }

  @override
  void dispose() {
    _horizontalController?.dispose();
    _verticalController?.dispose();
    super.dispose();
  }

  void _resetCursor() {
    // Attempt to reset the stuck resize cursor when the divider is unmounted mid-drag
    SystemChannels.mouseCursor.invokeMethod<void>(
      'activateSystemCursor',
      <String, dynamic>{
        'kind': 'basic',
        'device': 1,
      },
    ).catchError((_) {});
  }

  Widget _buildLeftPanelWrapper() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 100 && widget.showLeftPanel) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ref.read(shellLayoutProvider).showLeftPanel) {
              _resetCursor();
              ref.read(shellLayoutProvider.notifier).toggleLeftPanel();
            }
          });
          return const SizedBox.shrink();
        }
        return widget.leftPanel;
      },
    );
  }

  Widget _buildLeftRailWrapper() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 60 && !widget.showLeftPanel) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!ref.read(shellLayoutProvider).showLeftPanel) {
              _resetCursor();
              ref.read(shellLayoutProvider.notifier).toggleLeftPanel();
            }
          });
          return const SizedBox.shrink();
        }
        return widget.leftRail;
      },
    );
  }

  Widget _buildRightPanelWrapper() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 100 && widget.showRightPanel) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ref.read(shellLayoutProvider).showRightPanel) {
              _resetCursor();
              ref.read(shellLayoutProvider.notifier).toggleRightPanel();
            }
          });
          return const SizedBox.shrink();
        }
        return widget.rightPanel;
      },
    );
  }

  Widget _buildRightRailWrapper() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 60 && !widget.showRightPanel) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!ref.read(shellLayoutProvider).showRightPanel) {
              _resetCursor();
              ref.read(shellLayoutProvider.notifier).toggleRightPanel();
            }
          });
          return const SizedBox.shrink();
        }
        return widget.rightRail;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final layoutState = ref.watch(shellLayoutProvider);

    // Update vertical areas based on bottom panel visibility
    _verticalController?.areas = _buildVerticalAreas(layoutState.showBottomPanel);

    // Update vertical areas based on bottom panel visibility
    _verticalController?.areas = _buildVerticalAreas(layoutState.showBottomPanel);

    // Build the center vertical stack (Editor + Console)
    Widget centerContent = MultiSplitViewTheme(
      key: const ValueKey('center_vertical_theme'),
      data: MultiSplitViewThemeData(
        dividerThickness: 8,
        dividerPainter: DividerPainters.background(
          color: ui.colors.divider,
          highlightedColor: ui.colors.accent,
        ),
      ),
      child: MultiSplitView(
        key: _verticalKey,
        axis: Axis.vertical,
        controller: _verticalController,
        builder: (context, area) {
          if (area.data == 'main') return widget.centerPanel;
          if (area.data == 'bottom') return widget.bottomPanel;
          return const SizedBox.shrink();
        },
      ),
    );

    return MultiSplitViewTheme(
      key: const ValueKey('main_horizontal_theme'),
      data: MultiSplitViewThemeData(
        dividerThickness: 8,
        dividerPainter: DividerPainters.background(
          color: ui.colors.divider,
          highlightedColor: ui.colors.accent,
        ),
      ),
      child: MultiSplitView(
        key: _horizontalKey,
        controller: _horizontalController,
        builder: (context, area) {
          if (area.data == 'left') return _buildLeftPanelWrapper();
          if (area.data == 'left_rail') return _buildLeftRailWrapper();
          if (area.data == 'center') return centerContent;
          if (area.data == 'right') return _buildRightPanelWrapper();
          if (area.data == 'right_rail') return _buildRightRailWrapper();
          return const SizedBox.shrink();
        },
      ),
    );
  }
}