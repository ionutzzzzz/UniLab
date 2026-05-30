import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
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
    
    // We fetch commands by ID
    final cmdRun = registry.get('run.run');
    final cmdStop = registry.get('run.stop');
    final cmdNew = registry.get('file.new');
    final cmdOpen = registry.get('file.open');
    final cmdSave = registry.get('file.save');

    List<RibbonGroup> activeGroups = [];

    if (_activeTab == 'HOME') {
      activeGroups = [
        RibbonGroup(
          title: 'Run',
          children: [
            RibbonButton(
              label: 'Run',
              icon: cmdRun?.icon ?? LucideIcons.play,
              isPrimary: true,
              onTap: cmdRun != null ? () => cmdRun.run(CommandContext(context)) : null,
            ),
            RibbonButton(
              label: 'Stop',
              icon: cmdStop?.icon ?? LucideIcons.square,
              onTap: cmdStop != null ? () => cmdStop.run(CommandContext(context)) : null,
            ),
          ],
        ),
        RibbonGroup(
          title: 'File',
          children: [
            RibbonButton(
              label: 'New',
              icon: cmdNew?.icon ?? LucideIcons.filePlus,
              onTap: cmdNew != null ? () => cmdNew.run(CommandContext(context)) : null,
            ),
            RibbonButton(
              label: 'Open',
              icon: cmdOpen?.icon ?? LucideIcons.folderOpen,
              onTap: cmdOpen != null ? () => cmdOpen.run(CommandContext(context)) : null,
            ),
            RibbonButton(
              label: 'Save',
              icon: cmdSave?.icon ?? LucideIcons.save,
              onTap: cmdSave != null ? () => cmdSave.run(CommandContext(context)) : null,
            ),
          ],
        ),
      ];
    } else if (_activeTab == 'EDITOR') {
      activeGroups = [
        RibbonGroup(
          title: 'Navigate',
          children: [
            RibbonButton(label: 'Go to', icon: LucideIcons.arrowRightCircle, onTap: () {}),
          ],
        ),
      ];
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: ui.colors.ribbonTabs,
          child: Row(
            children: [
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
        RibbonBody(
          groups: activeGroups,
          isCollapsed: _isCollapsed,
        ),
      ],
    );
  }
}
