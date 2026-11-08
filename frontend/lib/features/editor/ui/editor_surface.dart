import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import '../../../theme/ui_theme.dart';
import '../../../theme/syntax_themes.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_button.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/riverpod_providers.dart';
import 'package:context_menus/context_menus.dart';

class EditorSurface extends ConsumerStatefulWidget {
  const EditorSurface({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  final CodeController controller;
  final FocusNode focusNode;

  @override
  ConsumerState<EditorSurface> createState() => _EditorSurfaceState();
}

class _EditorSurfaceState extends ConsumerState<EditorSurface> with AutomaticKeepAliveClientMixin {
  late ScrollController _verticalScrollController;
  late ScrollController _horizontalScrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _verticalScrollController = ScrollController();
    _horizontalScrollController = ScrollController();
    widget.controller.addListener(_updateCursorPosition);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateCursorPosition);
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _updateCursorPosition() {
    final selection = widget.controller.selection;
    if (selection.isValid) {
      final text = widget.controller.text;
      final offset = selection.baseOffset;
      
      int line = 1;
      int column = 1;
      
      for (int i = 0; i < offset; i++) {
        if (text[i] == '\n') {
          line++;
          column = 1;
        } else {
          column++;
        }
      }
      
      // Update provider
      Future.microtask(() {
        if (mounted) {
          ref.read(cursorPositionProvider.notifier).state = {
            'line': line,
            'column': column,
          };
        }
      });
    }
  }

  String _extractWordAtCursor() {
    final text = widget.controller.text;
    if (text.isEmpty) return '';
    final sel = widget.controller.selection;
    if (sel.isValid && !sel.isCollapsed) {
      return text.substring(sel.start, sel.end).trim();
    }
    final offset = sel.isValid ? sel.baseOffset.clamp(0, text.length) : 0;
    final wordRx = RegExp(r'[a-zA-Z_]\w*');
    for (final m in wordRx.allMatches(text)) {
      if (offset >= m.start && offset <= m.end) {
        return m.group(0)!;
      }
    }
    return '';
  }

  Future<void> _peekDefinition(BuildContext context) async {
    final ui = UiTheme.of(context);
    final appProvider = p.Provider.of<AppProvider>(context, listen: false);
    final symbol = _extractWordAtCursor();
    if (symbol.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Place the cursor on a function or variable name to peek definition.')),
      );
      return;
    }

    // 1. Check active or open files for function definition
    final fnDefRx = RegExp(
      r'^\s*function\s+(?:(?:\[[^\]]*\]|[a-zA-Z_]\w*)\s*=\s*)?' + RegExp.escape(symbol) + r'\b',
      multiLine: true,
    );

    String? matchedFileName;
    int? matchedLine;
    String? snippet;

    for (final file in appProvider.openFiles) {
      final lines = file.content.split('\n');
      for (int i = 0; i < lines.length; i++) {
        if (fnDefRx.hasMatch(lines[i])) {
          matchedFileName = file.name;
          matchedLine = i + 1;
          final end = (i + 12).clamp(0, lines.length);
          snippet = lines.sublist(i, end).join('\n');
          break;
        }
      }
      if (snippet != null) break;
    }

    // 2. If not found in open files, query backend help
    snippet ??= await appProvider.fetchHelp(symbol);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(Icons.code, size: 18, color: ui.colors.accent),
            const SizedBox(width: 8),
            UiText(
              text: matchedFileName != null
                  ? 'Definition: $symbol ($matchedFileName:$matchedLine)'
                  : 'Documentation: $symbol',
              variant: UiTextVariant.body,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ui.colors.canvas,
              borderRadius: ui.spacing.radiusSm,
              border: Border.all(color: ui.colors.border),
            ),
            child: SingleChildScrollView(
              child: UiText(
                text: (snippet == null || snippet.trim().isEmpty)
                    ? 'No definition or help documentation found for "$symbol".'
                    : snippet,
                variant: UiTextVariant.codeBody,
              ),
            ),
          ),
        ),
        actions: [
          if (matchedFileName != null && matchedLine != null)
            UiButton(
              label: 'Go to Line $matchedLine',
              variant: UiButtonVariant.primary,
              onPressed: () {
                Navigator.pop(dialogContext);
                appProvider.navigateToFileLine(matchedFileName, matchedLine!);
              },
            ),
          UiButton(
            label: 'Close',
            variant: UiButtonVariant.ghost,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  KeyEventResult _handleEditorKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final isCtrlOrMeta = pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight) ||
        pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight);
    final isShift = pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);

    final appProvider = context.read<AppProvider>();

    if (event.logicalKey == LogicalKeyboardKey.f5 ||
        (isCtrlOrMeta && event.logicalKey == LogicalKeyboardKey.enter)) {
      appProvider.updateActiveFileContent(widget.controller.text);
      appProvider.runActiveFile();
      return KeyEventResult.handled;
    }

    if (isCtrlOrMeta && event.logicalKey == LogicalKeyboardKey.keyS) {
      appProvider.updateActiveFileContent(widget.controller.text);
      if (isShift) {
        appProvider.saveActiveFileAs();
      } else {
        appProvider.saveActiveFile().then((_) {
          if (mounted) {
            final name = appProvider.activeFile?.name ?? 'file';
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved $name'),
                duration: const Duration(milliseconds: 1200),
              ),
            );
          }
        });
      }
      return KeyEventResult.handled;
    }

    if (isCtrlOrMeta && !isShift && event.logicalKey == LogicalKeyboardKey.keyF) {
      appProvider.triggerEditorAction('editor.find');
      return KeyEventResult.handled;
    }

    if (isCtrlOrMeta && !isShift && event.logicalKey == LogicalKeyboardKey.keyH) {
      appProvider.triggerEditorAction('editor.replace');
      return KeyEventResult.handled;
    }

    if (isCtrlOrMeta && !isShift && event.logicalKey == LogicalKeyboardKey.keyG) {
      appProvider.triggerEditorAction('editor.gotoLine');
      return KeyEventResult.handled;
    }

    if (isCtrlOrMeta && !isShift && event.logicalKey == LogicalKeyboardKey.slash) {
      appProvider.triggerEditorAction('editor.comment');
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ui = UiTheme.of(context);
    final settings = p.Provider.of<SettingsProvider>(context).settings;

    // Get selected syntax theme colors
    final highlightTheme = SyntaxHighlightTheme.all.firstWhere(
      (m) => m.name == settings.syntaxHighlightTheme,
      orElse: () => SyntaxHighlightTheme.all.first,
    );
    final colors = highlightTheme.colors;
    final editorBg = highlightTheme.backgroundColor;
    final Color editorFg = highlightTheme.foregroundColor;
    final List<Color> syntaxColors = List.from(highlightTheme.colors);

    // Custom Syntax Theme
    final Map<String, TextStyle> customSyntaxTheme = {
      'root': TextStyle(
        color: editorFg,
        backgroundColor: editorBg,
        fontSize: settings.fontSize,
        fontFamily: settings.fontFamily,
      ),
      'keyword': TextStyle(color: syntaxColors[0], fontWeight: FontWeight.bold),
      'string': TextStyle(color: syntaxColors[1]),
      'number': TextStyle(color: syntaxColors[2]),
      'comment': TextStyle(color: editorFg.withValues(alpha: 0.5)),
      'function': TextStyle(color: syntaxColors[3]),
      'params': TextStyle(color: editorFg.withValues(alpha: 0.8)),
      'builtin': TextStyle(color: syntaxColors[5].withValues(alpha: 0.9)),
      'literal': TextStyle(color: syntaxColors[4]),
      'title': TextStyle(color: syntaxColors[5], fontWeight: FontWeight.bold),
      'attr': TextStyle(color: editorFg.withValues(alpha: 0.8)),
      'variable': TextStyle(color: editorFg),
      'operator': TextStyle(color: editorFg.withValues(alpha: 0.7)),
    };

    final isExecuting = context.select<AppProvider, bool>((p) => p.isExecuting);

    return Focus(
      onKeyEvent: _handleEditorKeyEvent,
      child: Listener(
        onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final isCtrlPressed = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight) ||
                                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaLeft) ||
                                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaRight);
          if (isCtrlPressed) {
            final provider = context.read<SettingsProvider>();
            final currentSize = provider.settings.fontSize;
            // scrollDelta.dy > 0 means scroll down (zoom out), < 0 means scroll up (zoom in)
            final newSize = (currentSize - (pointerSignal.scrollDelta.dy > 0 ? 1 : -1)).clamp(8.0, 48.0);
            if (newSize != currentSize) {
              provider.updateSettings(provider.settings.copyWith(fontSize: newSize));
            }
          }
        }
      },
      child: CodeTheme(
        data: CodeThemeData(styles: customSyntaxTheme),
        child: Container(
          color: editorBg,
          child: Builder(
            builder: (context) {
              final viewportWidth = MediaQuery.of(context).size.width;
              final codeField = ContextMenuRegion(
                contextMenu: GenericContextMenu(
                  buttonConfigs: [
                    ContextMenuButtonConfig(
                      'Cut',
                      icon: const Icon(Icons.content_cut, size: 16),
                      onPressed: () {
                        final sel = widget.controller.selection;
                        if (sel.isValid && !sel.isCollapsed) {
                          final selectedText = widget.controller.text
                              .substring(sel.start, sel.end);
                          Clipboard.setData(ClipboardData(text: selectedText));
                          final newText = widget.controller.text
                              .replaceRange(sel.start, sel.end, '');
                          widget.controller.text = newText;
                          widget.controller.selection =
                              TextSelection.collapsed(offset: sel.start);
                        }
                      },
                    ),
                    ContextMenuButtonConfig(
                      'Copy',
                      icon: const Icon(Icons.content_copy, size: 16),
                      onPressed: () {
                        final sel = widget.controller.selection;
                        if (sel.isValid && !sel.isCollapsed) {
                          final selectedText = widget.controller.text
                              .substring(sel.start, sel.end);
                          Clipboard.setData(ClipboardData(text: selectedText));
                        }
                      },
                    ),
                    ContextMenuButtonConfig(
                      'Paste',
                      icon: const Icon(Icons.content_paste, size: 16),
                      onPressed: () async {
                        final data =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) {
                          final sel = widget.controller.selection;
                          final pos = sel.isValid
                              ? sel.start
                              : widget.controller.text.length;
                          final end = sel.isValid ? sel.end : pos;
                          final newText = widget.controller.text
                              .replaceRange(pos, end, data!.text!);
                          widget.controller.text = newText;
                          widget.controller.selection = TextSelection.collapsed(
                            offset: pos + data.text!.length,
                          );
                        }
                      },
                    ),
                    ContextMenuButtonConfig(
                      'Run Selection',
                      icon: Icon(
                        Icons.play_arrow,
                        size: 16,
                        color: isExecuting ? ui.colors.textDisabled : ui.colors.accent,
                      ),
                      onPressed: isExecuting
                          ? null
                          : () {
                              final sel = widget.controller.selection;
                              if (sel.isValid && !sel.isCollapsed) {
                                final selectedText = widget.controller.text
                                    .substring(sel.start, sel.end);
                                p.Provider.of<AppProvider>(
                                  context,
                                  listen: false,
                                ).runConsoleCommand(selectedText);
                              } else {
                                p.Provider.of<AppProvider>(
                                  context,
                                  listen: false,
                                ).runActiveFile();
                              }
                            },
                    ),
                    ContextMenuButtonConfig(
                      'Toggle Comment',
                      icon: const Icon(Icons.comment, size: 16),
                      onPressed: () {
                        p.Provider.of<AppProvider>(
                          context,
                          listen: false,
                        ).triggerEditorAction('editor.comment');
                      },
                    ),
                    ContextMenuButtonConfig(
                      'Auto Indent',
                      icon: const Icon(Icons.format_indent_increase, size: 16),
                      onPressed: () {
                        p.Provider.of<AppProvider>(
                          context,
                          listen: false,
                        ).triggerEditorAction('editor.autoIndent');
                      },
                    ),
                    ContextMenuButtonConfig(
                      'Peek Definition',
                      icon: Icon(Icons.code, size: 16, color: ui.colors.info),
                      onPressed: () => _peekDefinition(context),
                    ),
                    ContextMenuButtonConfig(
                      'Find',
                      icon: const Icon(Icons.search, size: 16),
                      onPressed: () {
                        p.Provider.of<AppProvider>(
                          context,
                          listen: false,
                        ).triggerEditorAction('editor.find');
                      },
                    ),
                  ],
                ),
                child: CodeField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  wrap: settings.wordWrap,
                  textStyle: ui.typography.codeBody.copyWith(
                    color: editorFg,
                    height: 1.5,
                    fontSize: settings.fontSize,
                    fontFamily: settings.fontFamily,
                  ),
                  background: editorBg,
                  cursorColor: colors[0],
                  gutterStyle: GutterStyle(
                    showLineNumbers: settings.showLineNumbers,
                    width: 80,
                    margin: 20,
                    textAlign: TextAlign.right,
                    textStyle: ui.typography.label.copyWith(
                      color: editorFg.withValues(alpha: 0.3),
                      fontSize: 11,
                      height: 1.5,
                      fontFamily: settings.fontFamily,
                    ),
                  ),
                ),
              );

              if (settings.wordWrap) {
                return SingleChildScrollView(
                  key: const PageStorageKey('editor_v_scroll'),
                  controller: _verticalScrollController,
                  child: codeField,
                );
              }

              return SingleChildScrollView(
                key: const PageStorageKey('editor_v_scroll_no_wrap'),
                controller: _verticalScrollController,
                child: SingleChildScrollView(
                  key: const PageStorageKey('editor_h_scroll'),
                  controller: _horizontalScrollController,
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
    );
  }
}
