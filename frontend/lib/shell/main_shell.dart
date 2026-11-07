import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart' as p;
import 'title_strip.dart';
import 'split_shell.dart';
import 'package:unilab/theme/ui_theme.dart';
import 'package:unilab/features/status_bar/ui/status_bar.dart';
import 'package:unilab/features/editor/ui/editor_stack.dart';
import 'package:unilab/features/ribbon/ui/app_ribbon.dart';
import 'package:unilab/features/workspace/ui/workspace_panel.dart';
import 'package:unilab/features/console/ui/console_dock.dart';
import 'package:unilab/features/explorer/ui/explorer_panel.dart';
import 'package:flutter/foundation.dart';
import 'package:unilab/features/command_palette/ui/command_palette.dart';
import 'package:unilab/core/layout/shell_layout_state.dart';
import 'package:unilab/providers/settings_provider.dart';
import 'package:unilab/providers/app_provider.dart';
import 'package:unilab/models/models.dart';
import 'package:unilab/features/welcome/ui/welcome_screen.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = UiTheme.of(context);
    final settings = context.select<SettingsProvider, UserSettings>((s) => s.settings);
    final isWelcomeMode = context.select<AppProvider, bool>((p) => p.isWelcomeMode);

    if (isWelcomeMode) {
      return const WelcomeScreen();
    }
    
    final appProvider = context.read<AppProvider>();
    final isMac = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

    Map<ShortcutActivator, VoidCallback> shortcuts = {
      // Command palette: Ctrl/Cmd+Shift+P and Ctrl/Cmd+K
      SingleActivator(LogicalKeyboardKey.keyP, control: !isMac, meta: isMac, shift: true): () {
        CommandPalette.show(context);
      },
      SingleActivator(LogicalKeyboardKey.keyK, control: !isMac, meta: isMac): () {
        CommandPalette.show(context);
      },
      // Save: Ctrl/Cmd+S
      SingleActivator(LogicalKeyboardKey.keyS, control: !isMac, meta: isMac): () {
        appProvider.saveActiveFile();
      },
      // Save As: Ctrl/Cmd+Shift+S
      SingleActivator(LogicalKeyboardKey.keyS, control: !isMac, meta: isMac, shift: true): () {
        appProvider.triggerEditorAction('file.saveAs');
      },
      // New: Ctrl/Cmd+N
      SingleActivator(LogicalKeyboardKey.keyN, control: !isMac, meta: isMac): () {
        appProvider.addNewFile();
      },
      // Close tab: Ctrl/Cmd+W
      SingleActivator(LogicalKeyboardKey.keyW, control: !isMac, meta: isMac): () {
        if (appProvider.activeFileIndex >= 0) {
          appProvider.closeFile(appProvider.activeFileIndex);
        }
      },
      // Run: F5 or Ctrl/Cmd+Enter
      const SingleActivator(LogicalKeyboardKey.f5): () {
        appProvider.runActiveFile();
      },
      SingleActivator(LogicalKeyboardKey.enter, control: !isMac, meta: isMac): () {
        appProvider.runActiveFile();
      },
      // Undo: Ctrl/Cmd+Z
      SingleActivator(LogicalKeyboardKey.keyZ, control: !isMac, meta: isMac): () {
        appProvider.triggerEditorAction('editor.undo');
      },
      // Redo: Ctrl/Cmd+Y or Ctrl/Cmd+Shift+Z
      SingleActivator(LogicalKeyboardKey.keyY, control: !isMac, meta: isMac): () {
        appProvider.triggerEditorAction('editor.redo');
      },
      SingleActivator(LogicalKeyboardKey.keyZ, control: !isMac, meta: isMac, shift: true): () {
        appProvider.triggerEditorAction('editor.redo');
      },
      // Find: Ctrl/Cmd+F
      SingleActivator(LogicalKeyboardKey.keyF, control: !isMac, meta: isMac): () {
        appProvider.triggerEditorAction('editor.find');
      },
      // Replace: Ctrl/Cmd+H
      SingleActivator(LogicalKeyboardKey.keyH, control: !isMac, meta: isMac): () {
        appProvider.triggerEditorAction('editor.replace');
      },
    };

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: ui.colors.panel,
          body: LayoutBuilder(
            builder: (context, constraints) {
              // Determine visibility based on user preference and active layout state
              final layoutState = ref.watch(shellLayoutProvider);
              final bool showLeft = layoutState.showLeftPanel;
              final bool showRight = layoutState.showRightPanel;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TitleStrip(),
                  if (settings.showToolbar)
                    const AppRibbon(),
                  Expanded(
                    child: SplitShell(
                      key: ValueKey('split_shell_${layoutState.layoutId}'),
                      showLeftPanel: showLeft,
                      showRightPanel: showRight,
                      leftPanel: const ExplorerPanel(),
                      leftRail: _buildSideRail(context, 'Explorer', LucideIcons.folder, showLeft, () {
                        ref.read(shellLayoutProvider.notifier).toggleLeftPanel();
                      }),
                      centerPanel: const EditorStack(),
                      rightPanel: const WorkspacePanel(),
                      rightRail: _buildSideRail(context, 'Workspace', LucideIcons.layoutGrid, showRight, () {
                        ref.read(shellLayoutProvider.notifier).toggleRightPanel();
                      }, isRight: true),
                      bottomPanel: const ConsoleDock(),
                    ),
                  ),
                  if (settings.showStatusBar)
                    const AppStatusBar(),
                ],
              );
            },
          ),
        ),
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
        crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          SizedBox(height: ui.spacing.md),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ui.spacing.xs),
            child: _RailIcon(
              icon: icon, 
              tooltip: tooltip, 
              color: ui.colors.accent,
              isActive: isActive,
              onTap: onTap,
            ),
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
