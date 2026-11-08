import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/matlab.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path_utils;
import 'package:undo/undo.dart';
import 'package:unilab/theme/ui_theme.dart';
import 'package:unilab/widgets/ui_text.dart';
import 'package:unilab/providers/settings_provider.dart';
import 'package:unilab/providers/app_provider.dart';
import 'package:unilab/models/models.dart';
import 'package:unilab/utils/file_manager.dart';
import 'package:unilab/features/editor/ui/editor_tab_bar.dart';
import 'package:unilab/features/editor/ui/editor_breadcrumbs.dart';
import 'package:unilab/features/editor/ui/editor_surface.dart';
import 'package:unilab/features/editor/ui/find_replace_bar.dart';

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
  final Map<String, CodeController> _controllers = {};
  final Map<String, ChangeStack> _undoStacks = {};
  final FocusNode _focusNode = FocusNode();
  final FocusNode _secondaryFocusNode = FocusNode();
  bool _showFindReplace = false;
  bool _isReplaceMode = true;
  Timer? _autoSaveTimer;
  Timer? _undoTimer;
  StreamSubscription? _actionSubscription;
  bool _isUndoingOrRedoing = false;

  CodeController _getOrCreateController(UniLabFile file) {
    if (!_controllers.containsKey(file.id)) {
      final controller = CodeController(
        text: file.content,
        language: matlab,
      );
      controller.addListener(_onCodeChanged);
      _controllers[file.id] = controller;
      _undoStacks[file.id] = ChangeStack();
    }
    return _controllers[file.id]!;
  }

  void _flushControllersToProvider() {
    if (!mounted) return;
    _debounceTimer?.cancel();
    final appProvider = context.read<AppProvider>();
    for (final entry in _controllers.entries) {
      appProvider.updateFileContent(entry.key, entry.value.text);
    }
  }

  CodeController? get _activeController {
    final activeFile = context.read<AppProvider>().activeFile;
    if (activeFile == null) return null;
    return _getOrCreateController(activeFile);
  }

  @override
  void initState() {
    super.initState();

    // Listen to actions from Ribbon via AppProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appProvider = context.read<AppProvider>();
      appProvider.registerEditorFlushCallback(_flushControllersToProvider);
      _actionSubscription = appProvider.editorActions.listen((action) {
        debugPrint('EditorStack: Received editor action: $action');
        if (!mounted) {
          debugPrint('EditorStack: Not mounted, ignoring action');
          return;
        }
        
        final activeFile = appProvider.activeFile;
        if (activeFile == null) return;

        if (action == 'file.save') {
          _flushControllersToProvider();
          appProvider.saveActiveFile();
          return;
        }

        if (action == 'file.saveAs') {
          _flushControllersToProvider();
          appProvider.saveActiveFileAs();
          return;
        }

        if (action == 'editor.syncFromProvider') {
          final ctrl = _controllers[activeFile.id];
          if (ctrl != null && ctrl.text != activeFile.content) {
            ctrl.text = activeFile.content;
            ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
          }
          setState(() {});
          return;
        }
        
        final controller = _controllers[activeFile.id];
        final stack = _undoStacks[activeFile.id];
        if (controller == null || stack == null) return;

        if (action.startsWith('editor.gotoLine:')) {
          final parts = action.split(':');
          final line = parts.length > 1 ? int.tryParse(parts[1]) : null;
          final col = parts.length > 2 ? (int.tryParse(parts[2]) ?? 1) : 1;
          if (line != null) {
            _goToLine(controller, line, col);
          }
          return;
        }

        switch (action) {
          case 'editor.find':
            setState(() {
              if (_showFindReplace && !_isReplaceMode) {
                _showFindReplace = false;
              } else {
                _showFindReplace = true;
                _isReplaceMode = false;
              }
            });
            break;
          case 'editor.replace':
            setState(() {
              if (_showFindReplace && _isReplaceMode) {
                _showFindReplace = false;
              } else {
                _showFindReplace = true;
                _isReplaceMode = true;
              }
            });
            break;
          case 'editor.gotoLine':
            _showGoToLineDialog();
            break;
          case 'editor.autoIndent':
            _autoIndentCode(activeFile.id, controller, stack);
            break;
          case 'editor.comment':
            _toggleCommentSelection(activeFile.id, controller, stack);
            break;
          case 'editor.undo':
            if (stack.canUndo) {
              _isUndoingOrRedoing = true;
              stack.undo();
              _isUndoingOrRedoing = false;
            }
            break;
          case 'editor.redo':
            if (stack.canRedo) {
              _isUndoingOrRedoing = true;
              stack.redo();
              _isUndoingOrRedoing = false;
            }
            break;
        }
      });
    });
  }

  void _applyControllerEdit(
    String fileId,
    CodeController controller,
    ChangeStack stack,
    String newText, {
    TextSelection? selection,
  }) {
    final oldText = controller.text;
    if (oldText == newText) return;
    final appProvider = context.read<AppProvider>();

    _isUndoingOrRedoing = true;
    controller.text = newText;
    if (selection != null) {
      controller.selection = selection;
    }
    appProvider.updateFileContent(fileId, newText);
    _isUndoingOrRedoing = false;

    stack.add(
      Change(
        oldText,
        () {
          if (controller.text != newText) {
            _isUndoingOrRedoing = true;
            controller.text = newText;
            appProvider.updateFileContent(fileId, newText);
            _isUndoingOrRedoing = false;
          }
        },
        (old) {
          if (controller.text != old) {
            _isUndoingOrRedoing = true;
            controller.text = old;
            appProvider.updateFileContent(fileId, old);
            _isUndoingOrRedoing = false;
          }
        },
      ),
    );
  }

  void _autoIndentCode(String fileId, CodeController controller, ChangeStack stack) {
    final tabSize = context.read<SettingsProvider>().settings.tabSize;
    final indentUnit = ' ' * tabSize;
    final lines = controller.text.split('\n');
    final formatted = <String>[];
    int depth = 0;

    final increaseRx = RegExp(r'^(function|for|while|if|switch|try)\b');
    final middleRx = RegExp(r'^(else|elseif|case|otherwise|catch)\b');
    final decreaseRx = RegExp(r'^end\b');

    for (final rawLine in lines) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) {
        formatted.add('');
        continue;
      }
      final codeOnly = trimmed.replaceAll(RegExp(r'%.*$'), '').trim();
      int lineDepth = depth;
      if (decreaseRx.hasMatch(codeOnly) || middleRx.hasMatch(codeOnly)) {
        lineDepth = math.max(0, depth - 1);
      }
      formatted.add('${indentUnit * lineDepth}$trimmed');

      if (decreaseRx.hasMatch(codeOnly)) {
        depth = math.max(0, depth - 1);
      } else if (increaseRx.hasMatch(codeOnly)) {
        final inlineEnd = RegExp(r'\bend\s*;?\s*$').hasMatch(codeOnly);
        if (!inlineEnd) {
          depth++;
        }
      }
    }

    _applyControllerEdit(fileId, controller, stack, formatted.join('\n'));
  }

  void _toggleCommentSelection(String fileId, CodeController controller, ChangeStack stack) {
    final text = controller.text;
    final sel = controller.selection;
    final startOffset = sel.isValid ? math.min(sel.start, sel.end) : 0;
    final endOffset = sel.isValid ? math.max(sel.start, sel.end) : 0;

    final lines = text.split('\n');
    int charCount = 0;
    int startLine = 0;
    int endLine = 0;

    for (int i = 0; i < lines.length; i++) {
      final lineStart = charCount;
      final lineEnd = charCount + lines[i].length;
      if (startOffset >= lineStart && startOffset <= lineEnd) {
        startLine = i;
      }
      if (endOffset >= lineStart && endOffset <= lineEnd) {
        endLine = i;
      }
      charCount = lineEnd + 1;
    }

    bool allCommented = true;
    for (int i = startLine; i <= endLine; i++) {
      final t = lines[i].trimLeft();
      if (t.isNotEmpty && !t.startsWith('%')) {
        allCommented = false;
        break;
      }
    }

    for (int i = startLine; i <= endLine; i++) {
      if (allCommented) {
        lines[i] = lines[i].replaceFirst(RegExp(r'%\s?'), '');
      } else {
        lines[i] = '% ${lines[i]}';
      }
    }

    _applyControllerEdit(fileId, controller, stack, lines.join('\n'));
  }

  void _showGoToLineDialog() {
    final ui = UiTheme.of(context);
    final controller = TextEditingController();
    final activeController = _activeController;
    if (activeController == null) return;
    
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
              _goToLine(activeController, line);
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
                _goToLine(activeController, line);
              }
              Navigator.pop(context);
            },
            child: UiText(text: 'Go', color: ui.colors.accent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _goToLine(CodeController controller, int line, [int column = 1]) {
    if (line < 1) return;
    final text = controller.text;
    final lines = text.split('\n');
    final targetLine = line.clamp(1, lines.length);

    int pos = 0;
    for (int i = 0; i < targetLine - 1; i++) {
      pos += lines[i].length + 1;
    }
    final colOffset = (column - 1).clamp(0, lines[targetLine - 1].length);
    pos += colOffset;
    
    controller.selection = TextSelection.collapsed(offset: pos);
    _focusNode.requestFocus();
  }

  Timer? _debounceTimer;

  void _onCodeChanged() {
    final appProvider = context.read<AppProvider>();
    final activeFile = appProvider.activeFile;
    if (activeFile == null) return;

    final fileId = activeFile.id;
    final controller = _controllers[fileId];
    final stack = _undoStacks[fileId];
    if (controller == null || stack == null) return;

    // Only handle changes for text files
    if (activeFile.path.isNotEmpty && !UniLabFileManager.isTextFile(activeFile.path)) {
      return;
    }

    if (!_isUndoingOrRedoing) {
       _undoTimer?.cancel();
       final oldText = activeFile.content;
       final newText = controller.text;
       
       if (oldText != newText) {
          _undoTimer = Timer(const Duration(milliseconds: 500), () {
             stack.add(Change(
               oldText,
               () {
                  if (controller.text != newText) {
                    _isUndoingOrRedoing = true;
                    controller.text = newText;
                    appProvider.updateFileContent(fileId, newText);
                    _isUndoingOrRedoing = false;
                  }
               },
               (old) {
                  if (controller.text != old) {
                    _isUndoingOrRedoing = true;
                    controller.text = old;
                    appProvider.updateFileContent(fileId, old);
                    _isUndoingOrRedoing = false;
                  }
               },
             ));
          });
       }
    }

    // Debounce the provider update to avoid full-app rebuilds on every keystroke
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      appProvider.updateFileContent(fileId, controller.text);
    });

    final settings = context.read<SettingsProvider>().settings;
    if (settings.autoSave &&
        activeFile.path.isNotEmpty &&
        !activeFile.path.startsWith('Untitled') &&
        !activeFile.name.startsWith('Untitled')) {
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer(const Duration(seconds: 2), () {
        appProvider.saveActiveFile();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activeFile = context.read<AppProvider>().activeFile;
    
    if (activeFile != null) {
      final controller = _getOrCreateController(activeFile);
      
      // Sync from provider if not modified by editor
      if (controller.text != activeFile.content && !activeFile.isModified) {
         final currentSelection = controller.selection;
         controller.text = activeFile.content;
         if (currentSelection.isValid && currentSelection.baseOffset <= controller.text.length) {
            controller.selection = currentSelection;
         }
      }
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _undoTimer?.cancel();
    _debounceTimer?.cancel();
    _actionSubscription?.cancel();
    for (final controller in _controllers.values) {
      controller.removeListener(_onCodeChanged);
      controller.dispose();
    }
    _focusNode.dispose();
    _secondaryFocusNode.dispose();
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
    final activeFile = context.select<AppProvider, UniLabFile?>((p) => p.activeFile);
    final openFiles = context.select<AppProvider, List<UniLabFile>>((p) => p.openFiles);
    final isSplitEditor = context.select<AppProvider, bool>((p) => p.isSplitEditor);
    final secondaryFile = context.select<AppProvider, UniLabFile?>((p) => p.secondaryFile);
    final isShowMinimap = context.select<SettingsProvider, bool>((s) => s.settings.showMinimap);

    if (activeFile == null) {
      return _buildEmptyState(ui);
    }

    final controller = _getOrCreateController(activeFile);
    
    final tabs = openFiles.map((f) => EditorTabModel(
      id: f.id,
      title: f.name,
      isActive: f.id == activeFile.id,
      isDirty: f.isModified,
    )).toList();

    Widget content;
    bool effectiveShowMinimap = false;

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
        key: ValueKey('surface_${activeFile.id}'),
        controller: controller,
        focusNode: _focusNode,
      );
      effectiveShowMinimap = isShowMinimap;
    }

    return Container(
      color: ui.colors.canvas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showTabs = constraints.maxHeight > 30;
          final appProvider = context.read<AppProvider>();
          
          return Column(
            children: [
              if (showTabs)
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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final showBreadcrumbs = constraints.maxHeight > 50;
                              return Column(
                                children: [
                                  if (showBreadcrumbs)
                                    EditorBreadcrumbs(
                                      pathSegments: activeFile.path.isNotEmpty 
                                          ? path_utils.split(activeFile.path)
                                          : [activeFile.name],
                                    ),
                                  Expanded(child: content),
                                ],
                              );
                            },
                          ),
                           if (_showFindReplace) 
                            Positioned(
                              top: 8,
                              right: 20,
                              width: math.min(
                                400.0,
                                math.max(260.0, constraints.maxWidth - 32),
                              ),
                              child: FindReplaceBar(
                                onClose: _toggleFindReplace,
                                isReplaceMode: _isReplaceMode,
                                controller: controller,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (effectiveShowMinimap)
                      _EditorMinimap(
                        controller: controller,
                        onLineSelected: (line) => _goToLine(controller, line),
                      ),
                    if (isSplitEditor && secondaryFile != null) ...[
                      Container(width: 1, color: ui.colors.divider),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 28,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: ui.colors.panelHeader.withValues(alpha: 0.6),
                                border: Border(
                                  bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.vertical_split, size: 13, color: ui.colors.accent),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: secondaryFile.id,
                                        isDense: true,
                                        dropdownColor: ui.colors.panel,
                                        style: TextStyle(color: ui.colors.textPrimary, fontSize: 11),
                                        items: openFiles
                                            .map(
                                              (f) => DropdownMenuItem(
                                                value: f.id,
                                                child: Text(f.name),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (selectedId) {
                                          if (selectedId == null) return;
                                          final idx = openFiles.indexWhere((f) => f.id == selectedId);
                                          if (idx != -1) {
                                            appProvider.setSecondaryFile(idx);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, size: 13, color: ui.colors.textMuted),
                                    tooltip: 'Close Split View',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                                    onPressed: () => appProvider.toggleSplitEditor(),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: EditorSurface(
                                key: ValueKey('split_surface_${secondaryFile.id}'),
                                controller: _getOrCreateController(secondaryFile),
                                focusNode: _secondaryFocusNode,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.code, size: 48, color: ui.colors.textDisabled),
            const SizedBox(height: 16),
            const UiText(text: 'No file open', variant: UiTextVariant.body),
          ],
        ),
      ),
    );
  }
}

class _EditorMinimap extends StatelessWidget {
  const _EditorMinimap({
    required this.controller,
    required this.onLineSelected,
  });
  final CodeController controller;
  final ValueChanged<int> onLineSelected;

  void _handlePosition(Offset localPosition, int totalLines) {
    if (totalLines <= 0) return;
    final clickedLine = ((localPosition.dy - 8.0) / 3.0).round() + 1;
    onLineSelected(clickedLine.clamp(1, totalLines));
  }

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
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) => _handlePosition(details.localPosition, lines.length),
                    onVerticalDragUpdate: (details) => _handlePosition(details.localPosition, lines.length),
                    child: Container(
                      color: Colors.transparent,
                    ),
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
      if (line[i] == ' ') {
        leadingSpaces++;
      } else if (line[i] == '\t') {
        leadingSpaces += 4;
      } else {
        break;
      }
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