import 'package:flutter/material.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_icon.dart';
import '../../../widgets/ui_text.dart';

class RibbonButton extends StatefulWidget {
  const RibbonButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.isPrimary = false,
    this.isLarge = false,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isLarge;
  final Color? color;

  @override
  State<RibbonButton> createState() => _RibbonButtonState();
}

class _RibbonButtonState extends State<RibbonButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final isEnabled = widget.onTap != null;

    Color bgColor = Colors.transparent;
    Color fgColor = isEnabled ? ui.colors.icon : ui.colors.textDisabled;

    if (widget.color != null && isEnabled) {
      bgColor = _isHovered ? widget.color!.withOpacity(0.25) : widget.color!.withOpacity(0.1);
      fgColor = _isHovered ? widget.color! : widget.color!.withOpacity(0.85);
    } else if (widget.isPrimary && isEnabled) {
      bgColor = _isHovered ? ui.colors.accentHover : ui.colors.accent;
      fgColor = ui.colors.textInverse;
    } else if (_isHovered && isEnabled) {
      bgColor = ui.colors.hover.withOpacity(0.8);
      fgColor = ui.colors.textPrimary;
    }

    final double width = widget.isLarge ? 84 : 96; // Adjusted for full text display
    final double height = widget.isLarge ? 68 : 34;

    return SizedBox(
      width: width,
      height: height,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isHovered && isEnabled ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: ui.spacing.xs,
                vertical: ui.spacing.xxs,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: ui.spacing.radiusMd,
                border: Border.all(
                  color: widget.color != null && isEnabled
                    ? widget.color!.withOpacity(0.3)
                    : (_isHovered && isEnabled ? ui.colors.border.withOpacity(0.3) : Colors.transparent),
                  width: 1.0,
                ),
                boxShadow: _isHovered && isEnabled ? ui.colors.shadowSm : null,
              ),
              child: widget.isLarge
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        transform: Matrix4.identity()..translate(0.0, _isHovered ? -1.0 : 0.0),
                        child: UiIcon(
                          widget.icon,
                          size: 26,
                          color: fgColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      UiText(
                        text: widget.label,
                        variant: UiTextVariant.label,
                        fontSize: 10,
                        fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                        color: fgColor,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      UiIcon(
                        widget.icon,
                        size: 18,
                        color: fgColor,
                      ),
                      const SizedBox(width: 8),
                      UiText(
                        text: widget.label,
                        variant: UiTextVariant.label,
                        fontSize: 10,
                        fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                        color: fgColor,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ));
  }
}
