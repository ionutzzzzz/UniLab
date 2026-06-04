import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import '../../../theme/ui_theme.dart';
import '../../../theme/syntax_themes.dart';
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

class _EditorSurfaceState extends ConsumerState<EditorSurface> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateCursorPosition);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateCursorPosition);
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

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final settings = p.Provider.of<SettingsProvider>(context).settings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get selected syntax theme colors
    final highlightTheme = SyntaxHighlightTheme.all.firstWhere(
      (m) => m.name == settings.syntaxHighlightTheme,
      orElse: () => SyntaxHighlightTheme.all.first,
    );
    final colors = highlightTheme.colors;
    
    final isInterfaceLight = !isDark;
    final editorBg = isInterfaceLight ? Colors.white : highlightTheme.backgroundColor;
    
    Color editorFg = highlightTheme.foregroundColor;
    List<Color> syntaxColors = List.from(highlightTheme.colors);

    if (isInterfaceLight) {
      // Force default text to be dark in light mode if it's too light
      if (editorFg.computeLuminance() > 0.6) {
        editorFg = const Color(0xFF24292E); // Dark gray/black
      }
      
      // Darken syntax colors if they are too light for a white background
      for (int i = 0; i < syntaxColors.length; i++) {
        if (syntaxColors[i].computeLuminance() > 0.7) {
          final hsl = HSLColor.fromColor(syntaxColors[i]);
          syntaxColors[i] = hsl.withLightness((hsl.lightness - 0.3).clamp(0.0, 0.7)).toColor();
        } else if (syntaxColors[i].computeLuminance() > 0.4 && syntaxColors[i].computeLuminance() < 0.7) {
          // Slightly darken mid-range colors for better contrast
          final hsl = HSLColor.fromColor(syntaxColors[i]);
          syntaxColors[i] = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 0.7)).toColor();
        }
      }
    }

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

    final appProvider = p.Provider.of<AppProvider>(context);

    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final isCtrlPressed = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight) ||
                                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaLeft) ||
                                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaRight);
          if (isCtrlPressed) {
            final provider = p.Provider.of<SettingsProvider>(context, listen: false);
            final currentSize = provider.settings.fontSize;
            // scrollDelta.dy > 0 means scroll down (zoom out), < 0 means scroll up (zoom in)
            final newSize = (currentSize - (pointerSignal.scrollDelta.dy > 0 ? 1 : -1)).clamp(8.0, 48.0);
            if (newSize != currentSize) {
              provider.updateSettings(provider.settings.copyWith(fontSize: newSize));
            }
          }
        }
      },
      child: ContextMenuRegion(
      contextMenu: GenericContextMenu(
        buttonConfigs: [
          ContextMenuButtonConfig(
            'Cut',
            icon: Icon(Icons.content_cut, size: 16, color: ui.colors.textMuted),
            onPressed: () {},
          ),
          ContextMenuButtonConfig(
            'Copy',
            icon: Icon(
              Icons.content_copy,
              size: 16,
              color: ui.colors.textMuted,
            ),
            onPressed: () {},
          ),
          ContextMenuButtonConfig(
            'Paste',
            icon: Icon(
              Icons.content_paste,
              size: 16,
              color: ui.colors.textMuted,
            ),
            onPressed: () {},
          ),
          ContextMenuButtonConfig(
            'Run Selection',
            icon: Icon(Icons.play_arrow, size: 16, color: appProvider.isExecuting ? ui.colors.textDisabled : ui.colors.accent),
            onPressed: appProvider.isExecuting ? null : () {},
          ),
          ContextMenuButtonConfig(
            'Peek Definition',
            icon: Icon(Icons.search, size: 16, color: ui.colors.info),
            onPressed: () {},
          ),
        ],
      ),
      child: CodeTheme(
        data: CodeThemeData(styles: customSyntaxTheme),
        child: Container(
          color: editorBg,
          child: Builder(
            builder: (context) {
              final viewportWidth = MediaQuery.of(context).size.width;
              final codeField = CodeField(
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
              );

              if (settings.wordWrap) {
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
    ));
  }
}
