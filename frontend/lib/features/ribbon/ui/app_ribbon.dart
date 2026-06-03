import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart' as p;
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../core/commands/command.dart';
import '../../../core/commands/commands_registration.dart';
import '../../../core/layout/shell_layout_state.dart';
import '../../../theme/plot_colormaps.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/app_provider.dart';
import 'ribbon_tab_bar.dart';
import 'ribbon_body.dart';
import 'ribbon_group.dart';
import 'ribbon_button.dart';
import 'quick_access_bar.dart';
import '../../../widgets/ui_button.dart';
import 'backstage/file_backstage.dart';

class AppRibbon extends ConsumerStatefulWidget {
  const AppRibbon({super.key});

  @override
  ConsumerState<AppRibbon> createState() => _AppRibbonState();
}

class _AppRibbonState extends ConsumerState<AppRibbon> {
  String _activeTab = 'HOME';
  bool _isCollapsed = false;
  bool _isFileHovered = false;

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

  void _showColormapPicker(BuildContext context) {
    final ui = UiTheme.of(context);
    final provider = p.Provider.of<SettingsProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        title: UiText(text: 'Select Plot Colormap', variant: UiTextVariant.body, fontWeight: FontWeight.bold),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: PlotColormap.all.length,
            itemBuilder: (context, index) {
              final map = PlotColormap.all[index];
              final isSelected = provider.settings.plotColormap == map.name;
              
              return InkWell(
                onTap: () {
                  provider.updateSettings(provider.settings.copyWith(plotColormap: map.name));
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? ui.colors.accent.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: ui.spacing.radiusSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UiText(
                        text: map.name, 
                        variant: UiTextVariant.label, 
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? ui.colors.accent : ui.colors.textPrimary,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: map.colors.map((c) => Expanded(
                          child: Container(height: 12, color: c),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          UiButton(label: 'Close', variant: UiButtonVariant.ghost, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  void _showNewScriptMenu(BuildContext context) {
    final ui = UiTheme.of(context);
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: ui.colors.panel,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: ui.colors.border),
      ),
      items: [
        PopupMenuItem(value: 'Script (.m)', child: Text('Script (.m)', style: TextStyle(color: ui.colors.textPrimary, fontSize: 13))),
        PopupMenuItem(value: 'Function (.m)', child: Text('Function (.m)', style: TextStyle(color: ui.colors.textPrimary, fontSize: 13))),
        PopupMenuItem(value: 'Live Script (.mlx)', child: Text('Live Script (.mlx)', style: TextStyle(color: ui.colors.textPrimary, fontSize: 13))),
      ],
    ).then((value) {
      if (value != null) {
        _showNameDialog(context, value);
      }
    });
  }

  void _showNameDialog(BuildContext context, String selectedType) {
    final ui = UiTheme.of(context);
    final appProvider = p.Provider.of<AppProvider>(context, listen: false);
    final controller = TextEditingController(text: 'Untitled');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ui.colors.panel,
          surfaceTintColor: Colors.transparent,
          title: UiText(text: 'New $selectedType', variant: UiTextVariant.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UiText(text: 'Script Name', variant: UiTextVariant.label, color: ui.colors.textMuted),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                style: TextStyle(color: ui.colors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: ui.colors.canvas,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: ui.colors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: ui.colors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: ui.colors.accent),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: UiText(text: 'Cancel', color: ui.colors.textMuted),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text;
                if (name.isNotEmpty) {
                  String ext = selectedType.contains('.mlx') ? '.mlx' : '.m';
                  String fileName = name.endsWith(ext) ? name : '$name$ext';
                  String content = '';
                  if (selectedType.contains('Function')) {
                     String funcName = fileName.replaceAll(ext, '');
                     content = 'function [outputArg1,outputArg2] = $funcName(inputArg1,inputArg2)\n% $funcName Summary of this function goes here\n%   Detailed explanation goes here\n\nend';
                  } else if (selectedType.contains('Live Script')) {
                     content = '%% Live Script\n% Add your live script content here.\n';
                  }
                  
                  await appProvider.createProjectFile(fileName, content);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: UiText(text: 'Create', color: ui.colors.accent, fontWeight: FontWeight.bold),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final registry = ref.watch(commandRegistryProvider);
    final appProvider = p.Provider.of<AppProvider>(context);
    
    final cmdRun = registry.get('run.run');
    final cmdStop = registry.get('run.stop');

    List<RibbonGroup> activeGroups = [];

    if (_activeTab == 'HOME') {
      activeGroups = [
        RibbonGroup(
          title: 'Environment',
          children: [
            Builder(
              builder: (context) => RibbonButton(
                label: 'New Script',
                icon: LucideIcons.filePlus2,
                isLarge: true,
                hasDropdown: true,
                onTap: () => _showNewScriptMenu(context),
              ),
            ),
            RibbonButton(
              label: 'Open Folder',
              icon: LucideIcons.folderInput,
              onTap: () => appProvider.openFolderPicker(),
            ),
            RibbonButton(
              label: 'Import Data',
              icon: LucideIcons.database,
              onTap: () => appProvider.openImportDataTab(),
            ),
          ],
        ),
        RibbonGroup(
          title: 'Execution',
          children: [
            RibbonButton(
              label: 'Run Script',
              icon: LucideIcons.playCircle,
              isLarge: true,
              loading: appProvider.isExecuting,
              onTap: cmdRun != null ? () => cmdRun.run(CommandContext(context)) : null,
            ),
            RibbonButton(
              label: 'Debug',
              icon: LucideIcons.bug,
              onTap: () {},
            ),
            RibbonButton(
              label: 'Stop',
              icon: LucideIcons.stopCircle,
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
              onTap: () {
                ref.read(shellLayoutProvider.notifier).resetLayout();
              },
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
            RibbonButton(
              label: 'Find & Replace', 
              icon: LucideIcons.searchCode, 
              isLarge: true, 
              onTap: () => appProvider.triggerEditorAction('editor.find'),
            ),
            RibbonButton(
              label: 'Go to Line', 
              icon: LucideIcons.hash, 
              onTap: () => appProvider.triggerEditorAction('editor.gotoLine'),
            ),
          ],
        ),
        RibbonGroup(
          title: 'Format',
          children: [
            RibbonButton(label: 'Auto Indent', icon: LucideIcons.indent),
            RibbonButton(label: 'Comment', icon: LucideIcons.messageSquare),
          ],
        ),
      ];
    } else if (_activeTab == 'PLOTS') {
      activeGroups = [
        RibbonGroup(
          title: 'Export',
          children: [
            RibbonButton(label: 'Snapshot', icon: LucideIcons.camera, isLarge: true, onTap: () {}),
            RibbonButton(label: 'Export PDF', icon: LucideIcons.fileType, onTap: () {}),
          ],
        ),
        RibbonGroup(
          title: 'Visuals',
          children: [
            RibbonButton(label: 'Grid', icon: LucideIcons.grid3X3, onTap: () {}),
            RibbonButton(label: 'Labels', icon: LucideIcons.type, onTap: () {}),
            RibbonButton(label: 'Legend', icon: LucideIcons.list, onTap: () {}),
            RibbonButton(
              label: 'Color Theme', 
              icon: LucideIcons.palette, 
              onTap: () => _showColormapPicker(context),
            ),
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
            RibbonButton(
              label: 'Import Data', 
              icon: LucideIcons.databaseBackup,
              onTap: () => appProvider.openImportDataTab(),
            ),
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
            RibbonButton(label: 'Split Editor', icon: LucideIcons.columns),
            RibbonButton(
              label: 'New Window', 
              icon: LucideIcons.externalLink,
              onTap: () => appProvider.openDetachedPlotsWindow(),
            ),
          ],
        ),
      ];
    } else if (_activeTab == 'HELP') {
      activeGroups = [
        RibbonGroup(
          title: 'Documentation',
          children: [
            RibbonButton(label: 'Get Started', icon: LucideIcons.rocket, isLarge: true),
            RibbonButton(label: 'User Guide', icon: LucideIcons.bookOpen, isLarge: true),
            RibbonButton(label: 'Examples', icon: LucideIcons.scrollText),
          ],
        ),
        RibbonGroup(
          title: 'Resources',
          children: [
            RibbonButton(label: 'Forum', icon: LucideIcons.users),
            RibbonButton(label: 'Updates', icon: LucideIcons.refreshCw),
          ],
        ),
        RibbonGroup(
          title: 'UniLab',
          children: [
            RibbonButton(label: 'About', icon: LucideIcons.info),
            RibbonButton(label: 'Licenses', icon: LucideIcons.copyright),
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
                color: Colors.black.withValues(alpha: 0.4),
                width: ui.spacing.strokeHair,
              ),
            ),
          ),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => FileBackstage.show(context),
                  onHover: (hovered) => setState(() => _isFileHovered = hovered),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 34,
                    padding: EdgeInsets.symmetric(horizontal: ui.spacing.lg),
                    decoration: BoxDecoration(
                      color: _isFileHovered ? ui.colors.accent : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UiText(
                          text: 'FILE',
                          variant: UiTextVariant.label,
                          color: _isFileHovered ? ui.colors.textInverse : ui.colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronDown, 
                          size: 14, 
                          color: _isFileHovered ? ui.colors.textInverse : ui.colors.textPrimary
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: RibbonTabBar(
                  tabs: const ['HOME', 'EDITOR', 'PLOTS', 'ANALYZE', 'VIEW', 'HELP'],
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
                color: Colors.black.withValues(alpha: 0.1),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ui.colors.panelHeader,
                ui.colors.panelHeader.withValues(alpha: 0.9),
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
