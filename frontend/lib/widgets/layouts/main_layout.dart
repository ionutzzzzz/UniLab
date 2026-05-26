import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../panels/file_browser_panel.dart';
import '../panels/editor_panel.dart';
import '../panels/workspace_panel.dart';
import '../panels/console_panel.dart';

class MainLayout extends StatefulWidget {
  final Function(String)? onPanelVisibilityChanged;

  const MainLayout({
    super.key,
    this.onPanelVisibilityChanged,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late MultiSplitViewController _mainController;
  late MultiSplitViewController _editorController;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
    
    // Initialize controllers based on settings
    final leftPanelFlex = settings.panelSizes['leftPanel'] ?? 0.15;
    final rightPanelFlex = settings.panelSizes['rightPanel'] ?? 0.20;
    final centerFlex = 1 - leftPanelFlex - rightPanelFlex;

    _mainController = MultiSplitViewController(areas: [
      // Left Panel - File Browser
      Area(
        flex: leftPanelFlex,
        min: 0.1,
        max: 0.4,
        builder: (context, area) => const FileBrowserPanel(),
      ),
      // Center - Editor & Console
      Area(
        flex: centerFlex,
        builder: (context, area) => _buildEditorAndConsole(),
      ),
      // Right Panel - Workspace
      Area(
        flex: rightPanelFlex,
        min: 0.15,
        max: 0.5,
        builder: (context, area) => const WorkspacePanel(),
      ),
    ]);

    _editorController = MultiSplitViewController(areas: [
      Area(
        flex: 0.7,
        min: 0.3,
        builder: (context, area) => const EditorPanel(),
      ),
      Area(
        flex: 0.3,
        min: 0.2,
        builder: (context, area) => const ConsolePanel(),
      ),
    ]);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _editorController.dispose();
    super.dispose();
  }

  Widget _buildEditorAndConsole() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        return MultiSplitViewTheme(
          data: MultiSplitViewThemeData(
            dividerPainter: DividerPainters.background(
              color: Theme.of(context).dividerColor,
              highlightedColor: Theme.of(context).primaryColor,
            ),
            dividerThickness: 4,
          ),
          child: MultiSplitView(
            axis: Axis.vertical,
            controller: _editorController,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        return MultiSplitViewTheme(
          data: MultiSplitViewThemeData(
            dividerPainter: DividerPainters.background(
              color: Theme.of(context).dividerColor,
              highlightedColor: Theme.of(context).primaryColor,
            ),
            dividerThickness: 4,
          ),
          child: MultiSplitView(
            controller: _mainController,
          ),
        );
      },
    );
  }
}
