import 'package:flutter/material.dart';

/// Custom line number gutter widget for the code editor
class LineNumberGutter extends StatefulWidget {
  final int lineCount;
  final ScrollController scrollController;
  final TextStyle textStyle;
  final Color backgroundColor;
  final Color textColor;

  const LineNumberGutter({
    super.key,
    required this.lineCount,
    required this.scrollController,
    this.textStyle = const TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 13,
      height: 1.5,
    ),
    this.backgroundColor = const Color(0xFF1E1E1E),
    this.textColor = const Color(0xFF858585),
  });

  @override
  State<LineNumberGutter> createState() => _LineNumberGutterState();
}

class _LineNumberGutterState extends State<LineNumberGutter> {
  @override
  Widget build(BuildContext context) {
    final int digits = widget.lineCount.toString().length;
    final double gutterWidth = 30.0 + (digits * 8.0);

    return Container(
      constraints: const BoxConstraints(minWidth: 45.0),
      width: gutterWidth > 45.0 ? gutterWidth : 45.0,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      alignment: Alignment.topRight,
      padding: const EdgeInsets.only(right: 8.0, top: 8.0),
      child: ListView.builder(
        controller: widget.scrollController,
        itemCount: widget.lineCount,
        itemBuilder: (context, index) {
          return SizedBox(
            height: widget.textStyle.height! * (widget.textStyle.fontSize ?? 13),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${index + 1}',
                style: widget.textStyle.copyWith(color: widget.textColor),
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom code editor with line numbers
class CodeEditorWithLineNumbers extends StatefulWidget {
  final String initialCode;
  final Function(String) onChanged;
  final TextStyle? textStyle;
  final Color? backgroundColor;

  const CodeEditorWithLineNumbers({
    super.key,
    this.initialCode = '',
    required this.onChanged,
    this.textStyle,
    this.backgroundColor,
  });

  @override
  State<CodeEditorWithLineNumbers> createState() =>
      _CodeEditorWithLineNumbersState();
}

class _CodeEditorWithLineNumbersState extends State<CodeEditorWithLineNumbers> {
  late TextEditingController _textController;
  late ScrollController _scrollController;
  int _lineCount = 1;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialCode);
    _scrollController = ScrollController();
    _updateLineCount();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateLineCount() {
    final newLineCount = '\n'.allMatches(_textController.text).length + 1;
    if (newLineCount != _lineCount) {
      setState(() {
        _lineCount = newLineCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LineNumberGutter(
          lineCount: _lineCount,
          scrollController: _scrollController,
        ),
        Expanded(
          child: TextField(
            controller: _textController,
            maxLines: null,
            expands: true,
            onChanged: (value) {
              _updateLineCount();
              widget.onChanged(value);
            },
            style: widget.textStyle ??
                const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFFCCCCCC),
                ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(8.0),
              filled: true,
              fillColor: widget.backgroundColor ?? const Color(0xFF1E1E1E),
            ),
            scrollController: _scrollController,
            cursorColor: const Color(0xFFFFFFFE),
          ),
        ),
      ],
    );
  }
}
