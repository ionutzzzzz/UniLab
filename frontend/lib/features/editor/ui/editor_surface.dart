import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import '../../../theme/ui_theme.dart';
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

    // Custom "Deep Pastel" Syntax Theme using Matplotlib Palette
    final Map<String, TextStyle> customSyntaxTheme = {
      'root': TextStyle(color: ui.colors.textPrimary, backgroundColor: ui.colors.canvas),
      'keyword': TextStyle(color: ui.colors.accent, fontWeight: FontWeight.bold), // Pastel Blue
      'string': TextStyle(color: ui.colors.success), // Pastel Green
      'number': TextStyle(color: ui.colors.warning), // Pastel Orange
      'comment': TextStyle(color: ui.colors.textDisabled, fontStyle: FontStyle.italic),
      'function': TextStyle(color: ui.colors.info), // Pastel Purple
      'params': TextStyle(color: ui.colors.textSecondary),
      'builtin': TextStyle(color: ui.colors.info.withOpacity(0.8)),
      'literal': TextStyle(color: ui.colors.warning),
      'title': TextStyle(color: ui.colors.accent, fontWeight: FontWeight.bold),
      'attr': TextStyle(color: ui.colors.textSecondary),
      'variable': TextStyle(color: ui.colors.textPrimary),
      'operator': TextStyle(color: ui.colors.textMuted),
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
          color: ui.colors.canvas,
          child: CodeField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            textStyle: ui.typography.codeBody.copyWith(
              color: ui.colors.textPrimary,
              height: 1.5,
              fontSize: 13,
            ),
            background: ui.colors.canvas,
            cursorColor: ui.colors.accent,
            lineNumberStyle: LineNumberStyle(
              width: 52,
              margin: 12,
              textAlign: TextAlign.right,
              textStyle: ui.typography.label.copyWith(
                color: ui.colors.textMuted.withOpacity(0.4),
                fontSize: 11,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
