import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart' as p;
import '../../../utils/platform_io.dart';
import 'package:path/path.dart' as p;
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../core/commands/command.dart';
import '../../../core/commands/commands_registration.dart';
import '../../../core/layout/shell_layout_state.dart';
import '../../../theme/plot_colormaps.dart';
import '../../../theme/syntax_themes.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/app_provider.dart';
import '../../../bridge/unilab_bridge.dart';
import '../../workspace/ui/toolbox_view.dart';
import 'ribbon_tab_bar.dart';
import 'ribbon_body.dart';
import 'ribbon_group.dart';
import 'ribbon_button.dart';
import 'quick_access_bar.dart';
import '../../../widgets/ui_button.dart';
import 'backstage/file_backstage.dart';
import '../../simulation/services/simulation_controller.dart';
import '../../simulation/ui/simulation_catalog_dialog.dart';

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
    if (tab == 'SIMULATION') {
      context.read<AppProvider>().openSimulationStudio();
    }
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

  void _showThemePicker(BuildContext context) {
    final ui = UiTheme.of(context);
    final provider = p.Provider.of<SettingsProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(LucideIcons.palette, size: 18, color: ui.colors.accent),
            const SizedBox(width: 8),
            const UiText(
              text: 'Select IDE & Code Highlight Theme',
              variant: UiTextVariant.body,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          height: 420,
          child: ListView.builder(
            itemCount: SyntaxHighlightTheme.all.length,
            itemBuilder: (context, index) {
              final theme = SyntaxHighlightTheme.all[index];
              final isSelected =
                  provider.settings.syntaxHighlightTheme == theme.name;

              return InkWell(
                onTap: () {
                  final isLight =
                      theme.backgroundColor.computeLuminance() > 0.5;
                  provider.updateSettings(
                    provider.settings.copyWith(
                      syntaxHighlightTheme: theme.name,
                      accentColor: theme.colors.first,
                      themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
                    ),
                  );
                  Navigator.pop(dialogContext);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? theme.colors.first
                          : theme.foregroundColor.withValues(alpha: 0.25),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          theme.name,
                          style: TextStyle(
                            color: theme.foregroundColor,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: theme.colors
                            .map(
                              (c) => Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(left: 4),
                                decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          UiButton(
            label: 'Close',
            variant: UiButtonVariant.ghost,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
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
                  final appProvider = p.Provider.of<AppProvider>(context, listen: false);
                  if (appProvider.generatedPlots.isNotEmpty) {
                    final targetFig = appProvider.generatedPlots.last.figNum;
                    appProvider.customizePlotFigure(targetFig, colormap: map.name);
                  }
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

  void _showExamplesDialog(BuildContext context) {
    final ui = UiTheme.of(context);
    final appProvider = p.Provider.of<AppProvider>(context, listen: false);
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final query = controller.text.toLowerCase();
            final filteredSamples = appProvider.availableSamples.where((s) {
              if (s is! File) return false;
              return p.basename(s.path).toLowerCase().contains(query);
            }).toList();

            return AlertDialog(
              backgroundColor: ui.colors.panel,
              surfaceTintColor: Colors.transparent,
              title: Row(
                children: [
                  Icon(LucideIcons.scrollText, color: ui.colors.accent, size: 20),
                  const SizedBox(width: 12),
                  const UiText(text: 'Example Scripts', variant: UiTextVariant.body, fontWeight: FontWeight.bold),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 16),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      onChanged: (_) => setDialogState(() {}),
                      style: TextStyle(color: ui.colors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search examples...',
                        hintStyle: TextStyle(color: ui.colors.textMuted),
                        prefixIcon: Icon(LucideIcons.search, size: 16, color: ui.colors.textMuted),
                        isDense: true,
                        filled: true,
                        fillColor: ui.colors.canvas,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: ui.colors.border),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filteredSamples.isEmpty 
                        ? Center(child: UiText(text: 'No matches found', color: ui.colors.textMuted))
                        : ListView.builder(
                            itemCount: filteredSamples.length,
                            itemBuilder: (context, index) {
                              final file = filteredSamples[index] as File;
                              final name = p.basename(file.path);
                              return ListTile(
                                dense: true,
                                leading: Icon(LucideIcons.fileCode, size: 16, color: ui.colors.accent),
                                title: UiText(text: name, variant: UiTextVariant.label),
                                hoverColor: ui.colors.hover,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onTap: () {
                                  appProvider.openSample(file);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
      if (value != null && context.mounted) {
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

  void _showDebuggerDialog(BuildContext context) {
    final ui = UiTheme.of(context);
    final appProvider = p.Provider.of<AppProvider>(context, listen: false);
    final activeFile = appProvider.activeFile;

    if (activeFile == null || activeFile.content.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open a non-empty script to start debugging.')),
      );
      return;
    }

    final blocks = appProvider.parseExecutableBlocks(activeFile.content);
    int currentBlockIdx = 0;
    bool isStepping = false;
    String lastOutput = '';
    String lastError = '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isFinished = currentBlockIdx >= blocks.length;
            final currentBlock = !isFinished ? blocks[currentBlockIdx] : null;

            Future<void> stepNext() async {
              if (isFinished || isStepping) return;
              setDialogState(() {
                isStepping = true;
                lastError = '';
              });
              final block = blocks[currentBlockIdx];
              appProvider.triggerEditorAction('editor.gotoLine:${block['line']}:1');
              try {
                final res = await UniLabBridge.instance.execute(
                  block['code'] as String,
                  filename: activeFile.path,
                );
                await appProvider.fetchWorkspaceVariables();
                if (!context.mounted) return;
                setDialogState(() {
                  lastOutput = res.stdout;
                  lastError = res.stderr;
                  currentBlockIdx++;
                  isStepping = false;
                });
              } catch (e) {
                if (!context.mounted) return;
                setDialogState(() {
                  lastError = e.toString();
                  isStepping = false;
                });
              }
            }

            Future<void> runRemaining() async {
              while (currentBlockIdx < blocks.length && lastError.isEmpty) {
                await stepNext();
              }
            }

            return AlertDialog(
              backgroundColor: ui.colors.panel,
              surfaceTintColor: Colors.transparent,
              title: Row(
                children: [
                  Icon(LucideIcons.bug, color: ui.colors.accent, size: 18),
                  const SizedBox(width: 10),
                  UiText(
                    text: 'Script Debugger — ${activeFile.name}',
                    variant: UiTextVariant.body,
                    fontWeight: FontWeight.bold,
                  ),
                  const Spacer(),
                  UiText(
                    text: isFinished
                        ? 'Completed (${blocks.length}/${blocks.length})'
                        : 'Step ${currentBlockIdx + 1} of ${blocks.length}',
                    variant: UiTextVariant.caption,
                    color: ui.colors.textMuted,
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                height: 380,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ui.colors.canvas,
                        borderRadius: ui.spacing.radiusSm,
                        border: Border.all(color: ui.colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UiText(
                            text: currentBlock != null
                                ? 'Next Statement (Line ${currentBlock['line']}):'
                                : 'All statements executed.',
                            variant: UiTextVariant.caption,
                            color: ui.colors.textMuted,
                          ),
                          const SizedBox(height: 6),
                          UiText(
                            text: currentBlock != null
                                ? (currentBlock['code'] as String)
                                : '% End of script',
                            variant: UiTextVariant.codeBody,
                            color: ui.colors.accent,
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (lastError.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: ui.spacing.radiusSm,
                        ),
                        child: UiText(
                          text: lastError,
                          variant: UiTextVariant.codeBody,
                          color: Colors.redAccent,
                          maxLines: 3,
                        ),
                      ),
                    if (lastOutput.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: ui.colors.panelHeader,
                          borderRadius: ui.spacing.radiusSm,
                        ),
                        child: UiText(
                          text: 'Output: ${lastOutput.trim()}',
                          variant: UiTextVariant.codeBody,
                          maxLines: 2,
                        ),
                      ),
                    UiText(
                      text: 'Live Workspace Variables (${appProvider.workspaceVariables.length})',
                      variant: UiTextVariant.label,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: ui.colors.canvas,
                          borderRadius: ui.spacing.radiusSm,
                          border: Border.all(color: ui.colors.border),
                        ),
                        child: appProvider.workspaceVariables.isEmpty
                            ? Center(
                                child: UiText(
                                  text: 'No variables assigned yet.',
                                  variant: UiTextVariant.caption,
                                  color: ui.colors.textMuted,
                                ),
                              )
                            : ListView(
                                padding: const EdgeInsets.all(8),
                                children: appProvider.workspaceVariables.entries.map((entry) {
                                  final info = entry.value is Map ? entry.value as Map : {};
                                  final preview = info['preview']?.toString() ?? entry.value.toString();
                                  final dtype = info['dtype']?.toString() ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 110,
                                          child: UiText(
                                            text: entry.key,
                                            variant: UiTextVariant.codeBody,
                                            fontWeight: FontWeight.bold,
                                            color: ui.colors.accent,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 80,
                                          child: UiText(
                                            text: dtype,
                                            variant: UiTextVariant.caption,
                                            color: ui.colors.textMuted,
                                          ),
                                        ),
                                        Expanded(
                                          child: UiText(
                                            text: preview,
                                            variant: UiTextVariant.codeBody,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                UiButton(
                  label: 'Reset',
                  icon: LucideIcons.rotateCcw,
                  variant: UiButtonVariant.secondary,
                  onPressed: isStepping
                      ? null
                      : () async {
                          await appProvider.clearWorkspace();
                          setDialogState(() {
                            currentBlockIdx = 0;
                            lastOutput = '';
                            lastError = '';
                          });
                        },
                ),
                UiButton(
                  label: 'Step Next',
                  icon: LucideIcons.stepForward,
                  variant: UiButtonVariant.primary,
                  onPressed: (isFinished || isStepping) ? null : stepNext,
                ),
                UiButton(
                  label: 'Continue All',
                  icon: LucideIcons.fastForward,
                  variant: UiButtonVariant.secondary,
                  onPressed: (isFinished || isStepping) ? null : runRemaining,
                ),
                UiButton(
                  label: 'Close',
                  variant: UiButtonVariant.ghost,
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPlotLabelsDialog(BuildContext context) {
    final ui = UiTheme.of(context);
    final appProvider = p.Provider.of<AppProvider>(context, listen: false);
    final settingsProvider = p.Provider.of<SettingsProvider>(context, listen: false);
    final latestPlot = appProvider.generatedPlots.isNotEmpty ? appProvider.generatedPlots.last : null;

    final titleCtrl = TextEditingController(text: latestPlot?.title ?? 'Figure 1');
    final xCtrl = TextEditingController(text: latestPlot?.xlabel ?? 'X Axis');
    final yCtrl = TextEditingController(text: latestPlot?.ylabel ?? 'Y Axis');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(LucideIcons.type, size: 18, color: ui.colors.accent),
            const SizedBox(width: 8),
            const UiText(text: 'Configure Plot Labels', variant: UiTextVariant.body, fontWeight: FontWeight.bold),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UiText(text: 'Figure Title', variant: UiTextVariant.caption, color: ui.colors.textMuted),
              const SizedBox(height: 6),
              TextField(
                controller: titleCtrl,
                style: TextStyle(color: ui.colors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: ui.colors.canvas,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 12),
              UiText(text: 'X-Axis Label', variant: UiTextVariant.caption, color: ui.colors.textMuted),
              const SizedBox(height: 6),
              TextField(
                controller: xCtrl,
                style: TextStyle(color: ui.colors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: ui.colors.canvas,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 12),
              UiText(text: 'Y-Axis Label', variant: UiTextVariant.caption, color: ui.colors.textMuted),
              const SizedBox(height: 6),
              TextField(
                controller: yCtrl,
                style: TextStyle(color: ui.colors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: ui.colors.canvas,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          UiButton(
            label: 'Cancel',
            variant: UiButtonVariant.ghost,
            onPressed: () => Navigator.pop(dialogContext),
          ),
          UiButton(
            label: 'Apply Labels',
            variant: UiButtonVariant.primary,
            onPressed: () {
              settingsProvider.updateSettings(
                settingsProvider.settings.copyWith(plotShowLabels: true),
              );
              final newTitle = titleCtrl.text.trim().isEmpty ? (latestPlot?.title ?? '') : titleCtrl.text.trim();
              final newX = xCtrl.text.trim();
              final newY = yCtrl.text.trim();
              if (latestPlot != null) {
                appProvider.updatePlotMetadata(
                  latestPlot.id,
                  title: newTitle,
                  xlabel: newX,
                  ylabel: newY,
                );
                appProvider.customizePlotFigure(
                  latestPlot.figNum,
                  title: newTitle,
                  xlabel: newX,
                  ylabel: newY,
                  showLabels: true,
                );
              }
              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showProfilerDialog(BuildContext context) async {
    final ui = UiTheme.of(context);
    final appProvider = p.Provider.of<AppProvider>(context, listen: false);
    if (appProvider.activeFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open a script first to run the Profiler.')),
      );
      return;
    }

    final report = await appProvider.runScriptProfiler();
    if (!context.mounted) return;

    final entries = (report['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final totalMs = (report['totalMs'] as num?)?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(LucideIcons.gauge, color: ui.colors.accent, size: 18),
            const SizedBox(width: 10),
            UiText(
              text: 'Execution Profiler — ${report['scriptName'] ?? ''}',
              variant: UiTextVariant.body,
              fontWeight: FontWeight.bold,
            ),
            const Spacer(),
            UiText(
              text: 'Total: ${totalMs.toStringAsFixed(2)} ms',
              variant: UiTextVariant.codeBody,
              color: ui.colors.accent,
            ),
          ],
        ),
        content: SizedBox(
          width: 620,
          height: 360,
          child: entries.isEmpty
              ? Center(
                  child: UiText(
                    text: report['error']?.toString() ?? 'No executable statements found.',
                    color: ui.colors.textMuted,
                  ),
                )
              : ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, index) => Divider(color: ui.colors.divider, height: 1),
                  itemBuilder: (context, idx) {
                    final item = entries[idx];
                    final ms = (item['durationMs'] as num).toDouble();
                    final ratio = totalMs > 0 ? (ms / totalMs).clamp(0.0, 1.0) : 0.0;
                    final line = item['line'] as int;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(dialogContext);
                        appProvider.triggerEditorAction('editor.gotoLine:$line:1');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 64,
                                  child: UiText(
                                    text: 'Line $line',
                                    variant: UiTextVariant.codeBody,
                                    color: ui.colors.textMuted,
                                  ),
                                ),
                                Expanded(
                                  child: UiText(
                                    text: item['code']?.toString() ?? '',
                                    variant: UiTextVariant.codeBody,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                UiText(
                                  text: '${ms.toStringAsFixed(2)} ms (${(ratio * 100).toStringAsFixed(0)}%)',
                                  variant: UiTextVariant.codeBody,
                                  color: ratio > 0.4 ? Colors.orangeAccent : ui.colors.accent,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 4,
                                backgroundColor: ui.colors.canvas,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ratio > 0.4 ? Colors.orangeAccent : ui.colors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          UiButton(
            label: 'Close',
            variant: UiButtonVariant.ghost,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  void _showDependencyMapDialog(BuildContext context) {
    final ui = UiTheme.of(context);
    final appProvider = p.Provider.of<AppProvider>(context, listen: false);
    final deps = appProvider.analyzeDependencies();

    final defined = (deps['definedFunctions'] as List).cast<String>();
    final localDeps = (deps['localDependencies'] as List).cast<Map<String, String>>();
    final builtins = (deps['builtinCalls'] as List).cast<String>();
    final externalCalls = (deps['externalCalls'] as List).cast<String>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(LucideIcons.network, color: ui.colors.accent, size: 18),
            const SizedBox(width: 10),
            UiText(
              text: 'Dependency Map — ${deps['scriptName']}',
              variant: UiTextVariant.body,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        content: SizedBox(
          width: 540,
          height: 360,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UiText(
                  text: 'Project Script Dependencies (${localDeps.length})',
                  variant: UiTextVariant.label,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 8),
                if (localDeps.isEmpty)
                  UiText(
                    text: 'No external project .m files referenced.',
                    variant: UiTextVariant.caption,
                    color: ui.colors.textMuted,
                  )
                else
                  ...localDeps.map(
                    (d) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(LucideIcons.fileCode, size: 16, color: ui.colors.accent),
                      title: UiText(text: '${d['name']}.m', variant: UiTextVariant.codeBody),
                      subtitle: UiText(
                        text: d['path'] ?? '',
                        variant: UiTextVariant.caption,
                        color: ui.colors.textMuted,
                      ),
                      onTap: () {
                        final path = d['path'];
                        if (path != null && path.isNotEmpty) {
                          appProvider.openFile(File(path));
                          Navigator.pop(dialogContext);
                        }
                      },
                    ),
                  ),
                const Divider(height: 24),
                UiText(
                  text: 'Defined Functions in File (${defined.length})',
                  variant: UiTextVariant.label,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: defined.isEmpty
                      ? [UiText(text: 'Top-level script (no local functions)', variant: UiTextVariant.caption, color: ui.colors.textMuted)]
                      : defined.map((fn) => Chip(label: Text(fn, style: const TextStyle(fontSize: 11)))).toList(),
                ),
                const Divider(height: 24),
                UiText(
                  text: 'Standard Library / Built-in Calls (${builtins.length})',
                  variant: UiTextVariant.label,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: builtins.isEmpty
                      ? [UiText(text: 'None detected', variant: UiTextVariant.caption, color: ui.colors.textMuted)]
                      : builtins.map((fn) => Chip(label: Text(fn, style: const TextStyle(fontSize: 11)))).toList(),
                ),
                if (externalCalls.isNotEmpty) ...[
                  const Divider(height: 24),
                  UiText(
                    text: 'Other Symbols / Unresolved Calls (${externalCalls.length})',
                    variant: UiTextVariant.label,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: externalCalls.map((fn) => Chip(label: Text(fn, style: const TextStyle(fontSize: 11)))).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          UiButton(
            label: 'Close',
            variant: UiButtonVariant.ghost,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  void _showVariableStatsDialog(BuildContext context) {
    final ui = UiTheme.of(context);
    final appProvider = p.Provider.of<AppProvider>(context, listen: false);
    if (!ref.read(shellLayoutProvider).showRightPanel) {
      ref.read(shellLayoutProvider.notifier).toggleRightPanel();
    }
    appProvider.setSelectedWorkspaceSegment('Variables');

    final vars = appProvider.workspaceVariables;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(LucideIcons.chartBar, color: ui.colors.accent, size: 18),
            const SizedBox(width: 10),
            const UiText(text: 'Workspace Variable Statistics', variant: UiTextVariant.body, fontWeight: FontWeight.bold),
          ],
        ),
        content: SizedBox(
          width: 680,
          height: 360,
          child: vars.isEmpty
              ? Center(
                  child: UiText(
                    text: 'No variables in workspace. Run a script or import data first.',
                    color: ui.colors.textMuted,
                  ),
                )
              : SingleChildScrollView(
                  child: DataTable(
                    headingRowHeight: 36,
                    dataRowMinHeight: 32,
                    dataRowMaxHeight: 40,
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Min')),
                      DataColumn(label: Text('Max')),
                      DataColumn(label: Text('Mean')),
                      DataColumn(label: Text('Std')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: vars.entries.map((e) {
                      final info = e.value is Map ? e.value as Map : {};
                      return DataRow(
                        cells: [
                          DataCell(UiText(text: e.key, variant: UiTextVariant.codeBody, fontWeight: FontWeight.bold, color: ui.colors.accent)),
                          DataCell(UiText(text: info['dtype']?.toString() ?? '-', variant: UiTextVariant.caption)),
                          DataCell(UiText(text: info['min']?.toString() ?? '-', variant: UiTextVariant.codeBody)),
                          DataCell(UiText(text: info['max']?.toString() ?? '-', variant: UiTextVariant.codeBody)),
                          DataCell(UiText(text: info['mean']?.toString() ?? '-', variant: UiTextVariant.codeBody)),
                          DataCell(UiText(text: info['std']?.toString() ?? '-', variant: UiTextVariant.codeBody)),
                          DataCell(
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                appProvider.runConsoleCommand('figure; plot(${e.key}); title("Plot of ${e.key}");');
                              },
                              child: const Text('Plot', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
        actions: [
          UiButton(
            label: 'Close',
            variant: UiButtonVariant.ghost,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  void _showForumDialog(BuildContext context) {
    final ui = UiTheme.of(context);
    const repoUrl = 'https://github.com/UniLab-Project/UniLab/discussions';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(LucideIcons.users, color: ui.colors.accent, size: 18),
            const SizedBox(width: 10),
            const UiText(text: 'UniLab Community & Forum', variant: UiTextVariant.body, fontWeight: FontWeight.bold),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const UiText(
                text: 'Join the UniLab scientific computing community to share scripts, ask questions, and request features.',
                variant: UiTextVariant.body,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ui.colors.canvas,
                  borderRadius: ui.spacing.radiusSm,
                  border: Border.all(color: ui.colors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: UiText(
                        text: repoUrl,
                        variant: UiTextVariant.codeBody,
                        color: ui.colors.accent,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.copy, size: 16),
                      tooltip: 'Copy URL',
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: repoUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Forum URL copied to clipboard.')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          UiButton(
            label: 'Close',
            variant: UiButtonVariant.primary,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdatesDialog(BuildContext context) async {
    final ui = UiTheme.of(context);
    final info = await UniLabBridge.instance.getInfo();
    if (!context.mounted) return;
    final backendVersion = info['version']?.toString() ?? '1.0.0';
    final mode = info['mode']?.toString() ?? 'native';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(LucideIcons.circleCheck, color: Colors.greenAccent, size: 18),
            const SizedBox(width: 10),
            const UiText(text: 'UniLab Update Status', variant: UiTextVariant.body, fontWeight: FontWeight.bold),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const UiText(
                text: 'You are running the latest version of UniLab.',
                variant: UiTextVariant.body,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 12),
              UiText(text: 'Frontend IDE Version: 1.5.2', variant: UiTextVariant.caption, color: ui.colors.textMuted),
              const SizedBox(height: 4),
              UiText(text: 'Kernel Version: $backendVersion ($mode)', variant: UiTextVariant.caption, color: ui.colors.textMuted),
            ],
          ),
        ),
        actions: [
          UiButton(
            label: 'OK',
            variant: UiButtonVariant.primary,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final ui = UiTheme.of(context);
    final appProvider = p.Provider.of<AppProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(LucideIcons.info, color: ui.colors.accent, size: 18),
            const SizedBox(width: 10),
            const UiText(text: 'About UniLab IDE', variant: UiTextVariant.body, fontWeight: FontWeight.bold),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const UiText(
                text: 'UniLab — Hybrid Scientific Computing & Numerical Simulation Environment',
                variant: UiTextVariant.body,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 12),
              UiText(
                text: 'Version 1.5.2 • Rust + Python Hybrid Kernel • Flutter Desktop Shell',
                variant: UiTextVariant.caption,
                color: ui.colors.textMuted,
              ),
              const SizedBox(height: 8),
              UiText(
                text: 'Backend Status: ${appProvider.backendStatus.name.toUpperCase()}',
                variant: UiTextVariant.codeBody,
                color: ui.colors.accent,
              ),
            ],
          ),
        ),
        actions: [
          UiButton(
            label: 'Open Licenses',
            variant: UiButtonVariant.secondary,
            onPressed: () {
              Navigator.pop(dialogContext);
              showLicensePage(
                context: context,
                applicationName: 'UniLab',
                applicationVersion: '1.5.2',
              );
            },
          ),
          UiButton(
            label: 'Close',
            variant: UiButtonVariant.primary,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
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
              onTap: () => _showDebuggerDialog(context),
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
              label: 'Toolbox',
              icon: LucideIcons.wrench,
              isLarge: true,
              onTap: () => EngineeringToolboxDialog.show(context),
            ),
            RibbonButton(
              label: 'Theme',
              icon: LucideIcons.palette,
              onTap: () => _showThemePicker(context),
            ),
            RibbonButton(
              label: 'Clear Workspace',
              icon: LucideIcons.eraser,
              onTap: () async {
                await appProvider.clearWorkspace();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Workspace variables cleared.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
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
              onTap: () {
                final layout = ref.read(shellLayoutProvider);
                if (layout.isCommandOnlyMode) {
                  ref.read(shellLayoutProvider.notifier).resetLayout();
                } else {
                  ref.read(shellLayoutProvider.notifier).setCommandOnlyMode();
                }
              },
            ),
          ],
        ),
      ];
    } else if (_activeTab == 'SIMULATION') {
      final simCtrl = SimulationController.instance;

      activeGroups = [
        RibbonGroup(
          title: 'Simulation Studio',
          children: [
            RibbonButton(
              label: 'Open Studio',
              icon: LucideIcons.atom,
              isLarge: true,
              onTap: () {
                appProvider.openSimulationStudio();
              },
            ),
            RibbonButton(
              label: 'Browse Library',
              icon: LucideIcons.boxes,
              isLarge: true,
              onTap: () {
                SimulationCatalogDialog.show(context);
              },
            ),
          ],
        ),
        RibbonGroup(
          title: 'Playback & Time',
          children: [
            RibbonButton(
              label: simCtrl.isPlaying ? 'Pause' : 'Play',
              icon: simCtrl.isPlaying ? LucideIcons.pause : LucideIcons.play,
              isLarge: true,
              onTap: () {
                appProvider.openSimulationStudio();
                simCtrl.togglePlayPause();
              },
            ),
            RibbonButton(
              label: 'Step Back',
              icon: LucideIcons.stepBack,
              onTap: () {
                appProvider.openSimulationStudio();
                simCtrl.stepBackward();
              },
            ),
            RibbonButton(
              label: 'Step Forward',
              icon: LucideIcons.stepForward,
              onTap: () {
                appProvider.openSimulationStudio();
                simCtrl.stepForward();
              },
            ),
            RibbonButton(
              label: 'Reset (t=0)',
              icon: LucideIcons.rotateCcw,
              onTap: () {
                appProvider.openSimulationStudio();
                simCtrl.reset();
              },
            ),
          ],
        ),
        RibbonGroup(
          title: 'MP4 Recording',
          children: [
            RibbonButton(
              label: simCtrl.videoRecorder.isRecording ? 'Stop & Save' : 'Record MP4',
              icon: simCtrl.videoRecorder.isRecording ? Icons.stop : LucideIcons.video,
              isLarge: true,
              onTap: () async {
                appProvider.openSimulationStudio();
                if (simCtrl.videoRecorder.isRecording) {
                  final path = await simCtrl.stopAndSaveVideoRecording(context);
                  if (path != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Video saved: $path')),
                    );
                  }
                } else {
                  await simCtrl.startVideoRecording();
                }
              },
            ),
            RibbonButton(
              label: 'Reset 3D Camera',
              icon: LucideIcons.camera,
              onTap: () {
                simCtrl.camera3D.reset();
              },
            ),
          ],
        ),
        RibbonGroup(
          title: 'Model Code',
          children: [
            RibbonButton(
              label: 'Export Script',
              icon: LucideIcons.fileCode,
              isLarge: true,
              onTap: () {
                final script = simCtrl.activeModel.toUniLabScript();
                appProvider.insertCodeIntoActiveScript(
                  script,
                  suggestedFileName: '${simCtrl.activeModel.id}.m',
                  replaceAll: false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Model script exported to active editor.')),
                );
              },
            ),
          ],
        ),
      ];
    } else if (_activeTab == 'TOOLBOX') {
      void openInDock(EngineeringToolCategory cat) {
        if (!ref.read(shellLayoutProvider).showRightPanel) {
          ref.read(shellLayoutProvider.notifier).toggleRightPanel();
        }
        appProvider.setSelectedWorkspaceSegment('Toolbox');
        EngineeringToolboxDialog.show(context, initialCategory: cat);
      }

      activeGroups = [
        RibbonGroup(
          title: 'Control Systems',
          children: [
            RibbonButton(
              label: 'Control Studio',
              icon: LucideIcons.slidersHorizontal,
              isLarge: true,
              onTap: () => openInDock(EngineeringToolCategory.control),
            ),
            RibbonButton(
              label: 'Bode & Margins',
              icon: LucideIcons.activity,
              onTap: () {
                appProvider.runConsoleCommand(
                  'G = tf([10], [1, 2, 10]); figure; margin(G); grid on;',
                );
              },
            ),
            RibbonButton(
              label: 'Root Locus',
              icon: LucideIcons.gitBranch,
              onTap: () {
                appProvider.runConsoleCommand(
                  'G = tf([10], conv([1, 0], [1, 4, 8])); figure; rlocus(G); title("Root Locus"); grid on;',
                );
              },
            ),
          ],
        ),
        RibbonGroup(
          title: 'Signal & Filters',
          children: [
            RibbonButton(
              label: 'Filter Designer',
              icon: LucideIcons.waves,
              isLarge: true,
              onTap: () => openInDock(EngineeringToolCategory.signal),
            ),
            RibbonButton(
              label: 'FFT & PSD',
              icon: LucideIcons.chartBar,
              onTap: () {
                appProvider.runConsoleCommand(
                  'fs = 1000; t = linspace(0, 1, fs); x = sin(2*pi*60*t) + 0.6*sin(2*pi*180*t) + 0.3*randn(size(t)); figure; pwelch(x, 256, 128, 512, fs); title("Welch PSD"); grid on;',
                );
              },
            ),
            RibbonButton(
              label: 'Spectrogram',
              icon: LucideIcons.flame,
              onTap: () {
                appProvider.runConsoleCommand(
                  'fs = 1000; t = linspace(0, 2, 2000); x = chirp(t, 20, 2, 350); figure; spectrogram(x, 128, 120, 256, fs); title("Chirp Spectrogram");',
                );
              },
            ),
          ],
        ),
        RibbonGroup(
          title: 'Numerical & ODE',
          children: [
            RibbonButton(
              label: 'Matrix Lab',
              icon: LucideIcons.grid3x3,
              isLarge: true,
              onTap: () => openInDock(EngineeringToolCategory.matrix),
            ),
            RibbonButton(
              label: 'ODE45 Solver',
              icon: LucideIcons.sigma,
              isLarge: true,
              onTap: () => openInDock(EngineeringToolCategory.ode),
            ),
          ],
        ),
        RibbonGroup(
          title: 'Engineering Ref',
          children: [
            RibbonButton(
              label: 'Units & SI',
              icon: LucideIcons.compass,
              onTap: () => openInDock(EngineeringToolCategory.units),
            ),
            RibbonButton(
              label: 'Templates',
              icon: LucideIcons.fileCode2,
              onTap: () => openInDock(EngineeringToolCategory.templates),
            ),
          ],
        ),
      ];
    } else if (_activeTab == 'EDITOR') {
      activeGroups = [
        RibbonGroup(
          title: 'File & Save',
          children: [
            RibbonButton(
              label: 'Save (Ctrl+S)',
              icon: LucideIcons.save,
              isLarge: true,
              onTap: () => appProvider.saveActiveFile(),
            ),
            RibbonButton(
              label: 'Save As',
              icon: LucideIcons.fileOutput,
              onTap: () => appProvider.saveActiveFileAs(),
            ),
          ],
        ),
        RibbonGroup(
          title: 'Edit',
          children: [
            RibbonButton(
              label: 'Find & Replace', 
              icon: LucideIcons.searchCode, 
              isLarge: true, 
              onTap: () => appProvider.triggerEditorAction('editor.replace'),
            ),
            RibbonButton(
              label: 'Go to Line', 
              icon: LucideIcons.hash, 
              onTap: () => appProvider.triggerEditorAction('editor.gotoLine'),
            ),
          ],
        ),
        RibbonGroup(
          title: 'Format & Theme',
          children: [
            RibbonButton(
              label: 'Auto Indent',
              icon: LucideIcons.indentIncrease,
              onTap: () => appProvider.triggerEditorAction('editor.autoIndent'),
            ),
            RibbonButton(
              label: 'Comment',
              icon: LucideIcons.messageSquare,
              onTap: () => appProvider.triggerEditorAction('editor.comment'),
            ),
            RibbonButton(
              label: 'App Theme',
              icon: LucideIcons.palette,
              onTap: () => _showThemePicker(context),
            ),
          ],
        ),
      ];
    } else if (_activeTab == 'PLOTS') {
      final settingsProvider = p.Provider.of<SettingsProvider>(context);
      final settings = settingsProvider.settings;
      activeGroups = [
        RibbonGroup(
          title: 'Export',
          children: [
            RibbonButton(
              label: 'Snapshot',
              icon: LucideIcons.camera,
              isLarge: true,
              onTap: () async {
                final ok = await appProvider.exportPlotSnapshot();
                if (!ok && context.mounted && appProvider.generatedPlots.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No plots available yet. Run a plotting script first.')),
                  );
                }
              },
            ),
            RibbonButton(
              label: 'Export PDF',
              icon: LucideIcons.fileType,
              onTap: () async {
                await appProvider.exportPlotsToPdf();
              },
            ),
          ],
        ),
        RibbonGroup(
          title: 'Visuals',
          children: [
            RibbonButton(
              label: 'Grid',
              icon: LucideIcons.grid3x3,
              color: settings.plotShowGrid ? ui.colors.accent : null,
              onTap: () {
                final next = !settings.plotShowGrid;
                settingsProvider.updateSettings(settings.copyWith(plotShowGrid: next));
                if (appProvider.generatedPlots.isNotEmpty) {
                  final target = appProvider.generatedPlots.last;
                  appProvider.updatePlotMetadata(
                    target.id,
                    showGrid: next,
                  );
                  appProvider.customizePlotFigure(
                    target.figNum,
                    showGrid: next,
                  );
                }
              },
            ),
            RibbonButton(
              label: 'Labels',
              icon: LucideIcons.type,
              color: settings.plotShowLabels ? ui.colors.accent : null,
              onTap: () {
                final next = !settings.plotShowLabels;
                settingsProvider.updateSettings(settings.copyWith(plotShowLabels: next));
                if (appProvider.generatedPlots.isNotEmpty) {
                  final target = appProvider.generatedPlots.last;
                  appProvider.updatePlotMetadata(
                    target.id,
                    showLabels: next,
                  );
                  appProvider.customizePlotFigure(
                    target.figNum,
                    showLabels: next,
                  );
                }
              },
            ),
            RibbonButton(
              label: 'Edit Labels',
              icon: LucideIcons.edit3,
              onTap: () => _showPlotLabelsDialog(context),
            ),
            RibbonButton(
              label: 'Legend',
              icon: LucideIcons.list,
              color: settings.plotShowLegend ? ui.colors.accent : null,
              onTap: () {
                final next = !settings.plotShowLegend;
                settingsProvider.updateSettings(settings.copyWith(plotShowLegend: next));
                if (appProvider.generatedPlots.isNotEmpty) {
                  final target = appProvider.generatedPlots.last;
                  appProvider.updatePlotMetadata(
                    target.id,
                    showLegend: next,
                  );
                  appProvider.customizePlotFigure(
                    target.figNum,
                    showLegend: next,
                  );
                }
              },
            ),
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
            RibbonButton(
              label: 'Profiler',
              icon: LucideIcons.gauge,
              isLarge: true,
              onTap: () => _showProfilerDialog(context),
            ),
            RibbonButton(
              label: 'Dependency Map',
              icon: LucideIcons.network,
              onTap: () => _showDependencyMapDialog(context),
            ),
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
            RibbonButton(
              label: 'Variable Stat',
              icon: LucideIcons.chartBar,
              onTap: () => _showVariableStatsDialog(context),
            ),
          ],
        ),
      ];
    } else if (_activeTab == 'VIEW') {
      final layoutState = ref.watch(shellLayoutProvider);
      activeGroups = [
        RibbonGroup(
          title: 'Panels',
          children: [
            RibbonButton(
              label: 'Files',
              icon: LucideIcons.folder,
              isLarge: true,
              color: layoutState.showLeftPanel ? ui.colors.accent : null,
              onTap: () => ref.read(shellLayoutProvider.notifier).toggleLeftPanel(),
            ),
            RibbonButton(
              label: 'Workspace',
              icon: LucideIcons.box,
              isLarge: true,
              color: layoutState.showRightPanel ? ui.colors.accent : null,
              onTap: () => ref.read(shellLayoutProvider.notifier).toggleRightPanel(),
            ),
            RibbonButton(
              label: 'Console',
              icon: LucideIcons.terminal,
              isLarge: true,
              color: layoutState.showBottomPanel ? ui.colors.accent : null,
              onTap: () => ref.read(shellLayoutProvider.notifier).toggleBottomPanel(),
            ),
          ],
        ),
        RibbonGroup(
          title: 'Window',
          children: [
            RibbonButton(
              label: 'Split Editor',
              icon: LucideIcons.columns2,
              color: appProvider.isSplitEditor ? ui.colors.accent : null,
              onTap: () => appProvider.toggleSplitEditor(),
            ),
            RibbonButton(
              label: 'Plots Tab', 
              icon: LucideIcons.lineChart,
              onTap: () {
                if (!ref.read(shellLayoutProvider).showRightPanel) {
                  ref.read(shellLayoutProvider.notifier).toggleRightPanel();
                }
                appProvider.setSelectedWorkspaceSegment('Plots');
              },
            ),
          ],
        ),
      ];
    } else if (_activeTab == 'HELP') {
      activeGroups = [
        RibbonGroup(
          title: 'Documentation',
          children: [
            RibbonButton(
              label: 'Get Started',
              icon: LucideIcons.rocket,
              isLarge: true,
              onTap: () {
                if (!ref.read(shellLayoutProvider).showRightPanel) {
                  ref.read(shellLayoutProvider.notifier).toggleRightPanel();
                }
                appProvider.openHelpTopic('intro');
              },
            ),
            RibbonButton(
              label: 'User Guide',
              icon: LucideIcons.bookOpen,
              isLarge: true,
              onTap: () {
                if (!ref.read(shellLayoutProvider).showRightPanel) {
                  ref.read(shellLayoutProvider.notifier).toggleRightPanel();
                }
                appProvider.openHelpTopic(null);
              },
            ),
            RibbonButton(
              label: 'Examples', 
              icon: LucideIcons.scrollText,
              onTap: () => _showExamplesDialog(context),
            ),
          ],
        ),
        RibbonGroup(
          title: 'Resources',
          children: [
            RibbonButton(
              label: 'Forum',
              icon: LucideIcons.users,
              onTap: () => _showForumDialog(context),
            ),
            RibbonButton(
              label: 'Updates',
              icon: LucideIcons.refreshCw,
              onTap: () => _showUpdatesDialog(context),
            ),
          ],
        ),
        RibbonGroup(
          title: 'UniLab',
          children: [
            RibbonButton(
              label: 'About',
              icon: LucideIcons.info,
              onTap: () => _showAboutDialog(context),
            ),
            RibbonButton(
              label: 'Licenses',
              icon: LucideIcons.copyright,
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: 'UniLab',
                  applicationVersion: '1.5.2',
                );
              },
            ),
          ],
        ),
      ];
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
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
                  tabs: const ['HOME', 'SIMULATION', 'TOOLBOX', 'EDITOR', 'PLOTS', 'ANALYZE', 'VIEW', 'HELP'],
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
          width: double.infinity,
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
