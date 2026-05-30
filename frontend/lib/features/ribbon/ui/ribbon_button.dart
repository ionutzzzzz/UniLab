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
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;

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
    BorderSide border = BorderSide.none;

    if (widget.isPrimary && isEnabled) {
      bgColor = _isHovered ? ui.colors.accentHover : ui.colors.accent;
      fgColor = ui.colors.textInverse;
    } else if (_isHovered && isEnabled) {
      bgColor = ui.colors.hover;
      fgColor = ui.colors.textPrimary;
      border = BorderSide(color: ui.colors.border);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: 56,
          height: 54,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: ui.spacing.radiusMd,
            border: Border.fromBorderSide(border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UiIcon(
                widget.icon,
                size: 20,
                color: fgColor,
              ),
              const SizedBox(height: 4),
              UiText(
                text: widget.label,
                variant: UiTextVariant.caption,
                color: widget.isPrimary && isEnabled 
                    ? ui.colors.textInverse 
                    : (isEnabled ? ui.colors.textSecondary : ui.colors.textDisabled),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
