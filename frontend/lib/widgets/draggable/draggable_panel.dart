import 'package:flutter/material.dart';

/// Draggable panel wrapper that allows repositioning panels
class DraggablePanel extends StatefulWidget {
  final String id;
  final String title;
  final IconData? icon;
  final Widget child;
  final VoidCallback? onClose;
  final bool closeable;
  final double initialWidth;

  const DraggablePanel({
    super.key,
    required this.id,
    required this.title,
    required this.child,
    this.icon,
    this.onClose,
    this.closeable = false,
    this.initialWidth = 300,
  });

  @override
  State<DraggablePanel> createState() => _DraggablePanelState();
}

class _DraggablePanelState extends State<DraggablePanel> {
  late double width;
  bool _isResizing = false;

  @override
  void initState() {
    super.initState();
    width = widget.initialWidth;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _isResizing ? SystemMouseCursors.resizeColumn : MouseCursor.defer,
      child: GestureDetector(
        onPanUpdate: (details) {
          if (_isResizing) {
            setState(() {
              width += details.delta.dx;
              width = width.clamp(200, 800);
            });
          }
        },
        onPanEnd: (_) {
          setState(() => _isResizing = false);
        },
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Panel Header (Draggable)
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Row(
                    children: [
                      if (widget.icon != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            widget.icon,
                            size: 14,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            widget.title,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (widget.closeable)
                        IconButton(
                          icon: const Icon(Icons.close, size: 14),
                          onPressed: widget.onClose,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Panel Content
              Expanded(
                child: widget.child,
              ),
              // Resize Handle
              MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: GestureDetector(
                  onPanStart: (_) {
                    setState(() => _isResizing = true);
                  },
                  child: Container(
                    height: 4,
                    color: _isResizing
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).dividerColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
