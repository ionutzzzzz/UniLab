import 'package:flutter/material.dart';

@immutable
class SyntaxPalette {
  const SyntaxPalette({
    required this.keyword,
    required this.type,
    required this.string,
    required this.number,
    required this.comment,
    required this.function,
    required this.variable,
    required this.operatorColor,
    required this.constant,
    required this.errorUnder,
    required this.warnUnder,
  });

  final Color keyword;
  final Color type;
  final Color string;
  final Color number;
  final Color comment;
  final Color function;
  final Color variable;
  final Color operatorColor;
  final Color constant;
  final Color errorUnder;
  final Color warnUnder;

  factory SyntaxPalette.darkPlus() => const SyntaxPalette(
        keyword: Color(0xFF8BC5FF),
        type: Color(0xFF4AA3FF),
        string: Color(0xFF78D2C4),
        number: Color(0xFFF4B860),
        comment: Color(0xFF8A94A3),
        function: Color(0xFFC4B5FD),
        variable: Color(0xFFE5E7EB),
        operatorColor: Color(0xFFB5BDC9),
        constant: Color(0xFF8BC5FF),
        errorUnder: Color(0xFFF14C4C),
        warnUnder: Color(0xFFE5E510),
      );

  factory SyntaxPalette.lightPlus() => const SyntaxPalette(
        keyword: Color(0xFF0000FF),
        type: Color(0xFF267F99),
        string: Color(0xFFA31515),
        number: Color(0xFF098658),
        comment: Color(0xFF008000),
        function: Color(0xFF795E26),
        variable: Color(0xFF001080),
        operatorColor: Color(0xFF000000),
        constant: Color(0xFF0000FF),
        errorUnder: Color(0xFFCD3131),
        warnUnder: Color(0xFFE5E510),
      );
}
