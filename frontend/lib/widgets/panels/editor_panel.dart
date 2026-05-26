import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/matlab.dart';
import '../../providers/app_provider.dart';
import '../../providers/settings_provider.dart';

class EditorPanel extends StatefulWidget {
  const EditorPanel({super.key});

  @override
  State<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends State<EditorPanel> {
  final Map<int, CodeController> _codeControllers = {};

  CodeController _getOrCreateController(String content) {
    final hash = content.hashCode;
    if (!_codeControllers.containsKey(hash)) {
      _codeControllers[hash] = CodeController(
        language: matlab,
        text: content,
      );
    }
    return _codeControllers[hash]!;
  }

  @override
  void dispose() {
    for (final controller in _codeControllers.values) {
      controller.dispose();
    }
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
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: appProvider.openFiles.length + 1,
                itemBuilder: (context, index) {
                  // Add File Button
                  if (index == appProvider.openFiles.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () {
                          appProvider.addNewFile();
                        },
                        tooltip: 'New File',
                        iconSize: 16,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    );
                  }

                  final file = appProvider.openFiles[index];
                  final isActive = index == appProvider.activeFileIndex;

                  return GestureDetector(
                    onTap: () {
                      appProvider.setActiveFile(index);
                    },
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).scaffoldBackgroundColor
                            : Colors.transparent,
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                          bottom: BorderSide(
                            color: isActive
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Text(
                              file.name,
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight:
                                    isActive ? FontWeight.bold : FontWeight.normal,
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
                          GestureDetector(
                            onTap: () {
                              appProvider.closeFile(index);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.close,
                                size: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.7),
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
            // Code Editor
            Expanded(
              child: activeFile != null
                  ? SingleChildScrollView(
                      child: CodeField(
                        controller: _getOrCreateController(activeFile.content),
                        textStyle: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: settingsProvider.settings.fontSize,
                          color: const Color(0xFFCCCCCC),
                          height: 1.5,
                        ),
                        onChanged: (code) {
                          appProvider.updateActiveFileContent(code);
                        },
                        cursorColor: Theme.of(context).primaryColor,
                        gutterStyle: GutterStyle(
                          width: 50,
                          textAlign: TextAlign.right,
                          textStyle: TextStyle(
                            color: const Color(0xFF858585),
                            fontSize: settingsProvider.settings.fontSize - 2,
                            fontFamily: 'JetBrains Mono',
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
