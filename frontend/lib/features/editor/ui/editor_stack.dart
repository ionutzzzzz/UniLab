import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/matlab.dart';
import 'package:provider/provider.dart';
import '../../../theme/ui_theme.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/app_provider.dart';
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
  Timer? _autoSaveTimer;

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
    _controller.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    final settings = context.read<SettingsProvider>().settings;
    if (settings.autoSave) {
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer(const Duration(seconds: 2), () {
        context.read<AppProvider>().saveActiveFile();
      });
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
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
    final settings = context.watch<SettingsProvider>().settings;

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
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          const EditorBreadcrumbs(
                            pathSegments: ['src', 'control', 'step.m'],
                          ),
                          Expanded(
                            child: EditorSurface(
                              controller: _controller,
                              focusNode: _focusNode,
                            ),
                          ),
                        ],
                      ),
                      if (_showFindReplace)
                        Positioned(
                          top: 0,
                          right: 20,
                          child: FindReplaceBar(onClose: _toggleFindReplace),
                        ),
                    ],
                  ),
                ),
                // Minimap Placeholder
                if (settings.showMinimap)
                  _EditorMinimap(controller: _controller),
              ],
            ),
          ),
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
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: ui.colors.canvas,
        border: Border(left: BorderSide(color: ui.colors.divider.withValues(alpha: 0.3))),
      ),
      child: Opacity(
        opacity: 0.3,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(100, (index) {
                final width = (index % 5 == 0) ? 20.0 : (index % 3 == 0 ? 40.0 : 30.0);
                return Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  height: 2,
                  width: width,
                  color: ui.colors.textMuted,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}