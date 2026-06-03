import 'dart:math';
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
    this.lineHeight = 18.2,
    this.paddingTop = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);

    // Use the same font/metrics as the editor body so numbers line up with text
    final TextStyle numberStyle = ui.typography.codeBody.copyWith(fontSize: 13, height: 1.4);
    final double textScale = MediaQuery.textScaleFactorOf(context);

    // Measure height using the real editor font (respect provided lineHeight as minimum)
    final measureTp = TextPainter(
      text: TextSpan(text: 'M', style: numberStyle),
      textDirection: TextDirection.ltr,
      textScaleFactor: textScale,
    );
    measureTp.layout();
    final double measuredHeight = measureTp.height;
    final double rowHeight = measuredHeight > lineHeight ? measuredHeight : lineHeight;

    // Compute exact widest rendered number string (1..lineCount) to avoid any overlap
    const double indicatorArea = 36.0; // left area for icons
    const double rightPadding = 12.0;
    const double gap = 8.0; // extra breathing room
    const double minNumberAreaWidth = 56.0; // larger minimum to prevent overlap

    double maxNumberWidth = 0.0;
    for (int n = 1; n <= lineCount; n++) {
      final tp = TextPainter(
        text: TextSpan(text: '$n', style: numberStyle),
        textDirection: TextDirection.ltr,
        textScaleFactor: textScale,
      );
      tp.layout();
      if (tp.width > maxNumberWidth) maxNumberWidth = tp.width;
    }

    final double numberAreaWidth = (maxNumberWidth + gap).clamp(minNumberAreaWidth, double.infinity);
    final double gutterWidth = indicatorArea + numberAreaWidth + rightPadding + 4.0; // small safety margin
    final double totalHeight = paddingTop * 2 + lineCount * rowHeight;

    return Container(
      width: gutterWidth,
      height: totalHeight,
      decoration: BoxDecoration(
        color: ui.colors.panel,
        border: Border(
          right: BorderSide(color: ui.colors.border, width: ui.spacing.strokeHair),
        ),
      ),
      child: ListView.builder(
        controller: scrollController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: lineCount,
        itemExtent: rowHeight,
        padding: EdgeInsets.only(top: paddingTop, bottom: paddingTop),
        itemBuilder: (context, index) {
          final lineNum = index + 1;
          final isBreakpoint = breakpoints.contains(lineNum);
          final isActive = lineNum == activeLine;

          return GestureDetector(
            onTap: () => onBreakpointToggle?.call(lineNum),
            child: Container(
              width: gutterWidth,
              color: isActive ? ui.colors.accent.withValues(alpha: 0.06) : Colors.transparent,
              child: Row(
                children: [
                  SizedBox(
                    width: indicatorArea,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isBreakpoint)
                            Container(
                              width: 10,
                              height: 10,
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
                          if (isActive)
                            Icon(
                              LucideIcons.play,
                              size: 12,
                              color: ui.colors.accent,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Use a fixed-width number area to avoid wrapping/stacking
                  SizedBox(
                    width: numberAreaWidth,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: rightPadding),
                        child: Text(
                          '$lineNum',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          textAlign: TextAlign.right,
                          textWidthBasis: TextWidthBasis.longestLine,
                          textScaleFactor: textScale,
                          strutStyle: StrutStyle(
                            forceStrutHeight: true,
                            fontSize: numberStyle.fontSize ?? 13.0,
                            height: numberStyle.height ?? 1.4,
                            fontFamily: numberStyle.fontFamily ?? 'JetBrains Mono',
                          ),
                          style: numberStyle.copyWith(
                            color: isActive
                                ? ui.colors.textPrimary
                                : (isBreakpoint ? ui.colors.danger.withValues(alpha: 0.9) : ui.colors.textDisabled),
                            fontWeight: isActive ? FontWeight.bold : numberStyle.fontWeight,
                          ),
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
