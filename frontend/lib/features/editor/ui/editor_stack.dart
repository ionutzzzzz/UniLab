import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/matlab.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path_utils;
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/app_provider.dart';
import '../../../utils/file_manager.dart';
import 'editor_tab_bar.dart';
import 'editor_breadcrumbs.dart';
import 'editor_surface.dart';
import 'find_replace_bar.dart';

// Specialized viewers
import 'viewers/image_viewer.dart';
import 'viewers/pdf_viewer.dart';
import 'viewers/audio_viewer.dart';
import 'viewers/import_data_view.dart';

class EditorStack extends StatefulWidget {
  const EditorStack({super.key});

  @override
  State<EditorStack> createState() => _EditorStackState();
}

class _EditorStackState extends State<EditorStack> {
  late CodeController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _showFindReplace = false;
  Timer? _autoSaveTimer;
  String? _lastFileId;
  StreamSubscription? _actionSubscription;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: '',
      language: matlab,
    );
    _controller.addListener(_onCodeChanged);

    // Listen to actions from Ribbon via AppProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = context.read<AppProvider>();
      _actionSubscription = appProvider.editorActions.listen((action) {
        debugPrint('EditorStack: Received editor action: $action');
        if (!mounted) {
          debugPrint('EditorStack: Not mounted, ignoring action');
          return;
        }
        switch (action) {
          case 'editor.find':
            _toggleFindReplace();
            break;
          case 'editor.gotoLine':
            _showGoToLineDialog();
            break;
        }
      });
    });
  }

  void _showGoToLineDialog() {
    final ui = UiTheme.of(context);
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ui.colors.panel,
        title: UiText(text: 'Go to Line', variant: UiTextVariant.body, fontWeight: FontWeight.bold),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: TextStyle(color: ui.colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Line number',
            hintStyle: TextStyle(color: ui.colors.textMuted),
          ),
          onSubmitted: (val) {
            final line = int.tryParse(val);
            if (line != null) {
              _goToLine(line);
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: UiText(text: 'Cancel', color: ui.colors.textMuted),
          ),
          TextButton(
            onPressed: () {
              final line = int.tryParse(controller.text);
              if (line != null) {
                _goToLine(line);
              }
              Navigator.pop(context);
            },
            child: UiText(text: 'Go', color: ui.colors.accent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _goToLine(int line) {
    if (line < 1) return;
    final text = _controller.text;
    final lines = text.split('\n');
    if (line > lines.length) return;

    int pos = 0;
    for (int i = 0; i < line - 1; i++) {
      pos += lines[i].length + 1;
    }
    
    _controller.selection = TextSelection.collapsed(offset: pos);
    _focusNode.requestFocus();
  }

  void _onCodeChanged() {
    final appProvider = context.read<AppProvider>();
    final activeFile = appProvider.activeFile;
    if (activeFile == null) return;

    // Only handle changes for text files
    if (activeFile.path.isNotEmpty && !UniLabFileManager.isTextFile(activeFile.path)) {
      return;
    }

    appProvider.updateActiveFileContent(_controller.text);

    final settings = context.read<SettingsProvider>().settings;
    if (settings.autoSave) {
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer(const Duration(seconds: 2), () {
        appProvider.saveActiveFile();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activeFile = context.watch<AppProvider>().activeFile;
    if (activeFile != null && activeFile.id != _lastFileId) {
      _lastFileId = activeFile.id;
      _controller.removeListener(_onCodeChanged);
      _controller.text = activeFile.content;
      _controller.addListener(_onCodeChanged);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _actionSubscription?.cancel();
    _controller.removeListener(_onCodeChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleFindReplace() {
    setState(() {
      _showFindReplace = !_showFindReplace;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final appProvider = context.watch<AppProvider>();
    final settings = context.watch<SettingsProvider>().settings;

    if (appProvider.activeFile == null) {
      return _buildEmptyState(ui);
    }

    final activeFile = appProvider.activeFile!;
    
    final tabs = appProvider.openFiles.map((f) => EditorTabModel(
      id: f.id,
      title: f.name,
      isActive: f.id == appProvider.activeFile?.id,
      isDirty: f.isModified,
    )).toList();

    Widget content;
    bool showMinimap = false;

    if (UniLabFileManager.isImageFile(activeFile.path)) {
      content = ImageViewer(path: activeFile.path, name: activeFile.name);
    } else if (UniLabFileManager.isPdfFile(activeFile.path)) {
      content = UniLabPdfViewer(path: activeFile.path, name: activeFile.name);
    } else if (UniLabFileManager.isAudioFile(activeFile.path)) {
      content = AudioViewer(path: activeFile.path, name: activeFile.name);
    } else if (activeFile.path == 'unilab://import-data') {
      content = const ImportDataView();
    } else {
      if (!UniLabFileManager.isTextFile(activeFile.path) && activeFile.path.isNotEmpty) {
        debugPrint('EditorStack: Unknown or binary file type for path: ${activeFile.path}. Falling back to text editor.');
      }
      content = EditorSurface(
        controller: _controller,
        focusNode: _focusNode,
      );
      showMinimap = settings.showMinimap;
    }

    return Container(
      color: ui.colors.canvas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxHeight < 50) {
            return const SizedBox.shrink();
          }
          return Column(
            children: [
              EditorTabBar(
                tabs: tabs,
                onTabTap: (id) {
                  final index = appProvider.openFiles.indexWhere((f) => f.id == id);
                  appProvider.setActiveFile(index);
                },
                onTabClose: (id) {
                  final index = appProvider.openFiles.indexWhere((f) => f.id == id);
                  appProvider.closeFile(index);
                },
                onNewTab: () => appProvider.addNewFile(),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              EditorBreadcrumbs(
                                pathSegments: activeFile.path.isNotEmpty 
                                    ? path_utils.split(activeFile.path)
                                    : [activeFile.name],
                              ),
                              Expanded(child: content),
                            ],
                          ),
                          if (_showFindReplace) 
                            Positioned(
                              top: 0,
                              right: 20,
                              child: FindReplaceBar(
                                onClose: _toggleFindReplace,
                                controller: _controller,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (showMinimap)
                      _EditorMinimap(controller: _controller),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(UiTheme ui) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.code, size: 48, color: ui.colors.textDisabled),
          const SizedBox(height: 16),
          const UiText(text: 'No file open', variant: UiTextVariant.body),
        ],
      ),
    );
  }
}

class _EditorMinimap extends StatelessWidget {
  const _EditorMinimap({required this.controller});
  final CodeController controller;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final lines = controller.text.split('\n');
        
        return Container(
          width: 80,
          decoration: BoxDecoration(
            color: ui.colors.canvas,
            border: Border(left: BorderSide(color: ui.colors.divider.withValues(alpha: 0.3))),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lines.map((line) => _MinimapLine(line: line)).toList(),
                ),
              ),
              Positioned.fill(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class _MinimapLine extends StatelessWidget {
  final String line;
  const _MinimapLine({required this.line});

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    if (line.trim().isEmpty) return const SizedBox(height: 3);

    int leadingSpaces = 0;
    for (int i = 0; i < line.length; i++) {
      if (line[i] == ' ') leadingSpaces++;
      else if (line[i] == '\t') leadingSpaces += 4;
      else break;
    }

    final double indent = (leadingSpaces * 1.2).clamp(0.0, 40.0);
    final double contentWidth = (line.trim().length * 1.5).clamp(2.0, 50.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        children: [
          SizedBox(width: indent),
          Container(
            height: 2,
            width: contentWidth,
            decoration: BoxDecoration(
              color: ui.colors.textMuted.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(0.5),
            ),
          ),
        ],
      ),
    );
  }
}