import 'package:flutter/material.dart';
import '../../theme/ui_theme.dart';

class LineNumberGutterPainter extends StatelessWidget {
  final int lineCount;
  final ScrollController scrollController;
  final Set<int> breakpoints;
  final int? activeLine;
  final Function(int)? onBreakpointToggle;
  final double paddingTop;

  const LineNumberGutterPainter({
    super.key,
    required this.lineCount,
    required this.scrollController,
    this.breakpoints = const {},
    this.activeLine,
    this.onBreakpointToggle,
    this.paddingTop = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    // Ensure metrics match editor CodeField (13px, 1.4 height)
    final textStyle = ui.typography.codeBody.copyWith(fontSize: 13, height: 1.4);
    final double textScale = MediaQuery.textScaleFactorOf(context);

    // Estimate height from the real editor font (respecting scale)
    final measureTp = TextPainter(
      text: TextSpan(text: 'M', style: textStyle),
      textDirection: TextDirection.ltr,
      textScaleFactor: textScale,
    );
    measureTp.layout();
    final double measuredLineHeight = measureTp.height;
    final double lineHeightUsed = measuredLineHeight;
    final double totalHeight = paddingTop * 2 + lineCount * lineHeightUsed;

    // Measure widest number to reserve space (respecting scale)
    final int digits = lineCount.toString().length;
    final widest = List.filled(digits, '9').join();
    final widthTp = TextPainter(
      text: TextSpan(text: widest, style: textStyle),
      textDirection: TextDirection.ltr,
      textScaleFactor: textScale,
    );
    widthTp.layout();
    final double digitWidth = widthTp.width;

    const double indicatorArea = 36.0;
    const double rightPadding = 12.0;
    const double gap = 8.0;
    const double minNumberAreaWidth = 28.0;

    final double numberAreaWidth = (digitWidth + gap).clamp(minNumberAreaWidth, double.infinity);

    final double gutterWidth = indicatorArea + numberAreaWidth + rightPadding + 4.0; // small safety

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final localY = details.localPosition.dy;
        final tappedLine = ((localY - paddingTop) / measuredLineHeight).floor() + 1;
        if (tappedLine >= 1 && tappedLine <= lineCount) {
          onBreakpointToggle?.call(tappedLine);
        }
      },
      child: SizedBox(
        width: gutterWidth,
        height: totalHeight,
        child: CustomPaint(
          painter: _LinePainter(
            lineCount: lineCount,
            breakpoints: breakpoints,
            activeLine: activeLine,
            lineHeight: measuredLineHeight,
            paddingTop: paddingTop,
            textStyle: textStyle,
            indicatorColor: ui.colors.danger,
            activeColor: ui.colors.accent,
            textColor: ui.colors.textDisabled,
            textScaleFactor: textScale,
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final int lineCount;
  final Set<int> breakpoints;
  final int? activeLine;
  final double lineHeight;
  final double paddingTop;
  final TextStyle textStyle;
  final Color indicatorColor;
  final Color activeColor;
  final Color textColor;

  final double textScaleFactor;

  _LinePainter({
    required this.lineCount,
    required this.breakpoints,
    required this.activeLine,
    required this.lineHeight,
    required this.paddingTop,
    required this.textStyle,
    required this.indicatorColor,
    required this.activeColor,
    required this.textColor,
    required this.textScaleFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final double gutterWidth = size.width;

    // Compute exact widest rendered number string (1..lineCount) to avoid any overlap
    const double indicatorArea = 36.0;
    const double rightPadding = 12.0;
    const double gap = 8.0;
    const double minNumberAreaWidth = 56.0; // larger minimum to prevent any overlap

    double maxNumberWidth = 0.0;
    for (int n = 1; n <= lineCount; n++) {
      final tp = TextPainter(
        text: TextSpan(text: '$n', style: textStyle),
        textDirection: TextDirection.ltr,
        textScaleFactor: textScaleFactor,
      );
      tp.layout();
      if (tp.width > maxNumberWidth) maxNumberWidth = tp.width;
    }

    final double numberAreaWidth = (maxNumberWidth + gap).clamp(minNumberAreaWidth, double.infinity);
    final double numberLeft = indicatorArea;

    for (int i = 1; i <= lineCount; i++) {
      final y = paddingTop + (i - 1) * lineHeight;

      // background highlight if active
      if (activeLine == i) {
        paint.color = activeColor.withValues(alpha: 0.08);
        final rect = Rect.fromLTWH(0, y, gutterWidth, lineHeight);
        canvas.drawRect(rect, paint);
      }

      // draw indicator (left)
      final indicatorX = 8.0;
      final indicatorCenterY = y + (lineHeight / 2);
      if (breakpoints.contains(i)) {
        paint.color = indicatorColor;
        canvas.drawCircle(Offset(indicatorX + 4, indicatorCenterY), 5.0, paint);
      } else if (activeLine == i) {
        paint.color = activeColor;
        final path = Path();
        path.moveTo(indicatorX + 2, indicatorCenterY - 6 / 2);
        path.lineTo(indicatorX + 2, indicatorCenterY + 6 / 2);
        path.lineTo(indicatorX + 8, indicatorCenterY);
        path.close();
        canvas.drawPath(path, paint);
      }

      // draw line number right aligned within reserved area
      final numberText = '$i';
      final tp = TextPainter(
        text: TextSpan(text: numberText, style: textStyle.copyWith(color: textColor)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
        maxLines: 1,
        textScaleFactor: textScaleFactor,
      );

      final availableWidth = numberAreaWidth + rightPadding + 4.0; // safety
      tp.layout(minWidth: 0, maxWidth: availableWidth);

      final dx = numberLeft + numberAreaWidth - tp.width; // align right within reserved number area
      final paintY = (y + (lineHeight - tp.height) / 2);
      tp.paint(canvas, Offset(dx, paintY));
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) {
    return old.lineCount != lineCount || old.breakpoints != breakpoints || old.activeLine != activeLine;
  }
}
