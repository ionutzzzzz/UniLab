import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:highlight/languages/matlab.dart';
import '../../providers/app_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/models.dart';

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
    return Consumer2<AppProvider, SettingsProvider>(
      builder: (context, appProvider, settingsProvider, _) {
        final activeFile = appProvider.activeFile;

        return Column(
          children: [
            // Tab Bar
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
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
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Theme.of(context).scaffoldBackgroundColor
                                  : Colors.transparent,
                              border: Border(
                                right: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                  width: 1,
                                ),
                                top: BorderSide(
                                  color: isActive
                                      ? Theme.of(context).primaryColor
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
                                  color: isActive ? Theme.of(context).primaryColor : const Color(0xFF858585),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    file.name,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                      color: isActive ? Colors.white : const Color(0xFF858585),
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
                                      color: Theme.of(context).primaryColor,
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
                                      color: const Color(0xFF858585).withValues(alpha: 0.5),
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
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () => appProvider.addNewFile(),
                    tooltip: 'New File',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            // Code Editor
            Expanded(
              child: activeFile != null
                  ? Theme(
                      data: Theme.of(context).copyWith(
                        hoverColor: Colors.transparent,
                      ),
                      child: CodeTheme(
                        data: CodeThemeData(styles: vs2015Theme),
                        child: CodeField(
                          controller: _getOrCreateController(activeFile),
                          expands: true,
                          textStyle: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: settingsProvider.settings.fontSize,
                            color: const Color(0xFFCCCCCC),
                            height: 1.5,
                          ),
                          onChanged: (code) {
                            appProvider.updateActiveFileContent(code);
                          },
                          cursorColor: Colors.white,
                          gutterStyle: GutterStyle(
                            background: const Color(0xFF1E1E1E),
                            textStyle: TextStyle(
                              color: const Color(0xFF858585),
                              fontSize: settingsProvider.settings.fontSize - 2,
                              fontFamily: 'JetBrains Mono',
                            ),
                            textAlign: TextAlign.right,
                            width: 60,
                            showLineNumbers: true,
                          ),
                        ),
                      ),
                    )

                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 48,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No file open',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF858585),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
