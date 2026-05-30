import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/ui_theme.dart';
import '../../models/editor_models.dart';
import 'line_number_gutter.dart';
import 'editor_breadcrumbs.dart';
import 'find_replace_bar.dart';

class EnhancedCodeEditor extends ConsumerStatefulWidget {
  final OpenFile file;
  final VoidCallback? onSave;
  final Function(String)? onChanged;

  const EnhancedCodeEditor({
    super.key,
    required this.file,
    this.onSave,
    this.onChanged,
  });

  @override
  ConsumerState<EnhancedCodeEditor> createState() => _EnhancedCodeEditorState();
}

class _EnhancedCodeEditorState extends ConsumerState<EnhancedCodeEditor> {
  late CodeController _codeController;
  late ScrollController _verticalScrollController;
  late ScrollController _horizontalScrollController;
  
  bool _isFindOpen = false;
  final Set<int> _breakpoints = {};
  int? _activeExecutionLine;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: widget.file.content,
      language: null, 
    );
    _verticalScrollController = ScrollController();
    _horizontalScrollController = ScrollController();
  }

  @override
  void didUpdateWidget(EnhancedCodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.id != widget.file.id) {
      _codeController.text = widget.file.content;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _onBreakpointToggle(int line) {
    setState(() {
      if (_breakpoints.contains(line)) {
        _breakpoints.remove(line);
      } else {
        _breakpoints.add(line);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final lineCount = '\n'.allMatches(_codeController.text).length + 1;

    return Column(
      children: [
        EditorBreadcrumbs(
          filePath: widget.file.path,
          symbols: const ['main()', 'calculate_physics()', 'render_frame()'],
          activeSymbol: 'calculate_physics()',
          onSymbolSelected: (symbol) {},
        ),
        
        Expanded(
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LineNumberGutter(
                    lineCount: lineCount,
                    scrollController: _verticalScrollController,
                    breakpoints: _breakpoints,
                    activeLine: _activeExecutionLine,
                    onBreakpointToggle: _onBreakpointToggle,
                    lineHeight: 18.2, // Match exactly
                    paddingTop: 8.0, // Match exactly
                  ),
                  
                  Expanded(
                    child: Container(
                      color: ui.colors.canvas,
                      child: CodeTheme(
                        data: CodeThemeData(styles: monokaiSublimeTheme),
                        child: SingleChildScrollView(
                          controller: _verticalScrollController,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: CodeField(
                              controller: _codeController,
                              onChanged: (val) {
                                widget.onChanged?.call(val);
                                setState(() {});
                              },

                              textStyle: ui.typography.codeBody.copyWith(
                                fontSize: 13,
                                height: 1.4, // lineHeight = 13 * 1.4 = 18.2
                                color: ui.colors.textPrimary,
                              ),
                              cursorColor: ui.colors.accent,
                              gutterStyle: GutterStyle.none,
                              background: ui.colors.canvas,
                              // Increased horizontal padding for better spacing
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              if (_isFindOpen)
                Positioned(
                  top: 10,
                  right: 20,
                  child: FindReplaceBar(
                    onClose: () => setState(() => _isFindOpen = false),
                    onFind: (query) {},
                  ),
                ),
            ],
          ),
        ),
        
        _buildEditorStatusBar(ui),
      ],
    );
  }

  Widget _buildEditorStatusBar(UiTheme ui) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ui.colors.panelHeader,
        border: Border(
          top: BorderSide(color: ui.colors.border, width: ui.spacing.strokeHair),
        ),
      ),
      child: Row(
        children: [
          _buildStatusItem(ui, 'Line: 12, Col: 45'),
          const SizedBox(width: 16),
          _buildStatusItem(ui, 'Spaces: 4'),
          const SizedBox(width: 16),
          _buildStatusItem(ui, 'UTF-8'),
          const Spacer(),
          _buildStatusItem(ui, 'Python', icon: LucideIcons.code2),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => setState(() => _isFindOpen = !_isFindOpen),
            child: Icon(
              LucideIcons.search,
              size: 12,
              color: _isFindOpen ? ui.colors.accent : ui.colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(UiTheme ui, String text, {IconData? icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: ui.colors.textMuted),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: ui.typography.label.copyWith(
            fontSize: 10,
            color: ui.colors.textMuted,
          ),
        ),
      ],
    );
  }
}