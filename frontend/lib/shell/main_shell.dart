import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'title_strip.dart';
import 'split_shell.dart';
import '../theme/ui_theme.dart';
import '../features/status_bar/ui/status_bar.dart';
import '../features/editor/ui/editor_stack.dart';
import '../features/ribbon/ui/app_ribbon.dart';
import '../features/workspace/ui/workspace_panel.dart';
import '../features/console/ui/console_dock.dart';
import '../features/explorer/ui/explorer_panel.dart';
import '../core/layout/shell_breakpoints.dart';
import '../core/layout/shell_layout_state.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = UiTheme.of(context);
    
    return Scaffold(
      backgroundColor: ui.colors.panel,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          
          // Determine visibility based on breakpoints and user preference
          final layoutState = ref.watch(shellLayoutProvider);
          final bool showLeft = layoutState.showLeftPanel && !ShellBreakpoints.shouldCollapseLeft(width);
          final bool showRight = layoutState.showRightPanel && !ShellBreakpoints.shouldCollapseRight(width);
          
          return Column(
            children: [
              const TitleStrip(),
              const AppRibbon(),
              Expanded(
                child: Row(
                  children: [
                    if (!showLeft && layoutState.showLeftPanel)
                      _buildCollapsedRail(context, 'Explorer', Icons.folder, () {
                        // Expand action
                      }),
                    Expanded(
                      child: SplitShell(
                        showLeftPanel: showLeft,
                        showRightPanel: showRight,
                        leftPanel: showLeft 
                            ? const ExplorerPanel()
                            : const SizedBox.shrink(),
                        centerPanel: const EditorStack(),
                        rightPanel: showRight
                            ? const WorkspacePanel()
                            : const SizedBox.shrink(),
                        bottomPanel: const ConsoleDock(),
                      ),
                    ),
                    if (!showRight && layoutState.showRightPanel)
                      _buildCollapsedRail(context, 'Workspace', Icons.settings, () {
                        // Expand action
                      }),
                  ],
                ),
              ),
              const AppStatusBar(),
            ],
          );
        }
      ),
    );
  }

  Widget _buildCollapsedRail(BuildContext context, String tooltip, IconData icon, VoidCallback onTap) {
    final ui = UiTheme.of(context);
    return Container(
      width: 48,
      color: ui.colors.panel,
      child: Column(
        children: [
          SizedBox(height: ui.spacing.sm),
          IconButton(
            icon: Icon(icon, size: 20, color: ui.colors.icon),
            onPressed: onTap,
            tooltip: tooltip,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
