import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/matlab.dart';
import '../../../theme/ui_theme.dart';
import 'editor_tab_bar.dart';
import 'editor_breadcrumbs.dart';
import 'editor_surface.dart';
import 'find_replace_bar.dart';

class EditorStack extends StatefulWidget {
  const EditorStack({super.key});

  @override
  State<EditorStack> createState() => _EditorStackState();
}

class _EditorStackState extends State<EditorStack> {
  late CodeController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _showFindReplace = false;

  final List<EditorTabModel> _tabs = [
    const EditorTabModel(id: '1', title: 'untitled.m', isActive: true),
    const EditorTabModel(id: '2', title: 'analysis.m', isDirty: true),
    const EditorTabModel(id: '3', title: 'data.csv'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: 'function y = step(t, a)\n    y = a .* (1 - exp(-t));\nend\n',
      language: matlab,
    );
  }

  @override
  void dispose() {
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
    return Container(
      color: ui.colors.canvas,
      child: Column(
        children: [
          EditorTabBar(
            tabs: _tabs,
            onTabTap: (id) {},
            onTabClose: (id) {},
            onNewTab: () {},
          ),
          const EditorBreadcrumbs(
            pathSegments: ['src', 'control', 'step.m'],
          ),
          if (_showFindReplace)
            FindReplaceBar(onClose: _toggleFindReplace),
          Expanded(
            child: EditorSurface(
              controller: _controller,
              focusNode: _focusNode,
            ),
          ),
        ],
      ),
    );
  }
}