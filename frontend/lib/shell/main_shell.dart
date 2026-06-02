import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
          
          // Determine visibility based on user preference and active layout state
          final layoutState = ref.watch(shellLayoutProvider);
          final bool showLeft = layoutState.showLeftPanel;
          final bool showRight = layoutState.showRightPanel;
          
          return Column(
            children: [
              const TitleStrip(),
              if (settings.showToolbar)
                const AppRibbon(),
              Expanded(
                child: Row(
                  children: [
                    _buildSideRail(context, 'Explorer', LucideIcons.folder, showLeft, () {
                      ref.read(shellLayoutProvider.notifier).toggleLeftPanel();
                    }),
                    Expanded(
                      child: SplitShell(
                        showLeftPanel: showLeft,
                        showRightPanel: showRight,
                        leftPanel: const ExplorerPanel(),
                        centerPanel: const EditorStack(),
                        rightPanel: const WorkspacePanel(),
                        bottomPanel: const ConsoleDock(),
                      ),
                    ),
                    _buildSideRail(context, 'Workspace', LucideIcons.layoutGrid, showRight, () {
                      ref.read(shellLayoutProvider.notifier).toggleRightPanel();
                    }, isRight: true),
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

  Widget _buildSideRail(BuildContext context, String tooltip, IconData icon, bool isActive, VoidCallback onTap, {bool isRight = false}) {
    final ui = UiTheme.of(context);
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: ui.colors.panel,
        border: Border(
          right: !isRight ? BorderSide(color: ui.colors.divider.withValues(alpha: 0.5)) : BorderSide.none,
          left: isRight ? BorderSide(color: ui.colors.divider.withValues(alpha: 0.5)) : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: ui.spacing.md),
          _RailIcon(
            icon: icon, 
            tooltip: tooltip, 
            color: ui.colors.accent,
            isActive: isActive,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _RailIcon extends StatefulWidget {
  const _RailIcon({
    required this.icon, 
    required this.tooltip, 
    required this.color,
    required this.isActive,
    required this.onTap,
  });
  
  final IconData icon;
  final String tooltip;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

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
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.isActive 
                  ? widget.color.withValues(alpha: 0.15) 
                  : (_isHovered ? widget.color.withValues(alpha: 0.08) : Colors.transparent),
              borderRadius: ui.spacing.radiusSm,
              border: Border.all(
                color: widget.isActive 
                    ? widget.color.withValues(alpha: 0.3) 
                    : Colors.transparent,
                width: 1.0,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: widget.isActive 
                  ? widget.color 
                  : (_isHovered ? widget.color : ui.colors.textMuted.withValues(alpha: 0.8)),
            ),
          ),
        ),
      ),
    );
  }
}
