import 'package:flutter/material.dart';

@immutable
class UiTypography {
  const UiTypography({
    required this.title,
    required this.body,
    required this.label,
    required this.caption,
    required this.codeBody,
    required this.codeGutter,
    required this.consoleBody,
  });

  final TextStyle title;
  final TextStyle body;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle codeBody;
  final TextStyle codeGutter;
  final TextStyle consoleBody;

  factory UiTypography.base(Color textPrimary, Color textMuted, {double scale = 1.0, String codeFontFamily = 'JetBrains Mono'}) {
    return UiTypography(
      title: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13 * scale,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: textPrimary,
      ),
      body: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12 * scale,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: textPrimary,
      ),
      label: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11 * scale,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: textPrimary,
      ),
      caption: TextStyle(
        fontFamily: 'Inter',
        fontSize: 10 * scale,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: textMuted,
      ),
      codeBody: TextStyle(
        fontFamily: codeFontFamily,
        fontSize: 13 * scale,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: textPrimary,
      ),
      codeGutter: TextStyle(
        fontFamily: codeFontFamily,
        fontSize: 12 * scale,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: textMuted,
      ),
      consoleBody: TextStyle(
        fontFamily: codeFontFamily,
        fontSize: 12 * scale,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textPrimary,
      ),
    );
  }
}