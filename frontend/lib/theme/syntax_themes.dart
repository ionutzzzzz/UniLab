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
    SyntaxHighlightTheme(
      name: 'Monokai',
      backgroundColor: Color(0xFF272822),
      foregroundColor: Color(0xFFF8F8F2),
      colors: [
        Color(0xFFF92672), // Keyword
        Color(0xFFE6DB74), // String
        Color(0xFFAE81FF), // Number
        Color(0xFFA6E22E), // Function
        Color(0xFFFD971F), // Variable
        Color(0xFF66D9EF), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'Nord',
      backgroundColor: Color(0xFF2E3440),
      foregroundColor: Color(0xFFD8DEE9),
      colors: [
        Color(0xFF81A1C1), // Keyword
        Color(0xFFA3BE8C), // String
        Color(0xFFB48EAD), // Number
        Color(0xFF88C0D0), // Function
        Color(0xFFD8DEE9), // Variable
        Color(0xFF8FBCBB), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'Solarized Dark',
      backgroundColor: Color(0xFF002B36),
      foregroundColor: Color(0xFF839496),
      colors: [
        Color(0xFF859900), // Keyword
        Color(0xFF2AA198), // String
        Color(0xFFD33682), // Number
        Color(0xFF268BD2), // Function
        Color(0xFFB58900), // Variable
        Color(0xFFCB4B16), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'GitHub Dark',
      backgroundColor: Color(0xFF0D1117),
      foregroundColor: Color(0xFFC9D1D9),
      colors: [
        Color(0xFFFF7B72), // Keyword
        Color(0xFFA5D6FF), // String
        Color(0xFF79C0FF), // Number
        Color(0xFFD2A8FF), // Function
        Color(0xFFFFA657), // Variable
        Color(0xFF7EE787), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'Night Owl',
      backgroundColor: Color(0xFF011627),
      foregroundColor: Color(0xFFD6DEEB),
      colors: [
        Color(0xFFC792EA), // Keyword
        Color(0xFFECC48D), // String
        Color(0xFFF78C6C), // Number
        Color(0xFF82AAFF), // Function
        Color(0xFFD6DEEB), // Variable
        Color(0xFFADDB67), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'Gruvbox Dark',
      backgroundColor: Color(0xFF282828),
      foregroundColor: Color(0xFFEBDBB2),
      colors: [
        Color(0xFFFB4934), // Keyword
        Color(0xFFB8BB26), // String
        Color(0xFFD3869B), // Number
        Color(0xFFFABD2F), // Function
        Color(0xFF83A598), // Variable
        Color(0xFF8EC07C), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'Material Palenight',
      backgroundColor: Color(0xFF292D3E),
      foregroundColor: Color(0xFFA6ACCD),
      colors: [
        Color(0xFFC792EA), // Keyword
        Color(0xFFC3E88D), // String
        Color(0xFFF78C6C), // Number
        Color(0xFF82AAFF), // Function
        Color(0xFFF07178), // Variable
        Color(0xFFFFCB6B), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'Pastel Pixel',
      backgroundColor: Color(0xFF1A1C23),
      foregroundColor: Color(0xFFD1D5DB),
      colors: [
        Color(0xFFDECBE4), // Keyword
        Color(0xFFCCEBC5), // String
        Color(0xFFFED9A6), // Number
        Color(0xFFB3CDE3), // Function
        Color(0xFFFBB4AE), // Variable
        Color(0xFFE5D8BD), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'Noctis',
      backgroundColor: Color(0xFF2c2e3b),
      foregroundColor: Color(0xFFe3e4e5),
      colors: [
        Color(0xFFff57a0), // Keyword
        Color(0xFFb9e295), // String
        Color(0xFFf5c276), // Number
        Color(0xFF72b1fc), // Function
        Color(0xFFe3e4e5), // Variable
        Color(0xFFc592ff), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'Monokai Pro',
      backgroundColor: Color(0xFF2d2a2e),
      foregroundColor: Color(0xFFfcfcfa),
      colors: [
        Color(0xFFff6188), // Keyword
        Color(0xFFffd866), // String
        Color(0xFFa9dc76), // Number
        Color(0xFF78dce8), // Function
        Color(0xFFab9df2), // Variable
        Color(0xFFfc9867), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'Panda',
      backgroundColor: Color(0xFF292a2b),
      foregroundColor: Color(0xFFe6e6e6),
      colors: [
        Color(0xFFff75b5), // Keyword
        Color(0xFF19f9d8), // String
        Color(0xFFffb86c), // Number
        Color(0xFF45a9f9), // Function
        Color(0xFFff2c6d), // Variable
        Color(0xFFb084eb), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'NightFox',
      backgroundColor: Color(0xFF192330),
      foregroundColor: Color(0xFFcdcecf),
      colors: [
        Color(0xFF9d79d6), // Keyword
        Color(0xFF98c379), // String
        Color(0xFFe0af68), // Number
        Color(0xFF82aaff), // Function
        Color(0xFFcdcecf), // Variable
        Color(0xFF63cdcf), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'GitHub Light',
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF24292E),
      colors: [
        Color(0xFFD73A49), // Keyword
        Color(0xFF032F62), // String
        Color(0xFF005CC5), // Number
        Color(0xFF6F42C1), // Function
        Color(0xFFE36209), // Variable
        Color(0xFF005CC5), // Type
      ],
    ),
    SyntaxHighlightTheme(
      name: 'Solarized Light',
      backgroundColor: Color(0xFFFDF6E3),
      foregroundColor: Color(0xFF657B83),
      colors: [
        Color(0xFF859900), // Keyword
        Color(0xFF2AA198), // String
        Color(0xFFD33682), // Number
        Color(0xFF268BD2), // Function
        Color(0xFFB58900), // Variable
        Color(0xFFCB4B16), // Type
      ],
    ),
  ];
}
