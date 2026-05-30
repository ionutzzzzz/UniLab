import 'package:flutter/material.dart';
import '../theme/ui_theme.dart';
import 'ui_tooltip.dart';

class UiIconButton extends StatefulWidget {
  const UiIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.size = 24,
    this.iconSize = 16,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final bool isActive;

  @override
  State<UiIconButton> createState() => _UiIconButtonState();
}

class _UiIconButtonState extends State<UiIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final isEnabled = widget.onPressed != null;

    final bgColor = widget.isActive
        ? ui.colors.selected
        : (_isHovered && isEnabled ? ui.colors.hover : Colors.transparent);
        
    final fgColor = widget.isActive
        ? ui.colors.textInverse
        : (isEnabled ? ui.colors.icon : ui.colors.textDisabled);

    final button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: ui.spacing.radiusSm,
          ),
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: fgColor,
          ),
        ),
      ),
    );

    if (widget.tooltip.isNotEmpty) {
      return UiTooltip(
        message: widget.tooltip,
        child: button,
      );
    }
    return button;
  }
}
