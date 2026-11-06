import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShellLayoutState {
  final double leftPanelWidth;
  final double rightPanelWidth;
  final double bottomPanelHeight;
  final bool showLeftPanel;
  final bool showRightPanel;
  final bool showBottomPanel;
  final bool isCommandOnlyMode;
  final int layoutId;

  const ShellLayoutState({
    this.leftPanelWidth = 240,
    this.rightPanelWidth = 280,
    this.bottomPanelHeight = 220,
    this.showLeftPanel = true,
    this.showRightPanel = true,
    this.showBottomPanel = true,
    this.isCommandOnlyMode = false,
    this.layoutId = 0,
  });

  ShellLayoutState copyWith({
    double? leftPanelWidth,
    double? rightPanelWidth,
    double? bottomPanelHeight,
    bool? showLeftPanel,
    bool? showRightPanel,
    bool? showBottomPanel,
    bool? isCommandOnlyMode,
    int? layoutId,
  }) {
    return ShellLayoutState(
      leftPanelWidth: leftPanelWidth ?? this.leftPanelWidth,
      rightPanelWidth: rightPanelWidth ?? this.rightPanelWidth,
      bottomPanelHeight: bottomPanelHeight ?? this.bottomPanelHeight,
      showLeftPanel: showLeftPanel ?? this.showLeftPanel,
      showRightPanel: showRightPanel ?? this.showRightPanel,
      showBottomPanel: showBottomPanel ?? this.showBottomPanel,
      isCommandOnlyMode: isCommandOnlyMode ?? this.isCommandOnlyMode,
      layoutId: layoutId ?? this.layoutId,
    );
  }
}

class ShellLayoutNotifier extends Notifier<ShellLayoutState> {
  @override
  ShellLayoutState build() {
    _loadSavedLayout();
    return const ShellLayoutState();
  }

  Future<void> _loadSavedLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool('rememberLayout') ?? true;
      if (!remember) return;

      final showLeft = prefs.getBool('shell_show_left') ?? true;
      final showRight = prefs.getBool('shell_show_right') ?? true;
      final showBottom = prefs.getBool('shell_show_bottom') ?? true;
      final cmdOnly = prefs.getBool('shell_cmd_only') ?? false;
      final leftWidth = prefs.getDouble('shell_left_width') ?? 240;
      final rightWidth = prefs.getDouble('shell_right_width') ?? 280;
      final bottomHeight = prefs.getDouble('shell_bottom_height') ?? 220;

      state = ShellLayoutState(
        showLeftPanel: showLeft,
        showRightPanel: showRight,
        showBottomPanel: showBottom,
        isCommandOnlyMode: cmdOnly,
        leftPanelWidth: leftWidth,
        rightPanelWidth: rightWidth,
        bottomPanelHeight: bottomHeight,
        layoutId: state.layoutId + 1,
      );
    } catch (_) {}
  }

  Future<void> _persistLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool('rememberLayout') ?? true;
      if (!remember) return;

      await prefs.setBool('shell_show_left', state.showLeftPanel);
      await prefs.setBool('shell_show_right', state.showRightPanel);
      await prefs.setBool('shell_show_bottom', state.showBottomPanel);
      await prefs.setBool('shell_cmd_only', state.isCommandOnlyMode);
      await prefs.setDouble('shell_left_width', state.leftPanelWidth);
      await prefs.setDouble('shell_right_width', state.rightPanelWidth);
      await prefs.setDouble('shell_bottom_height', state.bottomPanelHeight);
    } catch (_) {}
  }

  void updateLeftPanelWidth(double width) {
    state = state.copyWith(leftPanelWidth: width);
    _persistLayout();
  }

  void updateRightPanelWidth(double width) {
    state = state.copyWith(rightPanelWidth: width);
    _persistLayout();
  }

  void updateBottomPanelHeight(double height) {
    state = state.copyWith(bottomPanelHeight: height);
    _persistLayout();
  }

  void toggleLeftPanel() {
    state = state.copyWith(
      showLeftPanel: !state.showLeftPanel,
      isCommandOnlyMode: false,
    );
    _persistLayout();
  }

  void toggleRightPanel() {
    state = state.copyWith(
      showRightPanel: !state.showRightPanel,
      isCommandOnlyMode: false,
    );
    _persistLayout();
  }

  void toggleBottomPanel() {
    state = state.copyWith(showBottomPanel: !state.showBottomPanel);
    _persistLayout();
  }

  void setCommandOnlyMode() {
    state = state.copyWith(
      showLeftPanel: false,
      showRightPanel: false,
      showBottomPanel: true,
      isCommandOnlyMode: true,
      layoutId: state.layoutId + 1,
    );
    _persistLayout();
  }

  void resetLayout() {
    int currentId = 0;
    try {
      currentId = state.layoutId;
    } catch (_) {}
    state = ShellLayoutState(layoutId: currentId + 1);
    _persistLayout();
  }
}

final shellLayoutProvider =
    NotifierProvider<ShellLayoutNotifier, ShellLayoutState>(
  ShellLayoutNotifier.new,
);
