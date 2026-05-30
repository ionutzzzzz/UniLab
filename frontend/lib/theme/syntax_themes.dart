import 'package:flutter/material.dart';

class SyntaxHighlightTheme {
  final String name;
  final Color backgroundColor;
  final Color foregroundColor;
  final List<Color> colors; // [Keyword, String, Number, Function, Variable/Literal, Type/Title]

  const SyntaxHighlightTheme({
    required this.name, 
    required this.backgroundColor,
    required this.foregroundColor,
    required this.colors,
  });

  static const List<SyntaxHighlightTheme> all = [
    SyntaxHighlightTheme(
      name: 'Dracula',
      backgroundColor: Color(0xFF282A36),
      foregroundColor: Color(0xFFF8F8F2),
      colors: [
        Color(0xFFFF79C6), // Keyword
        Color(0xFF50FA7B), // String
        Color(0xFFFFB86C), // Number
        Color(0xFFBD93F9), // Function
        Color(0xFFFF5555), // Variable
        Color(0xFF8BE9FD), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'VS Code Dark+',
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Color(0xFFD4D4D4),
      colors: [
        Color(0xFF569CD6), // Keyword
        Color(0xFFCE9178), // String
        Color(0xFFB5CEA8), // Number
        Color(0xFFDCDCAA), // Function
        Color(0xFF9CDCFE), // Variable
        Color(0xFF4EC9B0), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'JetBrains Darcula',
      backgroundColor: Color(0xFF2B2B2B),
      foregroundColor: Color(0xFFA9B7C6),
      colors: [
        Color(0xFFCC7832), // Keyword
        Color(0xFF6A8759), // String
        Color(0xFF6897BB), // Number
        Color(0xFFFFC66D), // Function
        Color(0xFFA9B7C6), // Variable
        Color(0xFF9876AA), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'One Dark Pro',
      backgroundColor: Color(0xFF282C34),
      foregroundColor: Color(0xFFABB2BF),
      colors: [
        Color(0xFFC678DD), // Keyword
        Color(0xFF98C379), // String
        Color(0xFFD19A66), // Number
        Color(0xFF61AFEF), // Function
        Color(0xFFE06C75), // Variable
        Color(0xFF56B6C2), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'Tokyo Night',
      backgroundColor: Color(0xFF1A1B26),
      foregroundColor: Color(0xFFA9B1D6),
      colors: [
        Color(0xFFBB9AF7), // Keyword
        Color(0xFF9ECE6A), // String
        Color(0xFFFF9E64), // Number
        Color(0xFF7AA2F7), // Function
        Color(0xFFF7768E), // Variable
        Color(0xFF2AC3DE), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'Catppuccin Mocha',
      backgroundColor: Color(0xFF1E1E2E),
      foregroundColor: Color(0xFFCDD6F4),
      colors: [
        Color(0xFFCBA6F7), // Keyword
        Color(0xFFA6E3A1), // String
        Color(0xFFFAB387), // Number
        Color(0xFF89B4FA), // Function
        Color(0xFFF38BA8), // Variable
        Color(0xFF94E2D5), // Type
      ],
    ),
  ];
}