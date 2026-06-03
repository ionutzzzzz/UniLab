import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShellLayoutState {
  final double leftPanelWidth;
  final double rightPanelWidth;
  final double bottomPanelHeight;
  final bool showLeftPanel;
  final bool showRightPanel;
  final bool showBottomPanel;
  final int layoutId;

  const ShellLayoutState({
    this.leftPanelWidth = 240,
    this.rightPanelWidth = 280,
    this.bottomPanelHeight = 220,
    this.showLeftPanel = true,
    this.showRightPanel = true,
    this.showBottomPanel = true,
    this.layoutId = 0,
  });

  ShellLayoutState copyWith({
    double? leftPanelWidth,
    double? rightPanelWidth,
    double? bottomPanelHeight,
    bool? showLeftPanel,
    bool? showRightPanel,
    bool? showBottomPanel,
    int? layoutId,
  }) {
    return ShellLayoutState(
      leftPanelWidth: leftPanelWidth ?? this.leftPanelWidth,
      rightPanelWidth: rightPanelWidth ?? this.rightPanelWidth,
      bottomPanelHeight: bottomPanelHeight ?? this.bottomPanelHeight,
      showLeftPanel: showLeftPanel ?? this.showLeftPanel,
      showRightPanel: showRightPanel ?? this.showRightPanel,
      showBottomPanel: showBottomPanel ?? this.showBottomPanel,
      layoutId: layoutId ?? this.layoutId,
    );
  }
}

class ShellLayoutNotifier extends Notifier<ShellLayoutState> {
  @override
  ShellLayoutState build() {
    return const ShellLayoutState();
  }

  void updateLeftPanelWidth(double width) {
    state = state.copyWith(leftPanelWidth: width);
  }

  void updateRightPanelWidth(double width) {
    state = state.copyWith(rightPanelWidth: width);
  }

  void updateBottomPanelHeight(double height) {
    state = state.copyWith(bottomPanelHeight: height);
  }

  void toggleLeftPanel() {
    state = state.copyWith(showLeftPanel: !state.showLeftPanel);
  }

  void toggleRightPanel() {
    state = state.copyWith(showRightPanel: !state.showRightPanel);
  }

  void toggleBottomPanel() {
    state = state.copyWith(showBottomPanel: !state.showBottomPanel);
  }

  void setCommandOnlyMode() {
    state = state.copyWith(
      showLeftPanel: false,
      showRightPanel: false,
      showBottomPanel: true,
      layoutId: state.layoutId + 1,
    );
  }

  void resetLayout() {
    // Safely retrieve current ID, protecting against hot-reload nullability bugs
    int currentId = 0;
    try {
      currentId = state.layoutId;
    } catch (_) {}
    
    // Creating a fresh ShellLayoutState resets all panel visibility back to true!
    state = ShellLayoutState(layoutId: currentId + 1);
  }
}

final shellLayoutProvider = NotifierProvider<ShellLayoutNotifier, ShellLayoutState>(
  ShellLayoutNotifier.new,
);
