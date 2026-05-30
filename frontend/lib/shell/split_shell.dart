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
  late MultiSplitViewController _horizontalController;
  late MultiSplitViewController _verticalController;

  @override
  void initState() {
    super.initState();
    _horizontalController = MultiSplitViewController(areas: [
      Area(flex: 0.2, min: 150, data: 'left'),
      Area(flex: 0.6, min: 300, data: 'center'),
      Area(flex: 0.2, min: 200, data: 'right'),
    ]);
    
    _verticalController = MultiSplitViewController(areas: [
      Area(flex: 0.7, min: 200, data: 'main'),
      Area(flex: 0.3, min: 100, data: 'bottom'),
    ]);
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final layoutState = ref.watch(shellLayoutProvider);

    // Update horizontal controller areas based on visibility
    List<Area> horizAreas = [];
    if (widget.showLeftPanel) horizAreas.add(Area(flex: 0.2, min: 150, data: 'left'));
    horizAreas.add(Area(flex: 0.6, min: 300, data: 'center'));
    if (widget.showRightPanel) horizAreas.add(Area(flex: 0.2, min: 200, data: 'right'));
    
    // NOTE: In a real app we'd preserve sizes instead of resetting flex.
    // For now we just recreate the controller when visibility changes (or modify areas).
    // The simple way is to pass a new controller if we want to change areas dynamically
    // but multi_split_view might allow modifying areas.
    
    Widget mainHorizontalSplit = MultiSplitView(
      controller: MultiSplitViewController(areas: horizAreas),
      builder: (context, area) {
        if (area.data == 'left') return widget.leftPanel;
        if (area.data == 'center') return widget.centerPanel;
        if (area.data == 'right') return widget.rightPanel;
        return const SizedBox.shrink();
      },
      dividerBuilder: (axis, index, resizable, dragging, highlighted, themeData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: dragging || highlighted 
              ? ui.colors.accent.withOpacity(0.8) 
              : ui.colors.divider.withOpacity(0.4),
          child: Center(
            child: Container(
              width: axis == Axis.vertical ? 24 : 1,
              height: axis == Axis.vertical ? 1 : 24,
              decoration: BoxDecoration(
                color: dragging || highlighted 
                    ? Colors.white.withOpacity(0.5) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
      },
    );

    MultiSplitViewTheme mainTheme = MultiSplitViewTheme(
      data: MultiSplitViewThemeData(
        dividerThickness: 4, // Slightly thicker for easier grabbing, but thin visual line
      ),
      child: mainHorizontalSplit,
    );

    if (!layoutState.showBottomPanel) {
      return mainTheme;
    }

    return MultiSplitViewTheme(
      data: MultiSplitViewThemeData(
        dividerThickness: 4,
      ),
      child: MultiSplitView(
        axis: Axis.vertical,
        controller: _verticalController,
        builder: (context, area) {
          if (area.data == 'main') return mainTheme;
          if (area.data == 'bottom') return widget.bottomPanel;
          return const SizedBox.shrink();
        },
        dividerBuilder: (axis, index, resizable, dragging, highlighted, themeData) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: dragging || highlighted 
                ? ui.colors.accent.withOpacity(0.8) 
                : ui.colors.divider.withOpacity(0.4),
            child: Center(
              child: Container(
                width: axis == Axis.vertical ? 24 : 1,
                height: axis == Axis.vertical ? 1 : 24,
                decoration: BoxDecoration(
                  color: dragging || highlighted 
                      ? Colors.white.withOpacity(0.5) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}