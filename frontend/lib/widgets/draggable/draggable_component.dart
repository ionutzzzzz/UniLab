import 'package:flutter/material.dart';

/// Draggable item that can be moved around panels
class DraggableItem extends StatefulWidget {
  final String id;
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final VoidCallback? onTap;

  const DraggableItem({
    super.key,
    required this.id,
    required this.label,
    required this.icon,
    this.color,
    this.onDragStart,
    this.onDragEnd,
    this.onTap,
  });

  @override
  State<DraggableItem> createState() => _DraggableItemState();
}

class _DraggableItemState extends State<DraggableItem> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: widget.id,
      onDragStarted: () {
        setState(() => _isDragging = true);
        widget.onDragStart?.call();
      },
      onDraggableCanceled: (_, _) {
        setState(() => _isDragging = false);
        widget.onDragEnd?.call();
      },
      onDragCompleted: () {
        setState(() => _isDragging = false);
        widget.onDragEnd?.call();
      },
      feedback: _buildFeedbackWidget(context),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildItemChild(context),
      ),
      child: _buildItemChild(context),
    );
  }

  Widget _buildItemChild(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _isDragging
              ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
              : Theme.of(context).hoverColor,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: _isDragging
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 14,
              color: widget.color ?? Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Drop target for draggable items
class DragDropTarget extends StatefulWidget {
  final String id;
  final Widget child;
  final Function(String draggedId)? onItemDropped;
  final Color? highlightColor;
  final EdgeInsets padding;

  const DragDropTarget({
    super.key,
    required this.id,
    required this.child,
    this.onItemDropped,
    this.highlightColor,
    this.padding = const EdgeInsets.all(4),
  });

  @override
  State<DragDropTarget> createState() => _DragDropTargetState();
}

class _DragDropTargetState extends State<DragDropTarget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isHovering = true);
        return true;
      },
      onLeave: (_) {
        setState(() => _isHovering = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        widget.onItemDropped?.call(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _isHovering
                ? (widget.highlightColor ?? Theme.of(context).primaryColor)
                    .withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(
              color: _isHovering
                  ? (widget.highlightColor ?? Theme.of(context).primaryColor)
                  : Colors.transparent,
              width: 2,
              style: _isHovering ? BorderStyle.solid : BorderStyle.none,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: widget.child,
        );
      },
    );
  }
}
