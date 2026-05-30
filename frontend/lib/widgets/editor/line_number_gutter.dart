import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/ui_theme.dart';

class LineNumberGutter extends StatelessWidget {
  final int lineCount;
  final ScrollController scrollController;
  final Set<int> breakpoints;
  final int? activeLine;
  final Function(int)? onBreakpointToggle;
  final double lineHeight;
  final double paddingTop;

  const LineNumberGutter({
    super.key,
    required this.lineCount,
    required this.scrollController,
    this.breakpoints = const {},
    this.activeLine,
    this.onBreakpointToggle,
    this.lineHeight = 18.2, // 13 * 1.4
    this.paddingTop = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final int digits = lineCount.toString().length;
    
    // INCREASED WIDTH for maximum spacing
    // 40px (indicators) + (digits * 14px) + 20px (right padding)
    final double calculatedWidth = 40.0 + (digits * 14.0) + 20.0;
    // Ensuring a very spacious minimum width
    final double gutterWidth = calculatedWidth < 80.0 ? 80.0 : calculatedWidth;

    return Container(
      width: gutterWidth,
      decoration: BoxDecoration(
        color: ui.colors.panel,
        border: Border(
          right: BorderSide(
            color: ui.colors.border,
            width: ui.spacing.strokeHair,
          ),
        ),
      ),
      child: ListView.builder(
        controller: scrollController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: lineCount,
        padding: EdgeInsets.only(top: paddingTop, bottom: paddingTop),
        itemBuilder: (context, index) {
          final lineNum = index + 1;
          final isBreakpoint = breakpoints.contains(lineNum);
          final isActive = lineNum == activeLine;

          return GestureDetector(
            onTap: () => onBreakpointToggle?.call(lineNum),
            child: Container(
              height: lineHeight,
              width: gutterWidth,
              color: isActive ? ui.colors.accent.withValues(alpha: 0.1) : Colors.transparent,
              child: Stack(
                children: [
                  // Indicators Zone
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    width: 24,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isActive)
                          Icon(
                            LucideIcons.play,
                            size: 10,
                            color: ui.colors.accent,
                          ),
                        if (isBreakpoint)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: ui.colors.danger,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: ui.colors.danger.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Line Number Zone with extra right padding (20px)
                  Positioned.fill(
                    left: 40, 
                    right: 20, 
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$lineNum',
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.visible,
                        style: ui.typography.codeGutter.copyWith(
                          fontSize: 12,
                          height: 1.0, 
                          color: isActive 
                              ? ui.colors.textPrimary 
                              : (isBreakpoint ? ui.colors.danger.withValues(alpha: 0.8) : ui.colors.textDisabled),
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
