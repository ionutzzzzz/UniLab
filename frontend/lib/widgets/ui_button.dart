import 'package:flutter/material.dart';
import '../theme/ui_theme.dart';

enum UiButtonVariant { primary, secondary, ghost }
enum UiButtonSize { xs, sm, md }

class UiButton extends StatefulWidget {
  const UiButton({
    super.key,
    required this.label,
    this.icon,
    this.variant = UiButtonVariant.primary,
    this.size = UiButtonSize.md,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final UiButtonVariant variant;
  final UiButtonSize size;
  final VoidCallback? onPressed;

  @override
  State<UiButton> createState() => _UiButtonState();
}

class _UiButtonState extends State<UiButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final isEnabled = widget.onPressed != null;

    Color bgColor;
    Color fgColor;
    BorderSide border;

    switch (widget.variant) {
      case UiButtonVariant.primary:
        bgColor = isEnabled
            ? (_isHovered ? ui.colors.accentHover : ui.colors.accent)
            : ui.colors.panelHeader;
        fgColor = isEnabled ? ui.colors.textInverse : ui.colors.textDisabled;
        border = BorderSide.none;
        break;
      case UiButtonVariant.secondary:
        bgColor = _isHovered ? ui.colors.hover : Colors.transparent;
        fgColor = isEnabled ? ui.colors.textPrimary : ui.colors.textDisabled;
        border = BorderSide(color: isEnabled ? ui.colors.border : ui.colors.divider);
        break;
      case UiButtonVariant.ghost:
        bgColor = _isHovered && isEnabled ? ui.colors.hover : Colors.transparent;
        fgColor = isEnabled ? ui.colors.textPrimary : ui.colors.textDisabled;
        border = BorderSide.none;
        break;
    }

    double height;
    EdgeInsets padding;
    double iconSize;
    TextStyle textStyle;

    switch (widget.size) {
      case UiButtonSize.xs:
        height = 20;
        padding = EdgeInsets.symmetric(horizontal: ui.spacing.xs);
        iconSize = 12;
        textStyle = ui.typography.caption;
        break;
      case UiButtonSize.sm:
        height = 24;
        padding = EdgeInsets.symmetric(horizontal: ui.spacing.sm);
        iconSize = 14;
        textStyle = ui.typography.label;
        break;
      case UiButtonSize.md:
        height = 28;
        padding = EdgeInsets.symmetric(horizontal: ui.spacing.md);
        iconSize = 16;
        textStyle = ui.typography.body;
        break;
    }

    Widget content = Text(widget.label, style: textStyle.copyWith(color: fgColor));

    if (widget.icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: iconSize, color: fgColor),
          SizedBox(width: ui.spacing.xs),
          content,
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.fromBorderSide(border),
            borderRadius: ui.spacing.radiusMd,
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}
