import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
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
import '../providers/settings_provider.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = UiTheme.of(context);
    final settings = p.Provider.of<SettingsProvider>(context).settings;
    
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
              if (settings.showToolbar)
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
              if (settings.showStatusBar)
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
      width: 44, // Slightly slimmer
      decoration: BoxDecoration(
        color: ui.colors.panel,
        border: Border(
          right: tooltip == 'Explorer' ? BorderSide(color: ui.colors.divider.withValues(alpha: 0.3)) : BorderSide.none,
          left: tooltip == 'Workspace' ? BorderSide(color: ui.colors.divider.withValues(alpha: 0.3)) : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: ui.spacing.md),
          GestureDetector(
            onTap: onTap,
            child: _RailIcon(icon: icon, tooltip: tooltip, color: ui.colors.accent),
          ),
        ],
      ),
    );
  }
}

class _RailIcon extends StatefulWidget {
  const _RailIcon({required this.icon, required this.tooltip, required this.color});
  final IconData icon;
  final String tooltip;
  final Color color;

  @override
  State<_RailIcon> createState() => _RailIconState();
}

class _RailIconState extends State<_RailIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered ? widget.color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: ui.spacing.radiusSm,
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: _isHovered ? widget.color : ui.colors.textMuted.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
