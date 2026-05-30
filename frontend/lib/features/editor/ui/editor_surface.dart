import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:provider/provider.dart';
import '../../../theme/ui_theme.dart';
import '../../../theme/syntax_themes.dart';
import '../../../providers/settings_provider.dart';
import 'package:context_menus/context_menus.dart';

class EditorSurface extends StatefulWidget {
  const EditorSurface({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  final CodeController controller;
  final FocusNode focusNode;

  @override
  State<EditorSurface> createState() => _EditorSurfaceState();
}

class _EditorSurfaceState extends State<EditorSurface> {
  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final settings = context.watch<SettingsProvider>().settings;

    // Get selected syntax theme colors
    final highlightTheme = SyntaxHighlightTheme.all.firstWhere(
      (m) => m.name == settings.syntaxHighlightTheme,
      orElse: () => SyntaxHighlightTheme.all.first,
    );
    final colors = highlightTheme.colors;
    final editorBg = highlightTheme.backgroundColor;
    final editorFg = highlightTheme.foregroundColor;

    // Custom Syntax Theme using Common IDE Palettes
    final Map<String, TextStyle> customSyntaxTheme = {
      'root': TextStyle(
        color: editorFg, 
        backgroundColor: editorBg,
        fontSize: settings.fontSize,
        fontFamily: settings.fontFamily,
      ),
      'keyword': TextStyle(color: colors[0], fontWeight: FontWeight.bold),
      'string': TextStyle(color: colors[1]),
      'number': TextStyle(color: colors[2]),
      'comment': TextStyle(color: editorFg.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
      'function': TextStyle(color: colors[3]),
      'params': TextStyle(color: editorFg.withValues(alpha: 0.8)),
      'builtin': TextStyle(color: colors[5].withValues(alpha: 0.9)),
      'literal': TextStyle(color: colors[4]),
      'title': TextStyle(color: colors[5], fontWeight: FontWeight.bold),
      'attr': TextStyle(color: editorFg.withValues(alpha: 0.8)),
      'variable': TextStyle(color: editorFg),
      'operator': TextStyle(color: editorFg.withValues(alpha: 0.7)),
    };

    return ContextMenuRegion(
      contextMenu: GenericContextMenu(
        buttonConfigs: [
          ContextMenuButtonConfig('Cut', icon: Icon(Icons.content_cut, size: 16, color: ui.colors.textMuted), onPressed: () {}),
          ContextMenuButtonConfig('Copy', icon: Icon(Icons.content_copy, size: 16, color: ui.colors.textMuted), onPressed: () {}),
          ContextMenuButtonConfig('Paste', icon: Icon(Icons.content_paste, size: 16, color: ui.colors.textMuted), onPressed: () {}),
          ContextMenuButtonConfig('Run Selection', icon: Icon(Icons.play_arrow, size: 16, color: ui.colors.accent), onPressed: () {}),
          ContextMenuButtonConfig('Peek Definition', icon: Icon(Icons.search, size: 16, color: ui.colors.info), onPressed: () {}),
        ],
      ),
      child: CodeTheme(
        data: CodeThemeData(styles: customSyntaxTheme),
        child: Container(
          color: editorBg,
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
            cursorColor: colors[0], // Use keyword color as cursor
            gutterStyle: GutterStyle(
              showLineNumbers: settings.showLineNumbers,
              width: 52,
              margin: 12,
              textAlign: TextAlign.right,
              textStyle: ui.typography.label.copyWith(
                color: editorFg.withValues(alpha: 0.3),
                fontSize: 11,
                fontFamily: settings.fontFamily,
              ),
            ),
          ),
        ),
      ),
    );
  }
}