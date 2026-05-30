import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../core/commands/command.dart';
import '../../../core/commands/commands_registration.dart';
import 'ribbon_tab_bar.dart';
import 'ribbon_body.dart';
import 'ribbon_group.dart';
import 'ribbon_button.dart';
import 'quick_access_bar.dart';

class AppRibbon extends ConsumerStatefulWidget {
  const AppRibbon({super.key});

  @override
  ConsumerState<AppRibbon> createState() => _AppRibbonState();
}

class _AppRibbonState extends ConsumerState<AppRibbon> {
  String _activeTab = 'HOME';
  bool _isCollapsed = false;

  void _onTabTap(String tab) {
    if (_isCollapsed && _activeTab == tab) {
      setState(() => _isCollapsed = false);
    } else {
      setState(() {
        _activeTab = tab;
        _isCollapsed = false;
      });
    }
  }

  void _onDoubleTap() {
    setState(() => _isCollapsed = !_isCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final registry = ref.watch(commandRegistryProvider);
    
    final cmdRun = registry.get('run.run');
    final cmdStop = registry.get('run.stop');

    List<RibbonGroup> activeGroups = [];

    if (_activeTab == 'HOME') {
      activeGroups = [
        RibbonGroup(
          title: 'Environment',
          children: [
            RibbonButton(
              label: 'New Script',
              icon: LucideIcons.filePlus2,
              isLarge: true,
              onTap: () {},
            ),
            RibbonButton(
              label: 'Open Folder',
              icon: LucideIcons.folderInput,
              onTap: () {},
            ),
            RibbonButton(
              label: 'Import Data',
              icon: LucideIcons.database,
              color: ui.colors.tan,
              onTap: () {},
            ),
          ],
        ),
        RibbonGroup(
          title: 'Execution',
          children: [
            RibbonButton(
              label: 'Run Script',
              icon: LucideIcons.playCircle,
              color: ui.colors.success,
              isLarge: true,
              onTap: cmdRun != null ? () => cmdRun.run(CommandContext(context)) : null,
            ),
            RibbonButton(
              label: 'Debug',
              icon: LucideIcons.bug,
              color: ui.colors.yellow,
              onTap: () {},
            ),
            RibbonButton(
              label: 'Stop',
              icon: LucideIcons.stopCircle,
              color: ui.colors.danger,
              onTap: cmdStop != null ? () => cmdStop.run(CommandContext(context)) : null,
            ),
          ],
        ),
        RibbonGroup(
          title: 'Management',
          children: [
            RibbonButton(
              label: 'Clear Workspace',
              icon: LucideIcons.eraser,
              onTap: () {},
            ),
          ],
        ),
        RibbonGroup(
          title: 'Layout',
          children: [
            RibbonButton(
              label: 'Reset Layout',
              icon: LucideIcons.layoutTemplate,
              color: ui.colors.tan,
              onTap: () {},
            ),
            RibbonButton(
              label: 'Command Only',
              icon: LucideIcons.maximize,
              onTap: () {},
            ),
          ],
        ),
      ];
    } else if (_activeTab == 'EDITOR') {
      activeGroups = [
        RibbonGroup(
          title: 'Edit',
          children: [
            RibbonButton(label: 'Find & Replace', icon: LucideIcons.searchCode, isLarge: true, onTap: () {}),
            RibbonButton(label: 'Go to Line', icon: LucideIcons.hash, onTap: () {}),
          ],
        ),
        RibbonGroup(
          title: 'Format',
          children: [
            RibbonButton(label: 'Auto Indent', icon: LucideIcons.indent, color: ui.colors.tan),
            RibbonButton(label: 'Comment', icon: LucideIcons.messageSquare, color: ui.colors.accent),
          ],
        ),
      ];
    } else if (_activeTab == 'PLOTS') {
      activeGroups = [
        RibbonGroup(
          title: 'Export',
          children: [
            RibbonButton(label: 'Snapshot', icon: LucideIcons.camera, color: ui.colors.success, isLarge: true, onTap: () {}),
            RibbonButton(label: 'Export PDF', icon: LucideIcons.fileType, color: ui.colors.danger, onTap: () {}),
          ],
        ),
        RibbonGroup(
          title: 'Visuals',
          children: [
            RibbonButton(label: 'Grid Lines', icon: LucideIcons.grid3X3, color: ui.colors.accent),
            RibbonButton(label: 'Color Theme', icon: LucideIcons.palette, color: ui.colors.yellow),
          ],
        ),
      ];
    } else if (_activeTab == 'ANALYZE') {
      activeGroups = [
        RibbonGroup(
          title: 'Simulation',
          children: [
            RibbonButton(label: 'Profiler', icon: LucideIcons.gauge, isLarge: true, onTap: () {}),
            RibbonButton(label: 'Dependency Map', icon: LucideIcons.network, onTap: () {}),
          ],
        ),
        RibbonGroup(
          title: 'Data',
          children: [
            RibbonButton(label: 'Import Data', icon: LucideIcons.databaseBackup),
            RibbonButton(label: 'Variable Stat', icon: LucideIcons.barChart4),
          ],
        ),
      ];
    } else if (_activeTab == 'VIEW') {
      activeGroups = [
        RibbonGroup(
          title: 'Panels',
          children: [
            RibbonButton(label: 'Files', icon: LucideIcons.folder, isLarge: true),
            RibbonButton(label: 'Workspace', icon: LucideIcons.box, isLarge: true),
            RibbonButton(label: 'Console', icon: LucideIcons.terminal, isLarge: true),
          ],
        ),
        RibbonGroup(
          title: 'Window',
          children: [
            RibbonButton(label: 'Split Editor', icon: LucideIcons.columns, color: ui.colors.accent),
            RibbonButton(label: 'New Window', icon: LucideIcons.externalLink, color: ui.colors.success),
          ],
        ),
      ];
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: ui.colors.ribbonTabs,
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withOpacity(0.4),
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  child: Container(
                    height: 34,
                    padding: EdgeInsets.symmetric(horizontal: ui.spacing.lg),
                    decoration: BoxDecoration(
                      color: ui.colors.accent.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                          color: ui.colors.accent.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const UiText(
                          text: 'FILE',
                          variant: UiTextVariant.label,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, size: 14, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: RibbonTabBar(
                  tabs: const ['HOME', 'EDITOR', 'PLOTS', 'ANALYZE', 'VIEW'],
                  activeTab: _activeTab,
                  onTabTap: _onTabTap,
                  onDoubleTap: _onDoubleTap,
                ),
              ),
              const QuickAccessBar(),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: ui.colors.panelHeader,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ui.colors.panelHeader,
                ui.colors.panelHeader.withOpacity(0.9),
              ],
            ),
          ),
          child: RibbonBody(
            groups: activeGroups,
            isCollapsed: _isCollapsed,
          ),
        ),
      ],
    );
  }
}
