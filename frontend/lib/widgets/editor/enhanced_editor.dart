import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Enhanced editor with syntax highlighting, line numbers, and status
class EnhancedCodeEditor extends StatefulWidget {
  final String initialCode;
  final String fileName;
  final Function(String) onChanged;
  final Function()? onSave;
  final int activeLineNumber;
  final List<int> breakpoints;
  final Function(int)? onBreakpointToggle;

  const EnhancedCodeEditor({
    super.key,
    this.initialCode = '',
    required this.fileName,
    required this.onChanged,
    this.onSave,
    this.activeLineNumber = -1,
    this.breakpoints = const [],
    this.onBreakpointToggle,
  });

  @override
  State<EnhancedCodeEditor> createState() => _EnhancedCodeEditorState();
}

class _EnhancedCodeEditorState extends State<EnhancedCodeEditor> {
  late TextEditingController _controller;
  late ScrollController _verticalScrollController;
  late ScrollController _horizontalScrollController;
  late FocusNode _focusNode;
  int _lineCount = 1;
  int _currentLineNumber = 1;
  int _currentColumn = 1;
  String _language = 'dart';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCode);
    _verticalScrollController = ScrollController();
    _horizontalScrollController = ScrollController();
    _focusNode = FocusNode();
    _updateLineCount();
    _detectLanguage();

    _controller.addListener(() {
      _updateLineCount();
      _updateCursorPosition();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _detectLanguage() {
    final ext = widget.fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'm':
      case 'matlab':
        _language = 'matlab';
        break;
      case 'py':
      case 'python':
        _language = 'python';
        break;
      case 'cpp':
      case 'cc':
      case 'cxx':
        _language = 'cpp';
        break;
      case 'c':
        _language = 'c';
        break;
      case 'dart':
        _language = 'dart';
        break;
      default:
        _language = 'plaintext';
    }
  }

  void _updateLineCount() {
    final newLineCount = '\n'.allMatches(_controller.text).length + 1;
    if (newLineCount != _lineCount) {
      setState(() {
        _lineCount = newLineCount;
      });
    }
  }

  void _updateCursorPosition() {
    final text = _controller.text;
    final selection = _controller.selection;
    final position = selection.baseOffset;

    if (position < 0 || position > text.length) return;

    final lines = text.substring(0, position).split('\n');
    final line = lines.length;
    final column = lines.last.length + 1;

    setState(() {
      _currentLineNumber = line;
      _currentColumn = column;
    });
  }

  Widget _buildLineNumbers() {
    return Container(
      width: 50.0,
      decoration: BoxDecoration(
        color: AppTheme.editorLineNumberBackground,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(
            _lineCount,
            (index) {
              final lineNum = index + 1;
              final isActiveLine = lineNum == widget.activeLineNumber;
              final hasBreakpoint = widget.breakpoints.contains(lineNum);

              return GestureDetector(
                onSecondaryTap: () {
                  widget.onBreakpointToggle?.call(lineNum);
                },
                child: Container(
                  height: 18.4, // 13 * 1.4 line height
                  width: 50.0,
                  padding: const EdgeInsets.only(right: 8.0),
                  decoration: BoxDecoration(
                    color: isActiveLine
                        ? AppTheme.editorActiveLineBackground
                        : Colors.transparent,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      hasBreakpoint
                          ? Container(
                              width: 12.0,
                              height: 12.0,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF44336),
                                shape: BoxShape.circle,
                              ),
                            )
                          : const SizedBox(width: 12.0),
                      const SizedBox(width: 6.0),
                      Text(
                        '$lineNum',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          color: isActiveLine
                              ? AppTheme.editorGutterForeground
                              : const Color(0xFF858585),
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Editor with line numbers and text
        Expanded(
          child: Row(
            children: [
              _buildLineNumbers(),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (notification is ScrollUpdateNotification) {
                      _verticalScrollController.jumpTo(
                        notification.metrics.pixels,
                      );
                    }
                    return false;
                  },
                  child: Container(
                    color: AppTheme.darkCanvasBackground,
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 1200, // Default width, can be adjusted
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onChanged: widget.onChanged,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 13,
                            height: 1.4,
                            color: Color(0xFFCCCCCC),
                            backgroundColor: AppTheme.darkCanvasBackground,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 8.0,
                            ),
                            filled: true,
                            fillColor: AppTheme.darkCanvasBackground,
                          ),
                          scrollController: _verticalScrollController,
                          cursorColor: AppTheme.editorCursorColor,
                          cursorHeight: 18.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Status bar
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: AppTheme.darkRibbonBackground,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Line $_currentLineNumber, Column $_currentColumn',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    _language.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
              Text(
                'UTF-8 • CRLF',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tab bar for multiple open files with enhanced features
class EnhancedEditorTabBar extends StatefulWidget {
  final List<dynamic> openFiles; // List of OpenFile models
  final int activeIndex;
  final Function(int) onTabChanged;
  final Function(int) onTabClosed;
  final Function(int)? onTabMenu; // Right-click on tab

  const EnhancedEditorTabBar({
    super.key,
    required this.openFiles,
    required this.activeIndex,
    required this.onTabChanged,
    required this.onTabClosed,
    this.onTabMenu,
  });

  @override
  State<EnhancedEditorTabBar> createState() => _EnhancedEditorTabBarState();
}

class _EnhancedEditorTabBarState extends State<EnhancedEditorTabBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      color: AppTheme.darkRibbonBackground,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.openFiles.length,
        itemBuilder: (context, index) {
          final file = widget.openFiles[index];
          final isActive = index == widget.activeIndex;
          final isDirty = file.isDirty ?? false;

          return GestureDetector(
            onTap: () => widget.onTabChanged(index),
            onSecondaryTap: () => widget.onTabMenu?.call(index),
            child: MouseRegion(
              onEnter: (_) {},
              onExit: (_) {},
              child: Container(
                constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.darkCanvasBackground
                      : AppTheme.darkRibbonBackground,
                  border: Border(
                    top: BorderSide(
                      color: isActive ? AppTheme.darkAccentColor : Colors.transparent,
                      width: 2.0,
                    ),
                    right: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insert_drive_file,
                      size: 14,
                      color: isActive ? AppTheme.darkAccentColor : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.white : const Color(0xFF999999),
                          fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isDirty)
                      Container(
                        width: 6.0,
                        height: 6.0,
                        margin: const EdgeInsets.only(left: 6.0, right: 4.0),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFC107),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.onTabClosed(index),
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
