import 'package:flutter/material.dart';
import '../theme/ui_theme.dart';

enum UiTextVariant { title, body, label, caption, codeBody, codeGutter, consoleBody }

class UiText extends StatelessWidget {
  const UiText({
    super.key,
    required this.text,
    this.variant = UiTextVariant.body,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final UiTextVariant variant;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    TextStyle style;

    switch (variant) {
      case UiTextVariant.title:
        style = ui.typography.title;
        break;
      case UiTextVariant.body:
        style = ui.typography.body;
        break;
      case UiTextVariant.label:
        style = ui.typography.label;
        break;
      case UiTextVariant.caption:
        style = ui.typography.caption;
        break;
      case UiTextVariant.codeBody:
        style = ui.typography.codeBody;
        break;
      case UiTextVariant.codeGutter:
        style = ui.typography.codeGutter;
        break;
      case UiTextVariant.consoleBody:
        style = ui.typography.consoleBody;
        break;
    }

    if (color != null) {
      style = style.copyWith(color: color);
    }

    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
