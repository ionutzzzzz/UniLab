import 'package:flutter/material.dart';
import '../theme/ui_theme.dart';

class UiInputField extends StatefulWidget {
  const UiInputField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.isDense = true,
  });

  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool isDense;

  @override
  State<UiInputField> createState() => _UiInputFieldState();
}

class _UiInputFieldState extends State<UiInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final height = widget.isDense ? 28.0 : 32.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: ui.colors.canvas,
        border: Border.all(
          color: _isFocused ? ui.colors.accent : ui.colors.border,
          width: 1.0,
        ),
        borderRadius: ui.spacing.radiusMd,
      ),
      child: Row(
        children: [
          if (widget.prefixIcon != null) ...[
            SizedBox(width: ui.spacing.sm),
            Icon(widget.prefixIcon, size: 14, color: ui.colors.icon),
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: ui.typography.body.copyWith(color: ui.colors.textPrimary),
              cursorColor: ui.colors.textPrimary,
              cursorWidth: 1.0,
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.hintText,
                hintStyle: ui.typography.body.copyWith(color: ui.colors.textMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ui.spacing.sm,
                  vertical: (height - ui.typography.body.fontSize! * ui.typography.body.height!) / 2,
                ),
              ),
            ),
          ),
          if (widget.suffixIcon != null) widget.suffixIcon!,
        ],
      ),
    );
  }
}
