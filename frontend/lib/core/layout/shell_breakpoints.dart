class ShellBreakpoints {
  static const double compact = 760;
  static const double medium = 960;
  static const double large = 1280;

  static bool isCompact(double width) => width < compact;
  static bool isMedium(double width) => width >= compact && width < large;
  static bool isLarge(double width) => width >= large;
  
  static bool shouldCollapseLeft(double width) => width < medium;
  static bool shouldCollapseRight(double width) => width < large;
}