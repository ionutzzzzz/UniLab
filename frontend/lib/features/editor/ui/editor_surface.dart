import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import '../../../theme/ui_theme.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

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

    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: Container(
        color: ui.colors.canvas,
        child: SingleChildScrollView(
          child: CodeField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            textStyle: ui.typography.codeBody.copyWith(color: ui.colors.textPrimary),
            background: ui.colors.canvas,
            cursorColor: ui.colors.textPrimary,
            gutterStyle: const GutterStyle(
              width: 46,
              margin: 8.0,
            ),
          ),
        ),
      ),
    );
  }
}
