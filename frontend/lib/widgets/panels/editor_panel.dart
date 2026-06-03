import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:highlight/languages/matlab.dart';
import '../../providers/app_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/models.dart';
import '../../theme/ui_theme.dart';
import '../../theme/ui_decorations.dart';

class EditorPanel extends StatefulWidget {
  const EditorPanel({super.key});

  @override
  State<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends State<EditorPanel> {
  final Map<String, CodeController> _codeControllers = {};
  final ScrollController _tabsScrollController = ScrollController();

  CodeController _getOrCreateController(UniLabFile file) {
    if (!_codeControllers.containsKey(file.path)) {
      _codeControllers[file.path] = CodeController(
        language: matlab,
        text: file.content,
      );
    }
    return _codeControllers[file.path]!;
  }

  @override
  void dispose() {
    for (final controller in _codeControllers.values) {
      controller.dispose();
    }
    _tabsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return Consumer2<AppProvider, SettingsProvider>(
      builder: (context, appProvider, settingsProvider, _) {
        final activeFile = appProvider.activeFile;

        return Container(
          decoration: ShellDecorations.panelDecoration(ui),
          margin: const EdgeInsets.all(2.0),
          child: Column(
            children: [
              // Tab Bar
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: ui.colors.panelHeader,
                  border: Border(
                    bottom: BorderSide(
                      color: ui.colors.border,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _tabsScrollController,
                        primary: false,
                        scrollDirection: Axis.horizontal,
                        itemCount: appProvider.openFiles.length,
                        itemBuilder: (context, index) {
                          final file = appProvider.openFiles[index];
                          final isActive = index == appProvider.activeFileIndex;

                          return GestureDetector(
                            onTap: () {
                              appProvider.setActiveFile(index);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? ui.colors.canvas
                                    : Colors.transparent,
                                border: Border(
                                  right: BorderSide(
                                    color: ui.colors.border,
                                    width: 1,
                                  ),
                                  top: BorderSide(
                                    color: isActive
                                        ? ui.colors.accent
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    size: 14,
                                    color: isActive ? ui.colors.accent : ui.colors.textMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      file.name,
                                      style: ui.typography.label.copyWith(
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                        color: isActive ? ui.colors.textInverse : ui.colors.textMuted,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (file.isModified)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.circle,
                                        size: 6,
                                        color: ui.colors.accent,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {
                                        appProvider.closeFile(index);
                                      },
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: ui.colors.textMuted.withValues(alpha: 0.5),
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
                    // Add File Button
                    IconButton(
                      icon: Icon(Icons.add, size: 16, color: ui.colors.icon),
                      onPressed: () => appProvider.addNewFile(),
                      tooltip: 'New File',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
                            Expanded(
                              child: activeFile != null
                                  ? Container(
                                      color: ui.colors.canvas,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          hoverColor: Colors.transparent,
                                        ),
                                        child: Listener(
                                          onPointerSignal: (pointerSignal) {
                                            if (pointerSignal is PointerScrollEvent) {
                                              final isCtrlPressed = HardwareKeyboard
                                                      .instance.logicalKeysPressed
                                                      .contains(LogicalKeyboardKey.controlLeft) ||
                                                  HardwareKeyboard.instance.logicalKeysPressed
                                                      .contains(LogicalKeyboardKey.controlRight) ||
                                                  HardwareKeyboard.instance.logicalKeysPressed
                                                      .contains(LogicalKeyboardKey.metaLeft) ||
                                                  HardwareKeyboard.instance.logicalKeysPressed
                                                      .contains(LogicalKeyboardKey.metaRight);
                                              if (isCtrlPressed) {
                                                final currentSize =
                                                    settingsProvider.settings.fontSize;
                                                final newSize = (currentSize -
                                                        (pointerSignal.scrollDelta.dy > 0
                                                            ? 1
                                                            : -1))
                                                    .clamp(8.0, 48.0);
                                                if (newSize != currentSize) {
                                                  settingsProvider.updateSettings(
                                                      settingsProvider.settings
                                                          .copyWith(fontSize: newSize));
                                                }
                                              }
                                            }
                                          },
                                          child: CodeTheme(
                                            data: CodeThemeData(styles: vs2015Theme),
                                            child: Builder(
                                              builder: (context) {
                                                final viewportWidth = MediaQuery.of(context).size.width;
                                                final codeField = CodeField(
                                                  controller: _getOrCreateController(activeFile),
                                                  wrap: settingsProvider.settings.wordWrap,
                                                  textStyle: TextStyle(
                                                    fontFamily: 'JetBrains Mono',
                                                    fontSize: settingsProvider.settings.fontSize,
                                                    color: ui.colors.textPrimary,
                                                    height: 1.5,
                                                  ),
                                                  onChanged: (code) {
                                                    appProvider.updateActiveFileContent(code);
                                                  },
                                                  cursorColor: ui.colors.accent,
                                                  gutterStyle: GutterStyle(
                                                    background: ui.colors.canvas,
                                                    textStyle: TextStyle(
                                                      color: ui.colors.textMuted,
                                                      fontSize:
                                                          settingsProvider.settings.fontSize - 2,
                                                      fontFamily: 'JetBrains Mono',
                                                      height: 1.5,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                    width: 80,
                                                    showLineNumbers: true,
                                                  ),
                                                );

                                                if (settingsProvider.settings.wordWrap) {
                                                  return SingleChildScrollView(
                                                    child: codeField,
                                                  );
                                                }

                                                return SingleChildScrollView(
                                                  child: SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    child: ConstrainedBox(
                                                      constraints: BoxConstraints(
                                                        minWidth: viewportWidth,
                                                        maxWidth: 5000,
                                                      ),
                                                      child: codeField,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 48,
                              color: ui.colors.textMuted.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No file open',
                              style:
                                  ui.typography.body.copyWith(
                                color: ui.colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
